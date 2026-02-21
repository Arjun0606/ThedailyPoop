-- ═══════════════════════════════════════════════════════════════
-- v2 PIVOT MIGRATION — TheDailyPoop (Feb 2026)
-- New games, comments, any-emoji reactions, Today's Vibe
-- ═══════════════════════════════════════════════════════════════

-- 1. Add Today's Vibe columns to briefings
ALTER TABLE briefings ADD COLUMN IF NOT EXISTS vibe_label text;
ALTER TABLE briefings ADD COLUMN IF NOT EXISTS vibe_emoji text;

-- 2. Drop the fixed-emoji CHECK constraint on story_reactions (allow any emoji)
ALTER TABLE story_reactions DROP CONSTRAINT IF EXISTS story_reactions_reaction_check;

-- 3. Story comments
CREATE TABLE story_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  body text NOT NULL,
  upvotes int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_story_comments_story ON story_comments(story_id, created_at DESC);
CREATE INDEX idx_story_comments_user ON story_comments(user_id);
CREATE INDEX idx_story_comments_top ON story_comments(story_id, upvotes DESC);

ALTER TABLE story_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view comments" ON story_comments FOR SELECT USING (true);
CREATE POLICY "Users post own comments" ON story_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users edit own comments" ON story_comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own comments" ON story_comments FOR DELETE USING (auth.uid() = user_id);

-- Comment upvotes tracking (prevent double-voting)
CREATE TABLE comment_upvotes (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  comment_id uuid NOT NULL REFERENCES story_comments(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, comment_id)
);

ALTER TABLE comment_upvotes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view upvotes" ON comment_upvotes FOR SELECT USING (true);
CREATE POLICY "Users cast own upvotes" ON comment_upvotes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users remove own upvotes" ON comment_upvotes FOR DELETE USING (auth.uid() = user_id);

-- 4. Who Said It game
CREATE TABLE who_said_it_games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  publish_date date NOT NULL,
  rounds jsonb NOT NULL,  -- [{quote, correctAnswer, options: ["CEO","Dictator","Cult Leader","Reality TV"]}]
  created_at timestamptz DEFAULT now(),
  UNIQUE(briefing_id)
);

CREATE TABLE who_said_it_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  game_id uuid NOT NULL REFERENCES who_said_it_games(id) ON DELETE CASCADE,
  score int NOT NULL DEFAULT 0,
  total int NOT NULL DEFAULT 5,
  answers jsonb NOT NULL DEFAULT '[]',
  played_at timestamptz DEFAULT now(),
  UNIQUE(user_id, game_id)
);

CREATE INDEX idx_wsi_games_date ON who_said_it_games(publish_date DESC);
CREATE INDEX idx_wsi_scores_lb ON who_said_it_scores(game_id, score DESC);

ALTER TABLE who_said_it_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE who_said_it_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view wsi games" ON who_said_it_games FOR SELECT USING (true);
CREATE POLICY "Anyone can view wsi scores" ON who_said_it_scores FOR SELECT USING (true);
CREATE POLICY "Users submit own wsi scores" ON who_said_it_scores FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. Spin the Excuse game
CREATE TABLE excuse_games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  publish_date date NOT NULL,
  rounds jsonb NOT NULL,  -- [{scenario, correctExcuse, options: [excuse1, excuse2, excuse3, excuse4]}]
  created_at timestamptz DEFAULT now(),
  UNIQUE(briefing_id)
);

CREATE TABLE excuse_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  game_id uuid NOT NULL REFERENCES excuse_games(id) ON DELETE CASCADE,
  score int NOT NULL DEFAULT 0,
  total int NOT NULL DEFAULT 5,
  answers jsonb NOT NULL DEFAULT '[]',
  played_at timestamptz DEFAULT now(),
  UNIQUE(user_id, game_id)
);

CREATE INDEX idx_excuse_games_date ON excuse_games(publish_date DESC);
CREATE INDEX idx_excuse_scores_lb ON excuse_scores(game_id, score DESC);

