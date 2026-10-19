-- Migración para el Pizarrón Infinito de F.U.R.I.
-- Elementos colaborativos: notas, checklists, dibujos sincronizados en tiempo real.

CREATE TABLE IF NOT EXISTS board_elements (
  id BIGSERIAL PRIMARY KEY,
  board_id BIGINT NOT NULL DEFAULT 1,
  user_id TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL DEFAULT 'note',
  title TEXT NOT NULL DEFAULT '',
  content TEXT DEFAULT '',
  color TEXT NOT NULL DEFAULT '#9D00FF',
  x DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  y DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  width DOUBLE PRECISION NOT NULL DEFAULT 200.0,
  height DOUBLE PRECISION NOT NULL DEFAULT 160.0,
  data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar Realtime para board_elements
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE board_elements;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;
