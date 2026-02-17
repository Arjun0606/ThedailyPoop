-- TheDailyPoop: Friend Group Poop Tracking + Anonymous Gossip
-- Lean schema: Map drops (core), Groups, Gossip + Reveals, AI Challenges

-- Users (linked to Supabase Auth via Apple SSO)
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT auth.uid(),
  username text UNIQUE NOT NULL,
  display_name text,
  avatar_url text,
  apple_user_id text UNIQUE,
  total_drops int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users are viewable by everyone"
  ON users FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Friend Groups
CREATE TABLE groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  emoji text DEFAULT '💩',
  created_by uuid REFERENCES users(id),
  invite_code text UNIQUE DEFAULT substr(md5(random()::text), 1, 6),
  max_members int DEFAULT 20,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can view groups"
  ON groups FOR SELECT
  USING (
    id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Authenticated users can create groups"
  ON groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Group Members (junction table)
CREATE TABLE group_members (
  group_id uuid REFERENCES groups(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  role text DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at timestamptz DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view group members"
  ON group_members FOR SELECT
  USING (
    group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can join groups"
  ON group_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can remove members"
  ON group_members FOR DELETE
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
    OR auth.uid() = user_id  -- users can leave
  );

-- Drops (THE CORE FEATURE — poop location pins on the map, scoped to groups)
CREATE TABLE drops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id),
  group_id uuid REFERENCES groups(id),
  caption text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  location_name text,
  reactions jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE drops ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can view drops"
  ON drops FOR SELECT
  USING (
    group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create drops"
  ON drops FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Gossip (the money feature — anonymous posts with paid reveals)
CREATE TABLE gossip (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid REFERENCES users(id),  -- hidden until revealed
  group_id uuid REFERENCES groups(id),
  content text NOT NULL,
  expires_at timestamptz DEFAULT now() + interval '24 hours',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE gossip ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can view gossip"
  ON gossip FOR SELECT
  USING (
    group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can post gossip"
  ON gossip FOR INSERT
  WITH CHECK (auth.uid() = author_id);

-- Gossip Reveals ($1.99 to find out who posted)
CREATE TABLE gossip_reveals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gossip_id uuid REFERENCES gossip(id) ON DELETE CASCADE,
  revealed_by uuid REFERENCES users(id),
  price_cents int DEFAULT 199,
  revealed_at timestamptz DEFAULT now()
);

ALTER TABLE gossip_reveals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see their own reveals"
  ON gossip_reveals FOR SELECT
  USING (auth.uid() = revealed_by);

CREATE POLICY "Users can purchase reveals"
  ON gossip_reveals FOR INSERT
  WITH CHECK (auth.uid() = revealed_by);

-- AI Challenges (daily group challenges)
CREATE TABLE challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES groups(id),
  prompt text NOT NULL,
  challenge_type text CHECK (challenge_type IN ('dare', 'would_you_rather', 'roast', 'vote', 'weekly_recap')),
  options jsonb,
  expires_at timestamptz DEFAULT now() + interval '24 hours',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can see challenges"
  ON challenges FOR SELECT
  USING (
    group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
  );

-- Challenge Responses
CREATE TABLE challenge_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid REFERENCES challenges(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id),
  response text,
  voted_for uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  UNIQUE (challenge_id, user_id)
);

ALTER TABLE challenge_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can see responses"
  ON challenge_responses FOR SELECT
  USING (
    challenge_id IN (
      SELECT c.id FROM challenges c
      JOIN group_members gm ON gm.group_id = c.group_id
      WHERE gm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can respond to challenges"
  ON challenge_responses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Subscriptions (mirrors RevenueCat state)
CREATE TABLE subscriptions (
  user_id uuid PRIMARY KEY REFERENCES users(id),
  tier text DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
  rc_customer_id text,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see their subscription"
  ON subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX idx_drops_group_id ON drops(group_id);
CREATE INDEX idx_drops_user_id ON drops(user_id);
CREATE INDEX idx_drops_created_at ON drops(created_at);
CREATE INDEX idx_gossip_group_id ON gossip(group_id);
CREATE INDEX idx_gossip_expires_at ON gossip(expires_at);
CREATE INDEX idx_challenges_group_id ON challenges(group_id);
CREATE INDEX idx_challenges_expires_at ON challenges(expires_at);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);

-- Spatial index for map queries (find drops near a location)
CREATE INDEX idx_drops_location ON drops(latitude, longitude);

-- Enable Realtime for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE drops;
ALTER PUBLICATION supabase_realtime ADD TABLE gossip;
ALTER PUBLICATION supabase_realtime ADD TABLE challenges;
ALTER PUBLICATION supabase_realtime ADD TABLE challenge_responses;
