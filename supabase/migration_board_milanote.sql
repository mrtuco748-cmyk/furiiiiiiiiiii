-- Migracion pizarron Milanote-style: z-order + data JSONB + bucket de imagenes
-- Ejecutar en SQL Editor de Supabase
-- Idempotente: puede ejecutarse varias veces sin error (IF NOT EXISTS)

-- Orden de capas (mayor z = mas al frente)
ALTER TABLE board_elements
  ADD COLUMN IF NOT EXISTS z INTEGER DEFAULT 0;

-- Metadatos flexibles por tipo (link: title/favicon, connector: fromId/toId/style)
ALTER TABLE board_elements
  ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}'::jsonb;

-- Bucket privado para las imagenes del pizarron
INSERT INTO storage.buckets (id, name, public)
VALUES ('board-media', 'board-media', false)
ON CONFLICT (id) DO NOTHING;

-- Policies del bucket (misma linea de la app: acceso total para la pareja)
DROP POLICY IF EXISTS "board_media_insert" ON storage.objects;
CREATE POLICY "board_media_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'board-media');

DROP POLICY IF EXISTS "board_media_read" ON storage.objects;
CREATE POLICY "board_media_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'board-media');

DROP POLICY IF EXISTS "board_media_delete" ON storage.objects;
CREATE POLICY "board_media_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'board-media');

DROP POLICY IF EXISTS "board_media_update" ON storage.objects;
CREATE POLICY "board_media_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'board-media');

-- Tableros (proyecto a proyecto). El id=1 es el tablero raiz "Pizarra".
CREATE TABLE IF NOT EXISTS boards (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'Pizarra',
  parent_id BIGINT REFERENCES boards(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO boards (id, name, parent_id)
VALUES (1, 'Pizarra', NULL)
ON CONFLICT (id) DO NOTHING;

-- Cada elemento pertenece a un tablero (default: el raiz)
ALTER TABLE board_elements
  ADD COLUMN IF NOT EXISTS board_id BIGINT NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_board_elements_board_id ON board_elements(board_id);

ALTER TABLE boards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "full_access_boards" ON boards;
CREATE POLICY "full_access_boards" ON boards FOR ALL USING (true);
GRANT ALL ON boards TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE boards_id_seq TO authenticated, service_role;