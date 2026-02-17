-- Story reactions (fire, skull, laugh, mindblown)
CREATE TABLE story_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  reaction text NOT NULL CHECK (reaction IN ('fire', 'skull', 'laugh', 'mindblown')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, story_id)
);

CREATE INDEX idx_story_reactions_story ON story_reactions(story_id);
CREATE INDEX idx_story_reactions_user ON story_reactions(user_id);

-- Story bookmarks (save for later)
CREATE TABLE story_bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, story_id)
);

CREATE INDEX idx_story_bookmarks_user ON story_bookmarks(user_id, created_at DESC);

-- Enable realtime for reactions (live globe feed)
ALTER PUBLICATION supabase_realtime ADD TABLE story_reactions;
