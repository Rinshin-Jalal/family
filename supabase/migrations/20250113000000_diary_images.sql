-- Migration: Diary Images Upload and OCR System
-- Enables users to upload photos of old diaries, letters, and handwritten notes
-- with AI-powered OCR text extraction

-- MARK: - Tables

-- Table: diary_uploads (parent record for a batch of images)
CREATE TABLE diary_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Source classification
    source VARCHAR(50) NOT NULL DEFAULT 'diary',  -- diary, letter, notes, document, photo
    title VARCHAR(255),
    description TEXT,

    -- Processing state
    processing_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- States: pending, uploading, processing, completed, failed

    -- OCR results
    page_count INT NOT NULL DEFAULT 0,
    combined_text TEXT,
    overall_confidence DECIMAL(5,4),
    processing_time_ms INT,

    -- Story linkage
    story_id UUID REFERENCES stories(id) ON DELETE SET NULL,

    -- Metadata
    date_of_document DATE,  -- When the original document was written
    author_name VARCHAR(255),  -- Who wrote the original document
    tags TEXT[],

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Table: diary_images (individual pages within an upload)
CREATE TABLE diary_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    upload_id UUID NOT NULL REFERENCES diary_uploads(id) ON DELETE CASCADE,

    -- Storage
    image_url TEXT NOT NULL,
    image_key TEXT NOT NULL,  -- R2 storage key
    thumbnail_url TEXT,

    -- Page ordering
    page_order INT NOT NULL,

    -- OCR results for this page
    extracted_text TEXT,
    ocr_confidence DECIMAL(5,4),
    processing_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- States: pending, processing, completed, failed

    -- Image metadata
    width INT,
    height INT,
    file_size_bytes INT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- MARK: - Indexes

-- diary_uploads indexes
CREATE INDEX idx_diary_uploads_family ON diary_uploads(family_id);
CREATE INDEX idx_diary_uploads_user ON diary_uploads(user_id);
CREATE INDEX idx_diary_uploads_status ON diary_uploads(processing_status);
CREATE INDEX idx_diary_uploads_story ON diary_uploads(story_id);
CREATE INDEX idx_diary_uploads_created ON diary_uploads(created_at DESC);

-- diary_images indexes
CREATE INDEX idx_diary_images_upload ON diary_images(upload_id);
CREATE INDEX idx_diary_images_status ON diary_images(processing_status);
CREATE INDEX idx_diary_images_order ON diary_images(upload_id, page_order);

-- Full-text search on extracted text
CREATE INDEX idx_diary_uploads_text_search ON diary_uploads
    USING GIN (to_tsvector('english', COALESCE(combined_text, '')));

CREATE INDEX idx_diary_images_text_search ON diary_images
    USING GIN (to_tsvector('english', COALESCE(extracted_text, '')));

-- MARK: - Triggers

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_diary_uploads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER diary_uploads_updated_at
    BEFORE UPDATE ON diary_uploads
    FOR EACH ROW
    EXECUTE FUNCTION update_diary_uploads_updated_at();

CREATE TRIGGER diary_images_updated_at
    BEFORE UPDATE ON diary_images
    FOR EACH ROW
    EXECUTE FUNCTION update_diary_uploads_updated_at();

-- MARK: - Row Level Security

ALTER TABLE diary_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_images ENABLE ROW LEVEL SECURITY;

-- diary_uploads policies
CREATE POLICY "Users can view own family diary uploads"
    ON diary_uploads FOR SELECT
    USING (
        family_id IN (
            SELECT family_id FROM profiles
            WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert diary uploads"
    ON diary_uploads FOR INSERT
    WITH CHECK (
        user_id = (
            SELECT id FROM profiles
            WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own diary uploads"
    ON diary_uploads FOR UPDATE
    USING (
        user_id = (
            SELECT id FROM profiles
            WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own diary uploads"
    ON diary_uploads FOR DELETE
    USING (
        user_id = (
            SELECT id FROM profiles
            WHERE auth_user_id = auth.uid()
        )
    );

-- diary_images policies (cascade through upload_id)
CREATE POLICY "Users can view diary images from own family"
    ON diary_images FOR SELECT
    USING (
        upload_id IN (
            SELECT id FROM diary_uploads
            WHERE family_id IN (
                SELECT family_id FROM profiles
                WHERE auth_user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can insert diary images for own uploads"
    ON diary_images FOR INSERT
    WITH CHECK (
        upload_id IN (
            SELECT id FROM diary_uploads
            WHERE user_id = (
                SELECT id FROM profiles
                WHERE auth_user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can update diary images for own uploads"
    ON diary_images FOR UPDATE
    USING (
        upload_id IN (
            SELECT id FROM diary_uploads
            WHERE user_id = (
                SELECT id FROM profiles
                WHERE auth_user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can delete diary images for own uploads"
    ON diary_images FOR DELETE
    USING (
        upload_id IN (
            SELECT id FROM diary_uploads
            WHERE user_id = (
                SELECT id FROM profiles
                WHERE auth_user_id = auth.uid()
            )
        )
    );

-- MARK: - Helper Functions

-- Function to get full-text search results from diary content
CREATE OR REPLACE FUNCTION search_diary_content(
    p_family_id UUID,
    p_search_query TEXT,
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    upload_id UUID,
    title VARCHAR,
    source VARCHAR,
    combined_text TEXT,
    relevance REAL,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        du.id,
        du.title,
        du.source,
        du.combined_text,
        ts_rank(
            to_tsvector('english', COALESCE(du.combined_text, '')),
            plainto_tsquery('english', p_search_query)
        ) AS relevance,
        du.created_at
    FROM diary_uploads du
    WHERE du.family_id = p_family_id
      AND du.processing_status = 'completed'
      AND to_tsvector('english', COALESCE(du.combined_text, '')) @@ plainto_tsquery('english', p_search_query)
    ORDER BY relevance DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get diary upload with all pages
CREATE OR REPLACE FUNCTION get_diary_upload_with_pages(p_upload_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'id', du.id,
        'family_id', du.family_id,
        'user_id', du.user_id,
        'source', du.source,
        'title', du.title,
        'processing_status', du.processing_status,
        'page_count', du.page_count,
        'combined_text', du.combined_text,
        'overall_confidence', du.overall_confidence,
        'story_id', du.story_id,
        'created_at', du.created_at,
        'pages', (
            SELECT json_agg(
                json_build_object(
                    'id', di.id,
                    'page_order', di.page_order,
                    'image_url', di.image_url,
                    'extracted_text', di.extracted_text,
                    'ocr_confidence', di.ocr_confidence,
                    'processing_status', di.processing_status
                ) ORDER BY di.page_order
            )
            FROM diary_images di
            WHERE di.upload_id = du.id
        )
    ) INTO result
    FROM diary_uploads du
    WHERE du.id = p_upload_id;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- MARK: - Comments

COMMENT ON TABLE diary_uploads IS 'Parent records for diary/letter image uploads with OCR processing';
COMMENT ON TABLE diary_images IS 'Individual page images within a diary upload batch';
COMMENT ON COLUMN diary_uploads.source IS 'Type of document: diary, letter, notes, document, photo';
COMMENT ON COLUMN diary_uploads.processing_status IS 'Processing state: pending, uploading, processing, completed, failed';
COMMENT ON COLUMN diary_images.page_order IS 'Order of page within the upload (0-indexed)';
COMMENT ON COLUMN diary_images.ocr_confidence IS 'OCR confidence score from 0.0 to 1.0';
