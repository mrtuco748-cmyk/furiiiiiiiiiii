-- Migracion schedules sync: comparticion del calendario entre ambos usuarios.
-- 1. user_id en schedules (autor del evento, colores F/R + bot)
-- 2. color BIGINT (el ARGB de Flutter excede INTEGER -> 22003)
-- 3. ambas tablas del calendario en la publicacion realtime
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS user_id TEXT DEFAULT '';

ALTER TABLE schedules ALTER COLUMN color TYPE BIGINT USING color::bigint;

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
