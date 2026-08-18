-- Migracion schedules sync: comparticion del calendario entre ambos usuarios.
-- 1. user_id en schedules (autor del evento, colores F/R + bot)
-- 2. color BIGINT (el ARGB de Flutter excede INTEGER -> 22003)
-- 3. ambas tablas del calendario en la publicacion realtime
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS user_id TEXT DEFAULT '';

ALTER TABLE schedules ALTER COLUMN color TYPE BIGINT USING color::bigint;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'schedules') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE schedules;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'class_schedules') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE class_schedules;
  END IF;
END $$;
