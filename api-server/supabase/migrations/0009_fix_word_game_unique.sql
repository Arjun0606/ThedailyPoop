-- Fix: Allow 3 word games per briefing (morning, midday, evening)
-- The old UNIQUE(briefing_id) only allowed 1 game per briefing
ALTER TABLE word_games DROP CONSTRAINT IF EXISTS word_games_briefing_id_key;
ALTER TABLE word_games ADD CONSTRAINT word_games_briefing_drop_unique UNIQUE(briefing_id, drop_type);
