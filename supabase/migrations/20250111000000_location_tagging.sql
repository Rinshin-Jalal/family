-- Create location_tags table for auto-tagging stories with places
CREATE TABLE IF NOT EXISTS location_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    place_name TEXT NOT NULL,
    place_type TEXT CHECK (place_type IN ('home', 'school', 'work', 'travel', 'restaurant', 'outdoor', 'other')),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE location_tags ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Family members can view location tags" ON location_tags
    FOR SELECT USING (
        story_id IN (SELECT id FROM stories WHERE family_id IN (
            SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()
        ))
    );

CREATE POLICY "Family members can create location tags" ON location_tags
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT auth_user_id FROM profiles WHERE family_id IN (
                SELECT family_id FROM stories WHERE id = story_id
            )
        )
    );

CREATE POLICY "Family members can delete location tags" ON location_tags
    FOR DELETE USING (
        auth.uid() IN (
            SELECT auth_user_id FROM profiles WHERE family_id IN (
                SELECT family_id FROM stories WHERE id = story_id
            )
        )
    );

-- Create index for location-based queries
CREATE INDEX idx_location_tags_story ON location_tags(story_id);
CREATE INDEX idx_location_tags_place_type ON location_tags(place_type);

-- Create function to get stories by location
CREATE OR REPLACE FUNCTION get_stories_by_location(
    user_id UUID,
    max_distance_km DOUBLE PRECISION DEFAULT 50,
    limit_count INT DEFAULT 50
)
RETURNS SETOF stories AS $$
BEGIN
    RETURN QUERY
    SELECT s.*
    FROM stories s
    INNER JOIN location_tags lt ON s.id = lt.story_id
    WHERE s.family_id IN (
        SELECT family_id FROM profiles WHERE auth_user_id = user_id
    )
    GROUP BY s.id
    ORDER BY s.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
