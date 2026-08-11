-- Migracion class_schedules: clases recurrentes por dia de semana en Supabase
-- Para que el bot de WhatsApp avise antes de que empiecen.
-- Ejecutar en SQL Editor de Supabase
-- Idempotente: puede ejecutarse varias veces sin error (IF NOT EXISTS)

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

-- Tablas creadas antes con color INTEGER rechazan 0xFF7B2D8E (4286262670
-- > max int32 2147483647). BIGINT soporta el ARGB completo.
ALTER TABLE class_schedules ALTER COLUMN color TYPE BIGINT USING color::bigint;

CREATE INDEX IF NOT EXISTS class_schedules_day_idx
  ON class_schedules (day_of_week);