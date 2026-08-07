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