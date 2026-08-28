-- Logros de pareja (Fase 1.2 del roadmap "capa de juego")
-- Colección de insignias que la pareja desbloquea al cumplir hitos.
-- Idempotente: puede ejecutarse varias veces sin error.

CREATE TABLE IF NOT EXISTS couple_achievements (
  id BIGSERIAL PRIMARY KEY,
  achievement_code TEXT NOT NULL UNIQUE,
  awarded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_couple_achievements_awarded
  ON couple_achievements (awarded_at DESC);

-- RLS full access (app privada de 2 usuarios, mismo patrón que el resto)
ALTER TABLE couple_achievements ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'couple_achievements' AND policyname = 'full_access_couple_achievements'
  ) THEN
    CREATE POLICY full_access_couple_achievements
      ON couple_achievements FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- Publicación realtime para que ambos dispositivos vean los logros al instante
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'couple_achievements'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE couple_achievements;
  END IF;
END $$;

GRANT ALL ON couple_achievements TO anon, authenticated;
GRANT USAGE ON SEQUENCE couple_achievements_id_seq TO anon, authenticated;