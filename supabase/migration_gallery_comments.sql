-- Migracion galería: descripcion + reacciones al texto + comentarios por foto
-- Ejecutar en SQL Editor de Supabase
-- Idempotente: puede ejecutarse varias veces sin error (IF NOT EXISTS)

-- Descripcion de la foto (texto compartido, reemplaza el uso posivo del label)
ALTER TABLE gallery
  ADD COLUMN IF NOT EXISTS description TEXT;

-- Reacciones al texto/descripcion: JSONB { "key": ["user-id-1", "user-id-2"], ... }
ALTER TABLE gallery
  ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb;

-- Comentarios por foto
CREATE TABLE IF NOT EXISTS gallery_comments (
  id BIGSERIAL PRIMARY KEY,
  gallery_id BIGINT NOT NULL REFERENCES gallery(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS gallery_comments_gallery_id_idx
  ON gallery_comments (gallery_id);