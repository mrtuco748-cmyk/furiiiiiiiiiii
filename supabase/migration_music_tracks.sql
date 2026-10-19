-- Migración para el Reproductor de Música Compartida de F.U.R.I.
-- Permite a Facu y Rocío buscar canciones en YouTube, descargarlas comprimidas
-- y guardarlas en la nube compartida con reproducción instantánea.

CREATE TABLE IF NOT EXISTS music_tracks (
  id BIGSERIAL PRIMARY KEY,
  youtube_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT DEFAULT '',
  duration_seconds INT DEFAULT 0,
  thumbnail_url TEXT DEFAULT '',
  audio_url TEXT DEFAULT '',
  added_by TEXT DEFAULT '',
  size_bytes BIGINT DEFAULT 0,
  is_favorite BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Publicar en Realtime para que la música añadida por uno aparezca en vivo en el otro
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE music_tracks;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;
