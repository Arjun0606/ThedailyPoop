-- Add drop_type to briefings for multi-drop (morning, midday, evening)
ALTER TABLE briefings ADD COLUMN drop_type text NOT NULL DEFAULT 'morning';

-- Ensure one briefing per drop per day
CREATE UNIQUE INDEX idx_briefings_date_drop ON briefings(publish_date, drop_type);
