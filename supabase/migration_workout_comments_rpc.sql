-- ============================================================
-- Migración (PROPUESTA): RPCs de comentarios server-side (Equipo 3)
-- ============================================================
-- Elimina la race condition "último write gana" de los comentarios en
-- workout_*.social. Antes cada comentario se enviaba con el documento
-- `social` completo (.update(next.toMap())) y dos comentarios simultáneos
-- se pisaban. Aquí el append/delete ocurre DENTRO del servidor con
-- row-level lock (SELECT ... FOR UPDATE), devolviendo el `social` completo
-- como estado autoritativo para reconciliar en el cliente.
--
-- PROPUESTA para el Equipo 1: integrar estas 2 funciones al schema maestro
-- (supabase_schema.sql, sección 29) con SECURITY INVOKER + whitelist de
-- tablas y GRANT a anon/authenticated (mismo patrón que toggle_reaction).
-- ============================================================

-- 1. add_workout_comment: agrega UN comentario a social->comments (atómico)
DROP FUNCTION IF EXISTS public.add_workout_comment(TEXT, BIGINT, JSONB);
CREATE OR REPLACE FUNCTION public.add_workout_comment(
  target_table TEXT,
  row_id       BIGINT,
  comment      JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  doc      JSONB;
  social   JSONB;
  comments JSONB;
  w        JSONB;
BEGIN
  IF target_table NOT IN ('workout_logs','workout_routines','workout_challenges') THEN
    RAISE EXCEPTION 'tabla no permitida: %', target_table;
  END IF;
  IF comment IS NULL OR jsonb_typeof(comment) != 'object' THEN
    RAISE EXCEPTION 'comment es un JSONB de objeto requerido';
  END IF;

  EXECUTE format('SELECT %I FROM %I WHERE id = $1 FOR UPDATE', 'social', target_table)
    INTO doc USING row_id;
  IF doc IS NULL THEN
    RAISE EXCEPTION 'registro no encontrado: %', row_id;
  END IF;

  social   := doc;
  comments := COALESCE(social -> 'comments', '[]'::jsonb);
  comments := comments || comment;
  w        := jsonb_set(social, ARRAY['comments'], comments);

  EXECUTE format('UPDATE %I SET social = $1, updated_at = NOW() WHERE id = $2', target_table)
    USING w, row_id;
  RETURN w;
END;
$$;

-- 2. delete_workout_comment: borra el comentario y sus respuestas en cascada
DROP FUNCTION IF EXISTS public.delete_workout_comment(TEXT, BIGINT, TEXT);
CREATE OR REPLACE FUNCTION public.delete_workout_comment(
  target_table TEXT,
  row_id       BIGINT,
  comment_id   TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  doc          JSONB;
  social       JSONB;
  comments     JSONB;
  new_comments JSONB;
  w            JSONB;
BEGIN
  IF target_table NOT IN ('workout_logs','workout_routines','workout_challenges') THEN
    RAISE EXCEPTION 'tabla no permitida: %', target_table;
  END IF;
  IF comment_id IS NULL OR comment_id = '' THEN
    RAISE EXCEPTION 'comment_id es requerido';
  END IF;

  EXECUTE format('SELECT %I FROM %I WHERE id = $1 FOR UPDATE', 'social', target_table)
    INTO doc USING row_id;
  IF doc IS NULL THEN
    RAISE EXCEPTION 'registro no encontrado: %', row_id;
  END IF;

  social := doc;
  comments := COALESCE(social -> 'comments', '[]'::jsonb);
  new_comments := (
    SELECT COALESCE(jsonb_agg(e), '[]'::jsonb)
    FROM jsonb_array_elements(comments) AS e
    WHERE (e ->> 'id') <> comment_id AND (e ->> 'replyToId') <> comment_id
  );
  w := jsonb_set(social, ARRAY['comments'], new_comments);

  EXECUTE format('UPDATE %I SET social = $1, updated_at = NOW() WHERE id = $2', target_table)
    USING w, row_id;
  RETURN w;
END;
$$;

-- 3. Otorgar permisos a roles anon y authenticated
GRANT EXECUTE ON FUNCTION public.add_workout_comment(TEXT, BIGINT, JSONB) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_workout_comment(TEXT, BIGINT, TEXT) TO anon, authenticated;

COMMENT ON FUNCTION public.add_workout_comment(TEXT, BIGINT, JSONB) IS 'Agrega un comentario a workout_*.social->comments con row-level lock de forma atómica. Devuelve el social completo. Whitelist de tablas.';
COMMENT ON FUNCTION public.delete_workout_comment(TEXT, BIGINT, TEXT) IS 'Borra un comentario (y sus respuestas en cascada) de workout_*.social con row-level lock. Devuelve el social completo.';