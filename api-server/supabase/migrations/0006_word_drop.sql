-- ============================================================
-- MIGRATION 0006: Word Drop Game
-- Daily news-connected word game for engagement + premium conversion
-- ============================================================

-- Puzzle definitions (one per briefing/drop)
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

-- Player scores (one per user per game)
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_word_games_date ON word_games(publish_date DESC);
CREATE INDEX IF NOT EXISTS idx_word_games_date_drop ON word_games(publish_date, drop_type);
CREATE INDEX IF NOT EXISTS idx_word_game_scores_leaderboard ON word_game_scores(game_id, score DESC);
CREATE INDEX IF NOT EXISTS idx_word_game_scores_user ON word_game_scores(user_id);

-- Game streak columns on users
ALTER TABLE users ADD COLUMN IF NOT EXISTS game_streak int DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS game_streak_last_played date;
ALTER TABLE users ADD COLUMN IF NOT EXISTS highest_word_score int DEFAULT 0;

-- RLS
ALTER TABLE word_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_game_scores ENABLE ROW LEVEL SECURITY;

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
