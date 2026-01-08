-- Create story_timeline table for year-based story organization
CREATE TABLE IF NOT EXISTS story_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    year INT NOT NULL CHECK (year >= 1900 AND year <= EXTRACT(YEAR FROM NOW())::INT),
    era_label TEXT,
    era_color TEXT DEFAULT 'blue',
    is_featured BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE story_timeline ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Family members can view timeline entries" ON story_timeline
    FOR SELECT USING (
        story_id IN (SELECT id FROM stories WHERE family_id IN (
            SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()
        ))
    );

CREATE POLICY "Family members can manage timeline" ON story_timeline
    FOR ALL USING (
        auth.uid() IN (
            SELECT auth_user_id FROM profiles WHERE family_id IN (
                SELECT family_id FROM stories WHERE id = story_id
            ) AND role IN ('organizer', 'parent')
        )
    );

-- Create index for timeline queries
CREATE INDEX idx_story_timeline_year ON story_timeline(year);
CREATE INDEX idx_story_timeline_story ON story_timeline(story_id);

-- Create era labels function
CREATE OR REPLACE FUNCTION get_era_label(year INT) RETURNS TEXT AS $$
BEGIN
    CASE
        WHEN year < 1940 THEN RETURN 'The Greatest Generation';
        WHEN year < 1955 THEN RETURN 'Baby Boomers';
        WHEN year < 1970 THEN RETURN 'The Swinging Sixties';
        WHEN year < 1985 THEN RETURN 'Disco Era';
        WHEN year < 2000 THEN RETURN 'Y2K Era';
        WHEN year < 2015 THEN RETURN 'Digital Native';
        ELSE RETURN 'Modern Era';
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create view for family timeline
CREATE OR REPLACE VIEW family_timeline_view AS
SELECT
    st.year,
    st.era_label,
    st.era_color,
    COUNT(st.story_id) as story_count,
    ARRAY_AGG(
        json_build_object(
            'id', s.id,
            'title', s.title,
            'created_at', s.created_at
        ) ORDER BY s.created_at DESC
    ) as stories
FROM story_timeline st
INNER JOIN stories s ON st.story_id = s.id
WHERE s.is_public IS TRUE OR s.family_id IN (
    SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()
)
GROUP BY st.year, st.era_label, st.era_color
ORDER BY st.year DESC;
