-- Fix: remove restrictive CHECK constraint on stories.category
-- The AI generates stories across business, tech, culture, politics, sports, world, etc.
ALTER TABLE stories DROP CONSTRAINT IF EXISTS stories_category_check;
