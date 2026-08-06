-- Migracion: Rating dual + critica compartida en favorites
-- Fecha: 2026-08-05
-- Proposito: permitir que Facu y Rocio califiquen cada favorito
-- de forma independiente, y agregar critica de texto compartida.
--
-- Ejecutar una sola vez en Supabase SQL Editor.
-- Es idempotente: usa IF NOT EXISTS y PL/pgSQL condicional,
-- por lo que tolera que las columnas legacy (subtitle/rating)
-- existan o no.

-- 1. Agregar nuevas columnas (idempotente)
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS rating_facu DOUBLE PRECISION DEFAULT 0;
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS rating_rocio DOUBLE PRECISION DEFAULT 0;
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS critica TEXT;

-- 2. Migrar datos legacy de forma condicional.
--    PostgreSQL compila cada UPDATE al vuelo, asi que no se puede
--    referenciar una columna inexistente aunque haya un DROP despues.
--    Se consulta information_schema para actuar solo si la columna existe.
DO $$
BEGIN
  -- subtitle -> critica (solo si subtitle existe)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema() AND table_name = 'favorites'
      AND column_name = 'subtitle'
  ) THEN
    EXECUTE 'UPDATE favorites SET critica = subtitle
             WHERE critica IS NULL AND subtitle IS NOT NULL';
    EXECUTE 'ALTER TABLE favorites DROP COLUMN subtitle';
  END IF;

  -- rating -> rating_facu (conserva el rating viejo en el campo de Facu)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema() AND table_name = 'favorites'
      AND column_name = 'rating'
  ) THEN
    EXECUTE 'UPDATE favorites SET rating_facu = rating
             WHERE rating_facu = 0 AND rating IS NOT NULL AND rating > 0';
    EXECUTE 'ALTER TABLE favorites DROP COLUMN rating';
  END IF;
END $$;
