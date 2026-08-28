-- MERGE ATÓMICO DE REACCIONES EN EL SERVIDOR (Fase 0 del roadmap).
--
-- Propósito: eliminar la race condition de "último write gana" que hoy ocurre
-- porque cada provider envía el mapa completo de reacciones en cada update.
-- Dos reacciones simultáneas (Facu y Rocio) al mismo ítem pisaban la del otro
-- (BUG 2 CRÍTICO de la auditoría del pizarrón).
--
-- Se agregan 2 RPC que hacen el merge DENTRO de Postgres con row-level lock:
--   * toggle_reaction(...)  → forma {key: [userIds]}, max 5 keys, toggle on/off.
--     Cubre messages.reactions, gallery.reactions, workout_*.social y
--     board_elements_v2.data (reacciones anidadas en el documento).
--   * react_deck_card(...)  → forma {userId: emoji} (mazo). Reemplaza la
--     reacción propia de forma atómica.
--
-- IDEMPOTENTE: usa CREATE OR REPLACE + GRANT. Ejecutar en SQL Editor.

-- ────────────────────────────────────────────────────────────────────────────
-- 1. toggle_reaction — forma A: `{key: [userId, ...]}`
-- ────────────────────────────────────────────────────────────────────────────
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
  -- 0) Guard: columna/palabra de tabla permitida (evita SQL injection en
  --    identifiadores dinámicos). Solo las tablas de reacciones conocidas.
  IF NOT (
        (target_table = 'messages'   AND target_col = 'reactions')
     OR (target_table = 'gallery'    AND target_col = 'reactions')
     OR (target_table = 'workout_logs'       AND target_col = 'social')
     OR (target_table = 'workout_routines'   AND target_col = 'social')
     OR (target_table = 'workout_challenges' AND target_col = 'social')
     OR (target_table = 'board_elements_v2'  AND target_col = 'data')
  ) THEN
    RAISE EXCEPTION 'tabla/columna no permitida: %.%', target_table, target_col;
  END IF;

  IF reaction_key IS NULL OR reaction_key = '' OR user_id IS NULL OR user_id = '' THEN
    RAISE EXCEPTION 'reaction_key y user_id son requeridos';
  END IF;

  -- 1) Row-level lock: serializa reacciones concurrentes a la misma fila.
  EXECUTE format('SELECT %I FROM %I WHERE id = $1 FOR UPDATE', target_col, target_table)
    INTO doc USING row_id;
  IF doc IS NULL THEN
    RAISE EXCEPTION 'registro no encontrado: %', row_id;
  END IF;

  -- 2) Extraer el mapa de reacciones (anidado para social/data).
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

-- 3) ¿El usuario ya estaba en la key objetivo?
  already := (reac -> reaction_key) IS NOT NULL
             AND EXISTS (
               SELECT 1
               FROM jsonb_array_elements_text(reac -> reaction_key) AS e
               WHERE e = user_id
             );

  -- 4) Límite de 5 keys (solo aplica al AGREGAR una key nueva, no al togglée
  --     off). Se chequea ANTES de mutar: el resultado debe ser el estado
  --     original intacto (igual que Message.toggleReaction devuelve `this`).
  SELECT count(*)::int INTO nkeys FROM jsonb_object_keys(reac);
  IF NOT already AND NOT (reac ? reaction_key) AND nkeys >= 5 THEN
    RETURN reac;
  END IF;

  -- 5) Quitar al usuario de TODAS las keys (1 reacción por usuario).
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

  -- 6) Toggle ON si el usuario NO estaba en la key objetivo.
  IF NOT already THEN
    reac := jsonb_set(
      reac,
      ARRAY[reaction_key],
      COALESCE(reac -> reaction_key, '[]'::jsonb) || to_jsonb(user_id)
    );
  END IF;

  -- 7) Persistir (bump updated_at solo donde la columna existe).
  IF target_col IN ('social', 'data') THEN
    w := jsonb_set(base, ARRAY['reactions'], reac);
  ELSE
    w := reac;
  END IF;

  IF target_table IN ('workout_logs','workout_routines','workout_challenges','board_elements_v2') THEN
    EXECUTE format('UPDATE %I SET %I = $1, updated_at = NOW() WHERE id = $2', target_table, target_col)
      USING w, row_id;
  ELSE
    EXECUTE format('UPDATE %I SET %I = $1 WHERE id = $2', target_table, target_col)
      USING w, row_id;
  END IF;

  RETURN reac;
END;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 2. react_deck_card — forma B: `{userId: emoji}` (mazo tipo Tinder)
-- ────────────────────────────────────────────────────────────────────────────
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
  IF reac IS NULL OR jsonb_typeof(reac) != 'object' THEN
    reac := '{}'::jsonb;
  END IF;

  reac := jsonb_set(reac, ARRAY[user_id], to_jsonb(reaction));

  UPDATE deck_cards SET reactions = reac, updated_at = NOW() WHERE id = row_id;

  RETURN reac;
END;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- PERMISOS (la app usa la publishable/anon key)
-- ────────────────────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.toggle_reaction(TEXT, TEXT, BIGINT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.react_deck_card(BIGINT, TEXT, TEXT) TO anon, authenticated;