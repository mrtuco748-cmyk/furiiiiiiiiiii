-- EJERCICIOS: registros, rutinas con plan semanal, completados por
-- persona y retos con aprobacion conjunta.
-- social JSONB = {"reactions": {"🔥": ["uuid"]}, "comments": [{...}]}
-- Ejecutar en SQL Editor de Supabase. Idempotente.

-- 1. WORKOUT LOGS (registro de ejercicio: suelto o de rutina)
CREATE TABLE IF NOT EXISTS workout_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  exercise_name TEXT NOT NULL,
  muscle_group TEXT,
  series INT,
  reps INT,
  weight NUMERIC,
  rest_seconds INT,
  notes TEXT,
  routine_id BIGINT,
  logged_on DATE DEFAULT CURRENT_DATE,
  social JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_logs_logged_on ON workout_logs(logged_on);
CREATE INDEX IF NOT EXISTS idx_workout_logs_name ON workout_logs(exercise_name);

-- 2. WORKOUT ROUTINES (rutina con items JSONB; day_of_week 1=lunes..7=domingo)
CREATE TABLE IF NOT EXISTS workout_routines (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  name TEXT NOT NULL,
  day_of_week INT,
  items JSONB DEFAULT '[]'::jsonb,
  social JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_routines_day ON workout_routines(day_of_week);

-- 3. WORKOUT COMPLETIONS (cada persona marca su dia)
CREATE TABLE IF NOT EXISTS workout_completions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  completed_on DATE DEFAULT CURRENT_DATE,
  routine_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, completed_on, routine_id)
);

CREATE INDEX IF NOT EXISTS idx_workout_completions_on ON workout_completions(completed_on);

-- 4. WORKOUT CHALLENGES (aprobacion y completado conjuntos)
CREATE TABLE IF NOT EXISTS workout_challenges (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES profiles(id) NOT NULL,
  approved_by JSONB DEFAULT '[]'::jsonb,
  completed_by JSONB DEFAULT '[]'::jsonb,
  social JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS + policies (full access, app privada de 2 usuarios)
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_challenges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "full_access_workout_logs" ON workout_logs;
DROP POLICY IF EXISTS "full_access_workout_routines" ON workout_routines;
DROP POLICY IF EXISTS "full_access_workout_completions" ON workout_completions;
DROP POLICY IF EXISTS "full_access_workout_challenges" ON workout_challenges;

CREATE POLICY "full_access_workout_logs" ON workout_logs FOR ALL USING (true);
CREATE POLICY "full_access_workout_routines" ON workout_routines FOR ALL USING (true);
CREATE POLICY "full_access_workout_completions" ON workout_completions FOR ALL USING (true);
CREATE POLICY "full_access_workout_challenges" ON workout_challenges FOR ALL USING (true);

GRANT ALL ON workout_logs TO anon, authenticated, service_role;
GRANT ALL ON workout_routines TO anon, authenticated, service_role;
GRANT ALL ON workout_completions TO anon, authenticated, service_role;
GRANT ALL ON workout_challenges TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Realtime (idempotente)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'workout_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE workout_logs;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'workout_routines'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE workout_routines;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'workout_completions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE workout_completions;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'workout_challenges'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE workout_challenges;
  END IF;
END $$;
