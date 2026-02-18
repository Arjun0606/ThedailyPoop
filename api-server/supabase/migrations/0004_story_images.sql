-- Add image_url column to stories for OG images from source articles
ALTER TABLE stories ADD COLUMN image_url text;