ALTER TABLE excuse_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE excuse_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view excuse games" ON excuse_games FOR SELECT USING (true);
CREATE POLICY "Anyone can view excuse scores" ON excuse_scores FOR SELECT USING (true);
CREATE POLICY "Users submit own excuse scores" ON excuse_scores FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6. The Roast
CREATE TABLE roast_prompts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  publish_date date NOT NULL,
  story_headline text NOT NULL,
  story_summary text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(briefing_id)
);

CREATE TABLE roast_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_id uuid NOT NULL REFERENCES roast_prompts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body text NOT NULL,
  ai_score int,              -- AI judge score 1-10
  ai_feedback text,          -- AI judge one-liner feedback
  upvotes int NOT NULL DEFAULT 0,
  is_jester_of_day boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, prompt_id) -- one entry per user per day
);

CREATE TABLE roast_votes (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_id uuid NOT NULL REFERENCES roast_entries(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, entry_id)
);

CREATE INDEX idx_roast_prompts_date ON roast_prompts(publish_date DESC);
CREATE INDEX idx_roast_entries_top ON roast_entries(prompt_id, upvotes DESC);
CREATE INDEX idx_roast_entries_jester ON roast_entries(is_jester_of_day) WHERE is_jester_of_day = true;

ALTER TABLE roast_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE roast_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE roast_votes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view roast prompts" ON roast_prompts FOR SELECT USING (true);
CREATE POLICY "Anyone can view roast entries" ON roast_entries FOR SELECT USING (true);
CREATE POLICY "Users submit own roast entries" ON roast_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Anyone can view roast votes" ON roast_votes FOR SELECT USING (true);
CREATE POLICY "Users cast own roast votes" ON roast_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users remove own roast votes" ON roast_votes FOR DELETE USING (auth.uid() = user_id);

-- 7. Predict the Poop
CREATE TABLE predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  publish_date date NOT NULL,
  question text NOT NULL,           -- "Will X happen?"
  context text,                     -- brief context for the prediction
  resolve_by date NOT NULL,         -- when this should be resolved
  resolved_at timestamptz,
  outcome boolean,                  -- true = happened, false = didn't, null = pending
  created_at timestamptz DEFAULT now()
);

CREATE TABLE prediction_bets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id uuid NOT NULL REFERENCES predictions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bet boolean NOT NULL,             -- true = "yes it'll happen", false = "no way"
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, prediction_id)
);

CREATE INDEX idx_predictions_date ON predictions(publish_date DESC);
CREATE INDEX idx_predictions_pending ON predictions(outcome) WHERE outcome IS NULL;
CREATE INDEX idx_prediction_bets_user ON prediction_bets(user_id);
CREATE INDEX idx_prediction_bets_pred ON prediction_bets(prediction_id);

ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prediction_bets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view predictions" ON predictions FOR SELECT USING (true);
CREATE POLICY "Anyone can view prediction bets" ON prediction_bets FOR SELECT USING (true);
CREATE POLICY "Users place own bets" ON prediction_bets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 8. Headline Roulette
CREATE TABLE headline_roulette_games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  publish_date date NOT NULL,
  headlines jsonb NOT NULL,  -- [{headline, insanityRank}] (ranked 1-5 by "objective" insanity)
  created_at timestamptz DEFAULT now(),
  UNIQUE(briefing_id)
);

CREATE TABLE headline_roulette_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  game_id uuid NOT NULL REFERENCES headline_roulette_games(id) ON DELETE CASCADE,
  score int NOT NULL DEFAULT 0,     -- how close their ranking matched
  user_ranking jsonb NOT NULL,      -- their submitted order
  played_at timestamptz DEFAULT now(),
  UNIQUE(user_id, game_id)
);

CREATE INDEX idx_hr_games_date ON headline_roulette_games(publish_date DESC);
CREATE INDEX idx_hr_scores_lb ON headline_roulette_scores(game_id, score DESC);

ALTER TABLE headline_roulette_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE headline_roulette_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view hr games" ON headline_roulette_games FOR SELECT USING (true);
CREATE POLICY "Anyone can view hr scores" ON headline_roulette_scores FOR SELECT USING (true);
CREATE POLICY "Users submit own hr scores" ON headline_roulette_scores FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Enable realtime for comments (live engagement)
ALTER PUBLICATION supabase_realtime ADD TABLE story_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE roast_entries;
