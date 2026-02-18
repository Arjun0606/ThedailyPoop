-- ============================================================
-- TheDailyPoop: Consolidated Migration (0001 → 0005)
-- Paste this ENTIRE script into Supabase SQL Editor and run.
-- Safe to re-run (uses IF EXISTS / IF NOT EXISTS).
-- ============================================================

-- ============================================================
-- MIGRATION 0001: Pivot from Social → News Briefing
-- ============================================================

-- Remove realtime publications for old tables (ignore if not exist)
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS drops;
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS gossip;
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS challenges;
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS challenge_responses;
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS invite_codes;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Drop old social tables
DROP TABLE IF EXISTS challenge_responses CASCADE;
DROP TABLE IF EXISTS challenges CASCADE;
DROP TABLE IF EXISTS gossip_reveals CASCADE;
DROP TABLE IF EXISTS gossip CASCADE;
DROP TABLE IF EXISTS drops CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS waitlist CASCADE;
DROP TABLE IF EXISTS invite_codes CASCADE;

-- Add premium columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS premium_expires_at timestamptz;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rc_customer_id text;
ALTER TABLE users DROP COLUMN IF EXISTS total_drops;

-- Create briefings table (with drop_type from migration 0005 included)
CREATE TABLE IF NOT EXISTS briefings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  publish_date date NOT NULL,
  drop_type text NOT NULL DEFAULT 'morning',
  headline text NOT NULL,
  intro_text text,
  story_count int DEFAULT 10,
  free_story_count int DEFAULT 3,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  published_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create stories table (with image_url from migration 0004 included)
CREATE TABLE IF NOT EXISTS stories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  sort_order int NOT NULL,
  is_free boolean DEFAULT false,
  category text NOT NULL CHECK (category IN ('business', 'tech', 'culture')),
  headline text NOT NULL,
  body text NOT NULL,
  tldr text,
  source_url text,
  source_name text,
  image_url text,
  emoji text,
  created_at timestamptz DEFAULT now()
);

-- Create user_reads table
CREATE TABLE IF NOT EXISTS user_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  read_at timestamptz DEFAULT now(),
  UNIQUE(user_id, story_id)
);

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  favorite_categories text[] DEFAULT '{"business","tech","culture"}',
  push_enabled boolean DEFAULT true,
  push_time time DEFAULT '07:00',
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE briefings ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies (use DO blocks to avoid errors if already exist)
DO $$ BEGIN
  CREATE POLICY "Anyone can view published briefings" ON briefings
    FOR SELECT USING (status = 'published');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Anyone can view stories" ON stories
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can view own reads" ON user_reads
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can mark stories read" ON user_reads
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can create own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_briefings_publish_date ON briefings(publish_date DESC);
CREATE INDEX IF NOT EXISTS idx_briefings_status ON briefings(status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_briefings_date_drop ON briefings(publish_date, drop_type);
CREATE INDEX IF NOT EXISTS idx_stories_briefing_id ON stories(briefing_id);
CREATE INDEX IF NOT EXISTS idx_stories_sort_order ON stories(briefing_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_stories_category ON stories(category);
CREATE INDEX IF NOT EXISTS idx_user_reads_user ON user_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_user_reads_story ON user_reads(story_id);
CREATE INDEX IF NOT EXISTS idx_user_reads_date ON user_reads(read_at);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE briefings;
ALTER PUBLICATION supabase_realtime ADD TABLE stories;


-- ============================================================
-- MIGRATION 0002: Reader Sessions (Live Globe)
-- ============================================================

CREATE TABLE IF NOT EXISTS reader_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid REFERENCES stories(id) ON DELETE CASCADE,
  username text,
  story_headline text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  country_code text,
  country_name text,
  city text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reader_sessions_recent ON reader_sessions(created_at DESC);

ALTER PUBLICATION supabase_realtime ADD TABLE reader_sessions;


-- ============================================================
-- MIGRATION 0003: Reactions & Bookmarks
-- ============================================================

CREATE TABLE IF NOT EXISTS story_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  reaction text NOT NULL CHECK (reaction IN ('fire', 'skull', 'laugh', 'mindblown')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, story_id)
);

CREATE INDEX IF NOT EXISTS idx_story_reactions_story ON story_reactions(story_id);
CREATE INDEX IF NOT EXISTS idx_story_reactions_user ON story_reactions(user_id);

CREATE TABLE IF NOT EXISTS story_bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, story_id)
);

CREATE INDEX IF NOT EXISTS idx_story_bookmarks_user ON story_bookmarks(user_id, created_at DESC);

ALTER PUBLICATION supabase_realtime ADD TABLE story_reactions;


-- ============================================================
-- RLS for new tables
-- ============================================================

ALTER TABLE reader_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_bookmarks ENABLE ROW LEVEL SECURITY;

-- Reader sessions are public (globe is visible to everyone)
DO $$ BEGIN
  CREATE POLICY "Anyone can view reader sessions" ON reader_sessions
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can insert reader sessions" ON reader_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Story reactions
DO $$ BEGIN
  CREATE POLICY "Anyone can view reactions" ON story_reactions
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can manage own reactions" ON story_reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own reactions" ON story_reactions
    FOR UPDATE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own reactions" ON story_reactions
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Story bookmarks
DO $$ BEGIN
  CREATE POLICY "Users can view own bookmarks" ON story_bookmarks
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can create bookmarks" ON story_bookmarks
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own bookmarks" ON story_bookmarks
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ============================================================
-- DONE! All tables created:
-- - briefings (with drop_type for multi-drop)
-- - stories (with image_url for OG images)
-- - user_reads
-- - user_preferences
-- - reader_sessions (for live globe)
-- - story_reactions
-- - story_bookmarks
-- - device_tokens (already exists from 0000)
-- ============================================================
