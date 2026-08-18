-- MAZO: tarjetas swipe tipo Tinder (ideas, chistes, poemas, recetas,
-- retos, random, sueno, me_paso)
-- Reacciones JSONB: {"<user_id>": "encanta" | "me_gusta" | "meh" | "no_me_gusta"}
-- MATCH = dos o mas reacciones y todas "encanta"

CREATE TABLE IF NOT EXISTS deck_cards (
  id BIGSERIAL PRIMARY KEY,
  category TEXT NOT NULL DEFAULT 'random',
  content TEXT NOT NULL,
  created_by TEXT NOT NULL DEFAULT '',
  reactions JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deck_cards_category ON deck_cards(category);
CREATE INDEX IF NOT EXISTS idx_deck_cards_created_at ON deck_cards(created_at);

ALTER TABLE deck_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "full_access_deck_cards" ON deck_cards;
CREATE POLICY "full_access_deck_cards" ON deck_cards FOR ALL USING (true);

-- Realtime (idempotente)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'deck_cards'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE deck_cards;
  END IF;
END $$;
