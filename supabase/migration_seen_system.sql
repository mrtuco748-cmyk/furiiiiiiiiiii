-- Migracion "visto" (tipo WhatsApp) para retos y cartas
-- Cada registro guarda un array de user_id que ya lo vieron.
-- Ejecutar en SQL Editor de Supabase. Idempotente.

ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS seen_by JSONB DEFAULT '[]'::jsonb;

ALTER TABLE letters
  ADD COLUMN IF NOT EXISTS seen_by JSONB DEFAULT '[]'::jsonb;

ALTER TABLE letters
  ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false;
