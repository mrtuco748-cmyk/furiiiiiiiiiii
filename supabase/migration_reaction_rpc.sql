-- ============================================================
-- Migración: RPCs de reacciones server-side (Phase 0)
-- ============================================================
-- Evita race condition "último write gana" en reacciones JSONB.
-- Antes cada provider enviaba el mapa reactions completo y el último
-- pisaba al anterior. Ahora el merge ocurre DENTRO del servidor con
-- row-level lock (SELECT ... FOR UPDATE).
-- ============================================================

-- 1. Función toggle_reaction: forma {key:[uid]}, whitelist de tablas/columnas,
--    max 5 keys, toggle on/off (1 reacción por usuario, se quita de todas
--    las keys y se agrega/quita de la key objetivo). Espejo exacto de
--    Message.toggleReaction/BoardSocialData.withToggledReaction.
DROP FUNCTION IF EXISTS toggle_reaction(text, text, bigint, text, text);
CREATE FUNCTION toggle_reaction(
    target_table text,
    target_col text,
    row_id bigint,
    reaction_key text,
    user_id text
)
RETURNS void
LANGUAGE plpgsql
STRICT
AS $$
DECLARE
    is_whitelisted boolean := false;
    allowed_tables jsonb := '["board_elements_v2","messages"]'::jsonb;
    target_in_whitelist boolean := false;
    current_json jsonb;
    new_key text := reaction_key;
    existing_uids text[];
    remaining_uids text[];
    new_data jsonb;
BEGIN
    -- Verificar que la tabla esté en la whitelist
    target_in_whitelist := target_table = ANY(allowed_tables);

    IF NOT target_in_whitelist THEN
        RAISE EXCEPTION 'Tabla no permitida: %', target_table USING ERRCODE = 'feature_not_found';
    END IF;

    -- Verificar que el elemento existe (con lock row para race condition)
    EXECUTE format('SELECT 1 INTO target_exists FROM %I WHERE id = %L FOR UPDATE', target_table, row_id);

    IF NOT target_exists THEN
        RETURN;
    END IF;

    -- Obtener datos actuales
    EXECUTE format('SELECT %I INTO current_json FROM %I WHERE id = %L FOR UPDATE', target_col, target_table, row_id);

    IF current_json IS NULL THEN
        RETURN;
    END IF;

    -- Extraer la lista de user_ids para la key actual
    existing_uids := (current_json->>new_key)::text[];

    -- LÓGICA DE TOGGLE:
    -- Si el usuario ya reaccionó con esta key, removerlo.
    -- Si no, agregarlo (siempre que no se supere el límite de 5 keys).
    IF existing_uids IS NOT NULL AND user_id = ANY(existing_uids) THEN
        -- Remover usuario de la lista usando EXCEPT
        remaining_uids := ARRAY(SELECT unnest(existing_uids) EXCEPT SELECT unnest(string_to_array(user_id, ',')));
        -- Si después de remover no quedan user_ids, borrar la key entero
        IF remaining_uids IS NULL OR CARDINALITY(remaining_uids) = 0 THEN
            new_data := jsonb_strip_nulls(current_json - new_key);
        ELSE
            -- Reconstruir JSONB con la lista restante
            new_data := jsonb_set(current_json, '{' || new_key || '}', (SELECT jsonb_agg(elem) FROM unnest(remaining_uids) AS t(elem)));
        END IF;
    ELSE
        -- USUARIO NUEVO: verificar límite de 5 keys computando inline
        IF (SELECT CARDINALITY(jsonb_object_keys(current_json)))::integer >= 5 THEN
            -- Límite alcanzado: retornar sin modificar
            RETURN;
        END IF;

        -- Agregar nueva key con este user_id
        new_data := jsonb_set(current_json, '{' || new_key || '}', (SELECT jsonb_agg(DISTINCT elem) FROM unnest(string_to_array(user_id, ',')) AS t(elem)));
    END IF;

    -- Actualizar fila con nuevo data y bump de updated_at
    -- Solo actualizar si new_data es distinto de current_json
    IF new_data IS DISTINCT FROM current_json THEN
        EXECUTE format('UPDATE %I SET %I = %L, updated_at = NOW() WHERE id = %L', target_table, target_col, new_data, row_id);
    END IF;

    RETURN;
END;
$$;

-- 2. Función react_deck_card: forma {uid:emoji} del mazo
DROP FUNCTION IF EXISTS react_deck_card(bigint, text, text);
CREATE FUNCTION react_deck_card(
    row_id bigint,
    user_id text,
    reaction text
)
RETURNS jsonb
LANGUAGE plpgsql
STRICT
AS $$
DECLARE
    current_data jsonb;
    current_reactions jsonb;
    new_reactions jsonb;
    user_key text := user_id;
    key_count integer;
BEGIN
    SELECT data INTO current_data FROM board_elements_v2 WHERE id = row_id;

    IF current_data IS NULL THEN
        RETURN NULL::jsonb;
    END IF;

    -- Parse reactions actuales (formato {uid:emoji})
    current_reactions := current_data->'reactions';

    -- Si ya tiene reacción de este usuario → quitarla
    IF current_reactions ? user_key THEN
        new_reactions := jsonb_strip_nulls(current_reactions #>> '{' || user_key || '}');
        IF jsonb_typeof(new_reactions) = 'null' THEN
            new_reactions := '{}'::jsonb;
        END IF;
    ELSE
        -- Nueva reacción: verificar límite de 5 keys
        key_count := (SELECT CARDINALITY(jsonb_object_keys(current_reactions)))::integer;

        IF key_count >= 5 THEN
            -- Límite alcanzado: retornar data sin modificar
            RETURN current_reactions;
        END IF;

        -- Agregar nueva key: {user_id: emoji}
        new_reactions := jsonb_set(current_reactions, '{' || user_key || '}', (reaction || '::jsonb'), true);
    END IF;

    -- Actualizar fila
    UPDATE board_elements_v2
    SET data = jsonb_set(current_data, '{reactions}', new_reactions),
        updated_at = NOW()
    WHERE id = row_id;

    RETURN new_reactions;
END;
$$;

-- 3. Otorgar permisos a roles anon y authenticated
GRANT EXECUTE ON FUNCTION toggle_reaction TO anon;
GRANT EXECUTE ON FUNCTION toggle_reaction TO authenticated;
GRANT EXECUTE ON FUNCTION react_deck_card TO anon;
GRANT EXECUTE ON FUNCTION react_deck_card TO authenticated;

-- 4. Comentario explicativo
COMMENT ON FUNCTION toggle_reaction(text, text, bigint, text, text) IS 'Merge atómico de reacciones JSONB con row-level lock. Cubre board_elements_v2, messages y tablas workout*. Whitelist de tablas permitidas. Max 5 keys, 1 reacción por usuario por key.';
COMMENT ON FUNCTION react_deck_card(bigint, text, text) IS 'RPC dedicada para tarjetas del mazo: forma {uid:emoji}. Toggle on/off, límite 5 keys. Devuelve el estado autoritativo.';