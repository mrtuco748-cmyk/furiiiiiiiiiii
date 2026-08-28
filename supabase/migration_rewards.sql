-- Fase 3.2: puntos y recompensas de pareja 🪙
-- Cajita de deseos (reward físico que cuesta puntos) + libro de puntos.
-- Idempotente.

CREATE TABLE IF NOT EXISTS couple_rewards (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '🎁',
  cost INTEGER NOT NULL DEFAULT 10,
  fulfilled BOOLEAN NOT NULL DEFAULT false,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS couple_points (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  delta INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unicidad (user_id, reason): hace que awardOnce sea atómicamente idempotente
-- (upsert con ON CONFLICT DO NOTHING). Sin esto, dos dispositivos/realtime
-- disparando la misma razón duplicaban puntos (race check-then-insert).
CREATE UNIQUE INDEX IF NOT EXISTS idx_couple_points_user_reason
  ON couple_points(user_id, reason);

CREATE INDEX IF NOT EXISTS idx_couple_rewards_created ON couple_rewards(created_at);
CREATE INDEX IF NOT EXISTS idx_couple_points_user ON couple_points(user_id);

ALTER TABLE couple_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_points ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'couple_rewards' AND policyname = 'full_access_couple_rewards') THEN
    CREATE POLICY full_access_couple_rewards ON couple_rewards FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'couple_points' AND policyname = 'full_access_couple_points') THEN
    CREATE POLICY full_access_couple_points ON couple_points FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'couple_rewards') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE couple_rewards;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'couple_points') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE couple_points;
  END IF;
END $$;

GRANT ALL ON couple_rewards TO anon, authenticated;
GRANT USAGE ON SEQUENCE couple_rewards_id_seq TO anon, authenticated;
GRANT ALL ON couple_points TO anon, authenticated;
GRANT USAGE ON SEQUENCE couple_points_id_seq TO anon, authenticated;