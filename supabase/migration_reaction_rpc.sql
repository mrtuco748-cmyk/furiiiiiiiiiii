-- ============================================================
-- Migración: RPCs de reacciones server-side (Fase 0)
-- ============================================================
-- Evita race condition "último write gana" en reacciones JSONB.
-- Antes cada provider enviaba el mapa reactions completo y el último
-- pisaba al anterior. Ahora el merge ocurre DENTRO del servidor con
-- row-level lock (SELECT ... FOR UPDATE).
--
-- FUENTE DE VERDAD: este archivo DEBE espejar supabase_schema.sql
-- (sección 29, RPC DE MERGE ATÓMICO DE REACCIONES). C1 resuelto:
-- `react_deck_card` opera sobre `deck_cards.reactions` (no la pizarra) y
-- `toggle_reaction` usa whitelist + updated_at + USING (parámetros, no %L).
-- Si cambiás una función acá, cambiala también en el schema maestro.
-- ============================================================

-- 1. Función toggle_reaction: forma {key:[uid]}, whitelist de tablas/columnas,
--    max 5 keys, toggle on/off (1 reacción por usuario, se quita de todas
--    las keys y se agrega/quita de la key objetivo).
--    Usa USANDO (parámetros $1/$2) para los valores, nunca %L (evita
--    interpolación literal y coincide con el schema maestro). Bump de
--    updated_at solo en las tablas workout (donde la columna existe).
DROP FUNCTION IF EXISTS toggle_reaction(text, text, bigint, text, text);
CREATE OR REPLACE FUNCTION public.toggle_reaction(
  target_table TEXT,
  target_col   TEXT,
  row_id       BIGINT,
  reaction_key TEXT,
  user_id      TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  doc     JSONB;
  base    JSONB;
  reac    JSONB;
  w       JSONB;
  k       TEXT;
  arr     JSONB;
  new_arr JSONB;
  already BOOLEAN;
  nkeys   INT;
BEGIN
  IF NOT (
        (target_table = 'messages'   AND target_col = 'reactions')
     OR (target_table = 'gallery'    AND target_col = 'reactions')
     OR (target_table = 'workout_logs'       AND target_col = 'social')
     OR (target_table = 'workout_routines'   AND target_col = 'social')
     OR (target_table = 'workout_challenges' AND target_col = 'social')
  ) THEN
    RAISE EXCEPTION 'tabla/columna no permitida: %.%', target_table, target_col;
  END IF;

  IF reaction_key IS NULL OR reaction_key = '' OR user_id IS NULL OR user_id = '' THEN
    RAISE EXCEPTION 'reaction_key y user_id son requeridos';
  END IF;

  EXECUTE format('SELECT %I FROM %I WHERE id = $1 FOR UPDATE', target_col, target_table)
    INTO doc USING row_id;
  IF doc IS NULL THEN
    RAISE EXCEPTION 'registro no encontrado: %', row_id;
  END IF;

  IF target_col IN ('social', 'data') THEN
    base := doc;
    reac := doc -> 'reactions';
  ELSE
    base := NULL;
    reac := doc;
  END IF;
  IF reac IS NULL OR jsonb_typeof(reac) != 'object' THEN
    reac := '{}'::jsonb;
  END IF;

  already := (reac -> reaction_key) IS NOT NULL
             AND EXISTS (
               SELECT 1 FROM jsonb_array_elements_text(reac -> reaction_key) AS e
               WHERE e = user_id
             );

  SELECT count(*)::int INTO nkeys FROM jsonb_object_keys(reac);
  IF NOT already AND NOT (reac ? reaction_key) AND nkeys >= 5 THEN
    RETURN reac;
  END IF;

  FOR k IN SELECT key FROM jsonb_object_keys(reac) AS key LOOP
    arr := reac -> k;
    IF jsonb_typeof(arr) = 'array' THEN
      new_arr := (
        SELECT COALESCE(jsonb_agg(e), '[]'::jsonb)
        FROM jsonb_array_elements_text(arr) AS e
        WHERE e <> user_id
      );
      IF jsonb_array_length(new_arr) = 0 THEN
        reac := reac - k;
      ELSE
        reac := jsonb_set(reac, ARRAY[k], new_arr);
      END IF;
    END IF;
  END LOOP;

  IF NOT already THEN
    reac := jsonb_set(reac, ARRAY[reaction_key],
      COALESCE(reac -> reaction_key, '[]'::jsonb) || to_jsonb(user_id));
  END IF;

  IF target_col IN ('social', 'data') THEN
    w := jsonb_set(base, ARRAY['reactions'], reac);
  ELSE
    w := reac;
  END IF;

  IF target_table IN ('workout_logs','workout_routines','workout_challenges') THEN
    EXECUTE format('UPDATE %I SET %I = $1, updated_at = NOW() WHERE id = $2', target_table, target_col) USING w, row_id;
  ELSE
    EXECUTE format('UPDATE %I SET %I = $1 WHERE id = $2', target_table, target_col) USING w, row_id;
  END IF;

  RETURN reac;
END;
$$;

-- 2. Función react_deck_card: forma {uid:emoji} del mazo (deck_cards.reactions)
DROP FUNCTION IF EXISTS react_deck_card(bigint, text, text);
CREATE OR REPLACE FUNCTION public.react_deck_card(
  row_id   BIGINT,
  user_id  TEXT,
  reaction TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  reac JSONB;
BEGIN
  IF user_id IS NULL OR user_id = '' OR reaction IS NULL OR reaction = '' THEN
    RAISE EXCEPTION 'user_id y reaction son requeridos';
  END IF;

  SELECT reactions INTO reac FROM deck_cards WHERE id = row_id FOR UPDATE;
  IF reac IS NULL OR jsonb_typeof(reac) != 'object' THEN reac := '{}'::jsonb; END IF;

  reac := jsonb_set(reac, ARRAY[user_id], to_jsonb(reaction));
  UPDATE deck_cards SET reactions = reac, updated_at = NOW() WHERE id = row_id;
  RETURN reac;
END;
$$;

-- 3. Otorgar permisos a roles anon y authenticated
GRANT EXECUTE ON FUNCTION public.toggle_reaction(TEXT, TEXT, BIGINT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.react_deck_card(BIGINT, TEXT, TEXT) TO anon, authenticated;

-- 4. Comentario explicativo
COMMENT ON FUNCTION public.toggle_reaction(TEXT, TEXT, BIGINT, TEXT, TEXT) IS 'Merge atómico de reacciones JSONB con row-level lock. Devuelve el mapa de reacciones actualizado (JSONB). Cubre messages.reactions, gallery.reactions y workout_*.social. Whitelist de tablas permitidas. Max 5 keys, 1 reacción por usuario por key.';
COMMENT ON FUNCTION public.react_deck_card(BIGINT, TEXT, TEXT) IS 'RPC dedicada para tarjetas del mazo (deck_cards.reactions): forma {uid:emoji}. Reemplazo atómico con updated_at. Devuelve el estado autoritativo.';
