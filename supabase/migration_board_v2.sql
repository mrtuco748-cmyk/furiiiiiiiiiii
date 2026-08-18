-- Migracion pizarron v2: tabla board_elements_v2 + boards (tableros anidados)
-- Ejecutar en SQL Editor de Supabase
-- Idempotente: puede ejecutarse varias veces sin error (IF NOT EXISTS)

-- 1. Tabla de elementos del pizarron v2 (espejo del schema SQLite local)
CREATE TABLE IF NOT EXISTS board_elements_v2 (
  id BIGSERIAL PRIMARY KEY,
  type TEXT NOT NULL DEFAULT 'note',
  title TEXT DEFAULT '',
  content TEXT DEFAULT '',
  x DOUBLE PRECISION NOT NULL DEFAULT 0,
  y DOUBLE PRECISION NOT NULL DEFAULT 0,
  width DOUBLE PRECISION,
  height DOUBLE PRECISION,
  rotation DOUBLE PRECISION NOT NULL DEFAULT 0,
  color TEXT,
  text_color TEXT,
  font_family TEXT,
  font_size DOUBLE PRECISION,
  text_align TEXT DEFAULT 'left',
  is_bold BOOLEAN NOT NULL DEFAULT false,
  is_italic BOOLEAN NOT NULL DEFAULT false,
  is_underline BOOLEAN NOT NULL DEFAULT false,
  emoji_header TEXT,
  tags JSONB DEFAULT '[]'::jsonb,
  priority TEXT DEFAULT 'normal',
  assigned_to TEXT,
  user_id TEXT DEFAULT '',
  status TEXT DEFAULT 'draft',
  is_collapsed BOOLEAN NOT NULL DEFAULT false,
  is_locked BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  board_id BIGINT NOT NULL DEFAULT 1,
  z INTEGER NOT NULL DEFAULT 0,
  data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_new BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_board_elements_v2_board_id
  ON board_elements_v2(board_id);

-- 2. Tableros anidados. El id=1 es el tablero raiz "Pizarra".
CREATE TABLE IF NOT EXISTS boards (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'Pizarra',
  parent_id BIGINT REFERENCES boards(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO boards (id, name, parent_id)
VALUES (1, 'Pizarra', NULL)
ON CONFLICT (id) DO NOTHING;

-- 3. RLS full access para la pareja (misma linea del resto de la app)
ALTER TABLE board_elements_v2 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "full_access_board_elements_v2" ON board_elements_v2;
CREATE POLICY "full_access_board_elements_v2" ON board_elements_v2
  FOR ALL USING (true);

ALTER TABLE boards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "full_access_boards" ON boards;
CREATE POLICY "full_access_boards" ON boards FOR ALL USING (true);

GRANT ALL ON board_elements_v2 TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE board_elements_v2_id_seq TO authenticated, service_role;
GRANT ALL ON boards TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE boards_id_seq TO authenticated, service_role;

-- 4. Realtime para el sync en vivo
ALTER PUBLICATION supabase_realtime ADD TABLE board_elements_v2;
