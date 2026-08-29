-- UBICACIONES DE LA PAREJA (Fase 1.3: Mapa/Distancia en tiempo real)
-- La última ubicación conocida de cada miembro (PK = user_id). La distancia
-- entre ambos se calcula en el cliente por haversine, con realtime.
CREATE TABLE IF NOT EXISTS couple_locations (
  user_id TEXT PRIMARY KEY,
  lat DOUBLE PRECISION NOT NULL DEFAULT 0,
  lng DOUBLE PRECISION NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE couple_locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "full_access_couple_locations" ON couple_locations;
CREATE POLICY "full_access_couple_locations" ON couple_locations FOR ALL USING (true);

-- Realtime (idempotente: ignora si ya es miembro de la publicación)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'couple_locations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE couple_locations;
  END IF;
END $$;
GRANT ALL ON couple_locations TO anon, authenticated;