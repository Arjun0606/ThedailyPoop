-- Poop or Scoop: daily real/fake headline game

CREATE TABLE scoop_games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  briefing_id uuid NOT NULL REFERENCES briefings(id) ON DELETE CASCADE,
  publish_date date NOT NULL,
  headlines jsonb NOT NULL,            -- [{headline, isReal, sourceStoryId?}]
  created_at timestamptz DEFAULT now(),
  UNIQUE(briefing_id)
);

CREATE TABLE scoop_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  game_id uuid NOT NULL REFERENCES scoop_games(id) ON DELETE CASCADE,
  score int NOT NULL DEFAULT 0,
  total int NOT NULL DEFAULT 10,
  answers jsonb NOT NULL DEFAULT '[]',  -- [{headline, guessedReal, wasReal}]
  played_at timestamptz DEFAULT now(),
  UNIQUE(user_id, game_id)
);

CREATE INDEX idx_scoop_games_date ON scoop_games(publish_date DESC);
CREATE INDEX idx_scoop_scores_leaderboard ON scoop_scores(game_id, score DESC);

ALTER TABLE scoop_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE scoop_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view scoop games" ON scoop_games FOR SELECT USING (true);
CREATE POLICY "Anyone can view scoop scores" ON scoop_scores FOR SELECT USING (true);
CREATE POLICY "Users submit own scoop scores" ON scoop_scores FOR INSERT WITH CHECK (auth.uid() = user_id);
