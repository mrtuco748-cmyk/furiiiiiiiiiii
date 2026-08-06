-- Migracion chat: media + flags cloud + bucket storage + reply + reactions
-- Ejecutar en SQL Editor de Supabase
-- Idempotente: puede ejecutarse varias veces sin error (IF NOT EXISTS)

-- Columnas de reply (referencia a otro mensaje + preview del texto)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS reply_to_id BIGINT REFERENCES messages(id);

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS reply_content TEXT;

-- Tipo de mensaje (text, image, voice, video, gif, document)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text';

-- URL del adjunto en el bucket chat-media (se borra al descargar el receptor)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS attachment_url TEXT;

-- Metadatos del adjunto
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS attachment_name TEXT;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS attachment_mime TEXT;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS attachment_size BIGINT;

-- Flag de borrado cloud (delete-on-download)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS cloud_deleted BOOLEAN DEFAULT false;

-- Flags extra (starred / edited)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS starred BOOLEAN DEFAULT false;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS edited BOOLEAN DEFAULT false;

-- Reacciones: JSONB { "key": ["user-id-1", "user-id-2"], ... }  (max 5 keys)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb;

-- Timestamps de entrega y lectura (ticks de visto: simple/entregado/leído)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- Bucket privado para adjuntos del chat (delete-on-download)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-media',
  'chat-media',
  false,
  52428800,
  NULL
)
ON CONFLICT (id) DO NOTHING;

-- Policies abiertas (app privada Facu/Rocio sin auth real)
DROP POLICY IF EXISTS "chat_media_select" ON storage.objects;
DROP POLICY IF EXISTS "chat_media_insert" ON storage.objects;
DROP POLICY IF EXISTS "chat_media_update" ON storage.objects;
DROP POLICY IF EXISTS "chat_media_delete" ON storage.objects;

CREATE POLICY "chat_media_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'chat-media');

CREATE POLICY "chat_media_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'chat-media');

CREATE POLICY "chat_media_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'chat-media');

CREATE POLICY "chat_media_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'chat-media');
