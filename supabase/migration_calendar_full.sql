-- ===========================================================================
-- MIGRACION COMBINADA: sync de calendario/clases entre ambos usuarios
-- Ejecutar ESTE archivo completo en el SQL Editor de Supabase (una sola vez).
-- Es idempotente: se puede correr varias veces sin error.
-- Orden: (1) crear class_schedules, (2) columnas/color de schedules + realtime,
--        (3) RLS full access + grants + realtime para ambas tablas.
-- ===========================================================================

-- (1) class_schedules: tabla de clases recurrentes por dia de semana
CREATE TABLE IF NOT EXISTS class_schedules (
  id BIGSERIAL PRIMARY KEY,
  day_of_week INTEGER NOT NULL,
  class_type_id BIGINT,
  start_time TEXT NOT NULL,
  title TEXT NOT NULL,
  end_time TEXT DEFAULT '',
  professor TEXT DEFAULT '',
  user_id TEXT DEFAULT '',
  color BIGINT DEFAULT 4286262670,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE class_schedules ALTER COLUMN color TYPE BIGINT USING color::bigint;

CREATE INDEX IF NOT EXISTS class_schedules_day_idx
  ON class_schedules (day_of_week);

-- (2) schedules: user_id (autor) + color BIGINT (el ARGB de Flutter excede INTEGER)
--     y agregar ambas tablas a la publicacion realtime.
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS user_id TEXT DEFAULT '';

ALTER TABLE schedules ALTER COLUMN color TYPE BIGINT USING color::bigint;

-- (3) RLS full access + grants para que AMBOS usuarios vean/escriban,
--     y realtime (con manejo de duplicate_object).
DROP POLICY IF EXISTS "full_access_schedules" ON schedules;
DROP POLICY IF EXISTS "full_access_class_schedules" ON class_schedules;

ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "full_access_schedules" ON schedules
  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "full_access_class_schedules" ON class_schedules
  FOR ALL USING (true) WITH CHECK (true);

GRANT ALL ON TABLE schedules TO anon;
GRANT ALL ON TABLE schedules TO authenticated;
GRANT ALL ON TABLE class_schedules TO anon;
GRANT ALL ON TABLE class_schedules TO authenticated;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE schedules;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE class_schedules;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;

-- FIN
