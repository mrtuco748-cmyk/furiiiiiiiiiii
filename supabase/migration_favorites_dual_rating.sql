-- Migracion: Rating dual + critica compartida en favorites
-- Fecha: 2026-08-05
-- Proposito: permitir que Facu y Rocio califiquen cada favorito
-- de forma independiente, y agregar critica de texto compartida.
--
-- Ejecutar una sola vez en Supabase SQL Editor.
-- Es idempotente: usa IF NOT EXISTS y宽容 si las columnas ya existen.

-- 1. Agregar nuevas columnas
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS rating_facu DOUBLE PRECISION DEFAULT 0;
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS rating_rocio DOUBLE PRECISION DEFAULT 0;
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS critica TEXT;

-- 2. Migrar datos legacy:
--    - subtitle -> critica
--    - rating -> rating_facu (conserva el rating viejo, se asigna al campo de Facu por defecto)
UPDATE favorites SET critica = subtitle WHERE critica IS NULL AND subtitle IS NOT NULL;
UPDATE favorites SET rating_facu = rating WHERE rating_facu = 0 AND rating IS NOT NULL AND rating > 0;

-- 3. Eliminar columnas viejas (opcional pero recomendado para mantener esquema limpio)
ALTER TABLE favorites DROP COLUMN IF EXISTS subtitle;
ALTER TABLE favorites DROP COLUMN IF EXISTS rating;