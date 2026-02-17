-- TheDailyPoop Pivot: Social Media → Daily News Briefing
-- This migration drops all social tables and creates the briefing schema.

-- ============================================================
-- STEP 1: Remove realtime publications for old tables
-- ============================================================

ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS drops;
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS gossip;
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS challenges;
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS challenge_responses;
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS invite_codes;

-- ============================================================
-- STEP 2: Drop social tables (order matters for foreign keys)
-- ============================================================

DROP TABLE IF EXISTS challenge_responses CASCADE;
DROP TABLE IF EXISTS challenges CASCADE;
DROP TABLE IF EXISTS gossip_reveals CASCADE;
DROP TABLE IF EXISTS gossip CASCADE;
DROP TABLE IF EXISTS drops CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS waitlist CASCADE;
DROP TABLE IF EXISTS invite_codes CASCADE;

-- ============================================================
-- STEP 3: Add premium columns to users table
-- ============================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS premium_expires_at timestamptz;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rc_customer_id text;
-- Drop social-only column
ALTER TABLE users DROP COLUMN IF EXISTS total_drops;

-- ============================================================
-- STEP 4: Create briefing tables
-- ============================================================

CREATE TABLE briefings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  publish_date date UNIQUE NOT NULL,
  headline text NOT NULL,
  intro_text text,
  story_count int DEFAULT 10,
  free_story_count int DEFAULT 3,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  published_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE stories (
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
  emoji text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE user_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  read_at timestamptz DEFAULT now(),
  UNIQUE(user_id, story_id)
);

CREATE TABLE user_preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  favorite_categories text[] DEFAULT '{"business","tech","culture"}',
  push_enabled boolean DEFAULT true,
  push_time time DEFAULT '07:00',
  updated_at timestamptz DEFAULT now()
);

-- ============================================================
-- STEP 5: Enable RLS on new tables
-- ============================================================

ALTER TABLE briefings ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 6: RLS Policies
-- ============================================================

-- Briefings — public read (everyone sees briefings)
CREATE POLICY "Anyone can view published briefings" ON briefings
  FOR SELECT USING (status = 'published');

-- Stories — public read (gating is done in-app, not at DB level)
CREATE POLICY "Anyone can view stories" ON stories
  FOR SELECT USING (true);

-- User reads — users can only see/create their own
CREATE POLICY "Users can view own reads" ON user_reads
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can mark stories read" ON user_reads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User preferences — users own their prefs
CREATE POLICY "Users can view own preferences" ON user_preferences
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own preferences" ON user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================
-- STEP 7: Indexes
-- ============================================================

CREATE INDEX idx_briefings_publish_date ON briefings(publish_date DESC);
CREATE INDEX idx_briefings_status ON briefings(status);
CREATE INDEX idx_stories_briefing_id ON stories(briefing_id);
CREATE INDEX idx_stories_sort_order ON stories(briefing_id, sort_order);
CREATE INDEX idx_stories_category ON stories(category);
CREATE INDEX idx_user_reads_user ON user_reads(user_id);
CREATE INDEX idx_user_reads_story ON user_reads(story_id);
CREATE INDEX idx_user_reads_date ON user_reads(read_at);

-- ============================================================
-- STEP 8: Enable Realtime for briefings (live updates)
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE briefings;
ALTER PUBLICATION supabase_realtime ADD TABLE stories;
