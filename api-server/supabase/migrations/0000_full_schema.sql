-- TheDailyPoop: Complete Schema
-- Run this ONCE in the Supabase SQL Editor

-- ============================================================
-- STEP 1: Create all tables (no RLS policies yet)
-- ============================================================

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT auth.uid(),
  username text UNIQUE NOT NULL,
  display_name text,
  avatar_url text,
  apple_user_id text UNIQUE,
  total_drops int DEFAULT 0,
  streak_count int DEFAULT 0,
  streak_last_active date,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  emoji text DEFAULT '💩',
  created_by uuid REFERENCES users(id),
  invite_code text UNIQUE DEFAULT substr(md5(random()::text), 1, 6),
  max_members int DEFAULT 20,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE group_members (
  group_id uuid REFERENCES groups(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  role text DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at timestamptz DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);

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

CREATE TABLE gossip (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid REFERENCES users(id),
  group_id uuid REFERENCES groups(id),
  content text NOT NULL,
  expires_at timestamptz DEFAULT now() + interval '24 hours',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE gossip_reveals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gossip_id uuid REFERENCES gossip(id) ON DELETE CASCADE,
  revealed_by uuid REFERENCES users(id),
  price_cents int DEFAULT 199,
  revealed_at timestamptz DEFAULT now()
);

CREATE TABLE challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES groups(id),
  prompt text NOT NULL,
  challenge_type text CHECK (challenge_type IN ('dare', 'would_you_rather', 'roast', 'vote', 'weekly_recap')),
  options jsonb,
  expires_at timestamptz DEFAULT now() + interval '24 hours',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE challenge_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid REFERENCES challenges(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id),
  response text,
  voted_for uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  UNIQUE (challenge_id, user_id)
);

CREATE TABLE subscriptions (
  user_id uuid PRIMARY KEY REFERENCES users(id),
  tier text DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
  rc_customer_id text,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE waitlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE invite_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code text NOT NULL UNIQUE,
  used_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL DEFAULT 'ios',
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, platform)
);

-- ============================================================
-- STEP 2: Enable RLS on all tables
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE drops ENABLE ROW LEVEL SECURITY;
ALTER TABLE gossip ENABLE ROW LEVEL SECURITY;
ALTER TABLE gossip_reveals ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 3: RLS Policies
-- ============================================================

-- Users
CREATE POLICY "Users are viewable by everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can delete own profile" ON users FOR DELETE USING (auth.uid() = id);

-- Groups (open SELECT so users can look up by invite_code before joining)
CREATE POLICY "Anyone can view groups" ON groups FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create groups" ON groups FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Group Members
CREATE POLICY "Members can view group members" ON group_members FOR SELECT
  USING (group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));
CREATE POLICY "Users can join groups" ON group_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave or admins can remove" ON group_members FOR DELETE
  USING (
    auth.uid() = user_id
    OR group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid() AND role = 'admin')
  );

-- Drops
CREATE POLICY "Group members can view drops" ON drops FOR SELECT
  USING (group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));
CREATE POLICY "Users can create drops" ON drops FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own drops" ON drops FOR DELETE USING (auth.uid() = user_id);

-- Gossip
CREATE POLICY "Group members can view gossip" ON gossip FOR SELECT
  USING (group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));
CREATE POLICY "Users can post gossip" ON gossip FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can delete own gossip" ON gossip FOR DELETE USING (auth.uid() = author_id);

-- Gossip Reveals
CREATE POLICY "Users can see their own reveals" ON gossip_reveals FOR SELECT USING (auth.uid() = revealed_by);
CREATE POLICY "Users can purchase reveals" ON gossip_reveals FOR INSERT WITH CHECK (auth.uid() = revealed_by);

-- Challenges
CREATE POLICY "Group members can see challenges" ON challenges FOR SELECT
  USING (group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid()));

-- Challenge Responses
CREATE POLICY "Group members can see responses" ON challenge_responses FOR SELECT
  USING (challenge_id IN (
    SELECT c.id FROM challenges c
    JOIN group_members gm ON gm.group_id = c.group_id
    WHERE gm.user_id = auth.uid()
  ));
CREATE POLICY "Users can respond to challenges" ON challenge_responses FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Subscriptions
CREATE POLICY "Users can see their subscription" ON subscriptions FOR SELECT USING (auth.uid() = user_id);

-- Waitlist
CREATE POLICY "Users can join waitlist" ON waitlist FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Anyone can see waitlist" ON waitlist FOR SELECT USING (true);
CREATE POLICY "Users can update waitlist entry" ON waitlist FOR UPDATE USING (auth.uid() = user_id);

-- Invite Codes
CREATE POLICY "Anyone can look up invite codes" ON invite_codes FOR SELECT USING (true);
CREATE POLICY "Users can create invite codes" ON invite_codes FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can redeem invite codes" ON invite_codes FOR UPDATE
  USING (used_by IS NULL) WITH CHECK (auth.uid() = used_by);

-- Device Tokens
CREATE POLICY "Users can manage own tokens" ON device_tokens FOR ALL
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- STEP 4: Indexes
-- ============================================================

CREATE INDEX idx_drops_group_id ON drops(group_id);
CREATE INDEX idx_drops_user_id ON drops(user_id);
CREATE INDEX idx_drops_created_at ON drops(created_at);
CREATE INDEX idx_drops_location ON drops(latitude, longitude);
CREATE INDEX idx_gossip_group_id ON gossip(group_id);
CREATE INDEX idx_gossip_expires_at ON gossip(expires_at);
CREATE INDEX idx_challenges_group_id ON challenges(group_id);
CREATE INDEX idx_challenges_expires_at ON challenges(expires_at);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
CREATE INDEX idx_invite_codes_owner ON invite_codes(owner_id);
CREATE INDEX idx_invite_codes_code ON invite_codes(code);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_users_streak ON users(streak_count) WHERE streak_count > 0;

-- ============================================================
-- STEP 5: Enable Realtime
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE drops;
ALTER PUBLICATION supabase_realtime ADD TABLE gossip;
ALTER PUBLICATION supabase_realtime ADD TABLE challenges;
ALTER PUBLICATION supabase_realtime ADD TABLE challenge_responses;
ALTER PUBLICATION supabase_realtime ADD TABLE invite_codes;
