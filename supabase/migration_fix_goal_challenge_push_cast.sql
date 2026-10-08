-- ============================================================================
-- Fix: Push FCM de goals y challenges fallaba el INSERT (código 42883)
-- ============================================================================
-- causA: notify_goal_insert() y notify_challenge_insert() llamaban
--   furi_notify_partner(NEW.couple_id, ...) pasando couple_id como UUID,
--   pero la función espera text. PostgreSQL no hace cast implícito uuid->text
--   para resolver el overload -> "function furi_notify_partner(uuid,...) does
--   not exist" -> el trigger AFTER INSERT lanzaba y el INSERT a goals/challenges
--   fallaba ("no me deja agregar retos/metas").
-- Fix: cast NEW.couple_id::text (igual que moods/workout usan ::text).
-- Idempotente: CREATE OR REPLACE. Pegar en SQL Editor de Supabase.
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_goal_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.couple_id::text, 'Nueva meta', NEW.title, jsonb_build_object('type', 'goal', 'id', NEW.id));
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION notify_challenge_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.couple_id::text, 'Nuevo reto', NEW.title, jsonb_build_object('type', 'challenge', 'id', NEW.id));
  RETURN NEW;
END;
$$;
