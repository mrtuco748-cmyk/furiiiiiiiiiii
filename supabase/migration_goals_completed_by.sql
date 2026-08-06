-- Migracion metas: quien completo la meta (Facu o Rocio)
-- Ejecutar en SQL Editor de Supabase
-- Idempotente

ALTER TABLE goals
  ADD COLUMN IF NOT EXISTS completed_by TEXT;
