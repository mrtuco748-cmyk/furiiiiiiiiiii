-- ============================================================
-- Migración (PROPUESTA): notas compartidas con Supabase (Equipo 3)
-- ============================================================
-- Las notas vivían SOLO en SQLite local (cada dispositivo veía solo las
-- suyas). Para compartirlas entre Facu y Rocio (como reemplaza al pizarrón
-- colaborativo) se sincronizan con la tabla cloud `notes`. La tabla ya
-- existe en la nube (referenciada por el trigger de push `on_note_insert_send_push`),
-- así que aquí se garantizan las columnas + RLS + publicación realtime.
--
-- PROPUESTA para el Equipo 1: mantener el patrón del schema maestro
-- (id BIGSERIAL, user_id TEXT, RLS full_access, GRANT anon/authenticated,
-- ALTER PUBLICATION supabase_realtime ADD TABLE). Idempotente.
-- ============================================================

-- 1. Garantizar la tabla (no toca una existente)
CREATE TABLE IF NOT EXISTS public.notes (
  id         BIGSERIAL PRIMARY KEY,
  user_id    TEXT NOT NULL DEFAULT '',
  title      TEXT NOT NULL DEFAULT '',
  content    TEXT DEFAULT '',
  color      TEXT NOT NULL DEFAULT '#FFF9C4',
  created_at timestamptz DEFAULT NOW(),
  updated_at timestamptz DEFAULT NOW()
);

-- 2. Garantizar columnas en tablas reales creadas antes (sin esta migración)
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS user_id TEXT NOT NULL DEFAULT '';
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS title TEXT NOT NULL DEFAULT '';
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS content TEXT DEFAULT '';
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS color TEXT NOT NULL DEFAULT '#FFF9C4';
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT NOW();
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT NOW();

-- 3. RLS permisivo (app de 2 usuarios, mismo patrón que el resto)
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS full_access_notes ON public.notes;
CREATE POLICY full_access_notes ON public.notes FOR ALL USING (true) WITH CHECK (true);

GRANT ALL ON public.notes TO anon, authenticated;
GRANT ALL ON SEQUENCE public.notes_id_seq TO anon, authenticated;

-- 4. Publicación realtime (para sync bidireccional en vivo)
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notes;
  EXCEPTION WHEN duplicate_object THEN
    NULL; -- ya estaba publicada
  END;
END $$;