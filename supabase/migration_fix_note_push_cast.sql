-- ============================================================================
-- Fix: cast ::text en notify_note_insert() para consistencia con el push FCM
-- ============================================================================
-- Antecedente: el master declaraba notes.user_id como UUID y el resto de tablas
-- como TEXT; el trigger notify_note_insert() (migration_push_categories) pasaba
-- NEW.user_id SIN ::text a furi_notify_partner(text,...). En prod notes.user_id
-- quedó TEXT (migration_notes_sync), así que hoy funciona; PERO si en el futuro
-- una DB se reconstruye desde el master con user_id UUID, el INSERT a notes
-- rompería con 42883 (el mismo bug que migration_fix_goal_challenge_push_cast
-- resolvió para goals/challenges). Este cast es de red de seguridad y el master
-- ya quedó alineado a TEXT (se quitó el pinned y el REFERENCES).
-- Idempotente: CREATE OR REPLACE. Pegar en SQL Editor de Supabase (opcional,
-- solo red de seguridad).
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_note_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.user_id::text, 'Nueva nota', left(NEW.content, 120), jsonb_build_object('type', 'note', 'id', NEW.id));
  RETURN NEW;
END;
$$;