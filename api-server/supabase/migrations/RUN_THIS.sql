-- ============================================================
-- TheDailyPoop: COMPLETE SETUP (paste into Supabase SQL Editor)
-- Safe to re-run — uses IF EXISTS / IF NOT EXISTS everywhere.
-- ============================================================


-- ============================================================
-- 1. FIX USERS TABLE — add missing columns
-- ============================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS premium_expires_at timestamptz;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rc_customer_id text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS game_streak int DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS game_streak_last_played date;
ALTER TABLE users ADD COLUMN IF NOT EXISTS highest_word_score int DEFAULT 0;
ALTER TABLE users DROP COLUMN IF EXISTS total_drops;


-- ============================================================
-- 2. BRIEFINGS TABLE (with multi-drop support)
-- ============================================================
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

CREATE INDEX IF NOT EXISTS idx_briefings_publish_date ON briefings(publish_date DESC);
CREATE INDEX IF NOT EXISTS idx_briefings_status ON briefings(status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_briefings_date_drop ON briefings(publish_date, drop_type);


-- ============================================================
-- 3. STORIES TABLE
-- ============================================================
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

CREATE INDEX IF NOT EXISTS idx_stories_briefing_id ON stories(briefing_id);
CREATE INDEX IF NOT EXISTS idx_stories_sort_order ON stories(briefing_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_stories_category ON stories(category);


-- ============================================================
-- 4. USER READS
-- ============================================================
CREATE TABLE IF NOT EXISTS user_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  read_at timestamptz DEFAULT now(),
  UNIQUE(user_id, story_id)
);

CREATE INDEX IF NOT EXISTS idx_user_reads_user ON user_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_user_reads_story ON user_reads(story_id);
CREATE INDEX IF NOT EXISTS idx_user_reads_date ON user_reads(read_at);


-- ============================================================
-- 5. USER PREFERENCES
-- ============================================================
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  favorite_categories text[] DEFAULT '{"business","tech","culture"}',
  push_enabled boolean DEFAULT true,
  push_time time DEFAULT '07:00',
  updated_at timestamptz DEFAULT now()
);


-- ============================================================
-- 6. READER SESSIONS (Live Globe)
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


-- ============================================================
-- 7. REACTIONS & BOOKMARKS
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


-- ============================================================
-- 8. WORD DROP GAME
-- ============================================================
CREATE TABLE IF NOT EXISTS word_games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  drop_type text NOT NULL,
  publish_date date NOT NULL,
  key_word text NOT NULL,
  letters text[] NOT NULL,
  valid_words jsonb NOT NULL,
  story_headline text NOT NULL,
  story_id uuid REFERENCES stories(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(briefing_id)
);

CREATE TABLE IF NOT EXISTS word_game_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  game_id uuid NOT NULL REFERENCES word_games(id) ON DELETE CASCADE,
  score int NOT NULL DEFAULT 0,
  words_found text[] NOT NULL DEFAULT '{}',
  word_count int NOT NULL DEFAULT 0,
  found_key_word boolean NOT NULL DEFAULT false,
  time_remaining int NOT NULL DEFAULT 0,
  played_at timestamptz DEFAULT now(),
  UNIQUE(user_id, game_id)
);

CREATE INDEX IF NOT EXISTS idx_word_games_date ON word_games(publish_date DESC);
CREATE INDEX IF NOT EXISTS idx_word_games_date_drop ON word_games(publish_date, drop_type);
CREATE INDEX IF NOT EXISTS idx_word_game_scores_leaderboard ON word_game_scores(game_id, score DESC);
CREATE INDEX IF NOT EXISTS idx_word_game_scores_user ON word_game_scores(user_id);


-- ============================================================
-- 9. RLS POLICIES
-- ============================================================
ALTER TABLE briefings ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE reader_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_game_scores ENABLE ROW LEVEL SECURITY;

-- Briefings
DO $$ BEGIN
  CREATE POLICY "Anyone can view published briefings" ON briefings
    FOR SELECT USING (status = 'published');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Stories
DO $$ BEGIN
  CREATE POLICY "Anyone can view stories" ON stories
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- User reads
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

-- User preferences
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

-- Reader sessions
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

-- Reactions
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

-- Bookmarks
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

-- Word games
DO $$ BEGIN
  CREATE POLICY "Anyone can view word games" ON word_games
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Anyone can view word game scores" ON word_game_scores
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can submit own scores" ON word_game_scores
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ============================================================
-- 10. REALTIME
-- ============================================================
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE briefings;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE stories;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE reader_sessions;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE story_reactions;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ============================================================
-- DONE! Tables: briefings, stories, user_reads, user_preferences,
-- reader_sessions, story_reactions, story_bookmarks, word_games,
-- word_game_scores. Users table updated with all needed columns.
-- ============================================================
