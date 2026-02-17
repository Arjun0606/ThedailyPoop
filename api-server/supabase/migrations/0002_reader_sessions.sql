-- Reader sessions for real-time globe visualization
-- Tracks where readers are currently reading (IP geolocation, no precise GPS)

CREATE TABLE reader_sessions (
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

CREATE INDEX idx_reader_sessions_recent ON reader_sessions(created_at DESC);

-- Enable realtime for live globe updates
ALTER PUBLICATION supabase_realtime ADD TABLE reader_sessions;
