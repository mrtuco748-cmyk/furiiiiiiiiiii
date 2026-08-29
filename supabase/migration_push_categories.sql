-- ============================================================================
-- F.U.R.I - Push FCM para TODAS las categorías (adicional al bot de WhatsApp)
-- ============================================================================
-- Idempotente: DROP TRIGGER IF EXISTS + CREATE OR REPLACE FUNCTION.
-- Replica el patrón de notify_new_message() (pg_net -> /functions/v1/send-push)
-- pero para cartas, retos, eventos, clases, favoritos, emociones, metas,
-- notas, fotos, tareas, transacciones, timeline, mazo, custom_questions y
-- workout_*. El push va a la PAREJA del autor (resuelto vía profiles.partner_id).
--
-- Ejecutar en el SQL Editor de Supabase (no se puede deploy automático de DDL).
-- Requiere que la Edge Function send-push ya esté desplegada y que los
-- device_tokens se registren con el UUID de profiles (AppState.myId).
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

-- Anon key (publishable) inyectada como Bearer al invocar send-push.
-- Misma que usa notify_new_message().
DO $$
BEGIN
  -- no-op si ya existe la extensión
  NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Helper: enviar push a un UUID concreto (si no es null)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION furi_push(recipient uuid, title text, body text, data jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  supa_anon TEXT := 'sb_publishable_JP4QgTreyVi-Mm3EYyiQtQ_YuvAxguu';
BEGIN
  IF recipient IS NULL THEN
    RETURN;
  END IF;

  PERFORM
    net.http_post(
      url := 'https://nruyjpvoplkilcxqnees.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', concat('Bearer ', supa_anon)
      ),
      body := jsonb_build_object(
        'user_id', recipient,
        'title', coalesce(title, 'F.U.R.I'),
        'body', coalesce(body, ''),
        'data', coalesce(data, '{}'::jsonb)
      )
    );
END;
$$;

-- ---------------------------------------------------------------------------
-- Helper: resolver el UUID de la pareja a partir del autor.
-- El autor puede venir como UUID (user_id REFERENCES profiles) o como texto
-- identidad ('Facu'/'Rocio' == profiles.name). Soporta ambos.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION furi_resolve_partner(actor_any text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rid uuid;
BEGIN
  BEGIN
    -- ¿Es un UUID válido? -> buscar por profiles.id
    rid := (SELECT partner_id FROM profiles WHERE id = actor_any::uuid);
  EXCEPTION WHEN others THEN
    -- No es UUID -> tratar como nombre de identidad
    rid := (SELECT partner_id FROM profiles WHERE name = actor_any);
  END;
  RETURN rid;
END;
$$;

-- ---------------------------------------------------------------------------
-- Helper: notificar a la pareja del autor (UUID o texto identidad)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION furi_notify_partner(actor_any text, title text, body text, data jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM furi_push(furi_resolve_partner(actor_any), title, body, data);
END;
$$;

-- ---------------------------------------------------------------------------
-- Helper: notificar a AMBOS miembros de una pareja (couple_id apunta a uno)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION furi_notify_couple(cid uuid, title text, body text, data jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  p1 uuid := cid;
  p2 uuid := (SELECT partner_id FROM profiles WHERE id = cid);
BEGIN
  PERFORM furi_push(p1, title, body, data);
  PERFORM furi_push(p2, title, body, data);
END;
$$;

-- ---------------------------------------------------------------------------
-- Helper: notificar a TODOS los perfiles (app de 2 usuarios: logros, trivia)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION furi_notify_all(title text, body text, data jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM furi_push(id, title, body, data) FROM profiles;
END;
$$;

-- ===========================================================================
-- TRIGGERS POR CATEGORÍA
-- ===========================================================================

-- CARTAS: notificar al DESTINATARIO (to_user) directamente
CREATE OR REPLACE FUNCTION notify_letter_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  sender_name text;
BEGIN
  SELECT name INTO sender_name FROM profiles WHERE id = NEW.from_user;
  IF sender_name IS NULL THEN sender_name := 'Alguien'; END IF;
  PERFORM furi_push(NEW.to_user, sender_name, NEW.title, jsonb_build_object('type', 'letter', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_letter_insert_send_push ON letters;
CREATE TRIGGER on_letter_insert_send_push
  AFTER INSERT ON letters
  FOR EACH ROW EXECUTE FUNCTION notify_letter_insert();

-- EMOCIONES (moods): notificar a la pareja del autor
CREATE OR REPLACE FUNCTION notify_mood_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  who text;
BEGIN
  SELECT name INTO who FROM profiles WHERE id = NEW.user_id;
  PERFORM furi_notify_partner(NEW.user_id::text, who, 'registró una emoción', jsonb_build_object('type', 'mood', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_mood_insert_send_push ON moods;
CREATE TRIGGER on_mood_insert_send_push
  AFTER INSERT ON moods
  FOR EACH ROW EXECUTE FUNCTION notify_mood_insert();

-- METAS (goals): notificar a AMBOS de la pareja
CREATE OR REPLACE FUNCTION notify_goal_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_couple(NEW.couple_id, 'Nueva meta', NEW.title, jsonb_build_object('type', 'goal', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_goal_insert_send_push ON goals;
CREATE TRIGGER on_goal_insert_send_push
  AFTER INSERT ON goals
  FOR EACH ROW EXECUTE FUNCTION notify_goal_insert();

-- RETOS (challenges): notificar a AMBOS de la pareja
CREATE OR REPLACE FUNCTION notify_challenge_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_couple(NEW.couple_id, 'Nuevo reto', NEW.title, jsonb_build_object('type', 'challenge', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_challenge_insert_send_push ON challenges;
CREATE TRIGGER on_challenge_insert_send_push
  AFTER INSERT ON challenges
  FOR EACH ROW EXECUTE FUNCTION notify_challenge_insert();

-- CUSTOM QUESTIONS: notificar al DESTINATARIO (to_user)
CREATE OR REPLACE FUNCTION notify_custom_question_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  who text;
BEGIN
  SELECT name INTO who FROM profiles WHERE id = NEW.from_user;
  PERFORM furi_push(NEW.to_user, who, NEW.question, jsonb_build_object('type', 'custom_question', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_custom_question_insert_send_push ON custom_questions;
CREATE TRIGGER on_custom_question_insert_send_push
  AFTER INSERT ON custom_questions
  FOR EACH ROW EXECUTE FUNCTION notify_custom_question_insert();

-- NOTAS
CREATE OR REPLACE FUNCTION notify_note_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.user_id, 'Nueva nota', left(NEW.content, 120), jsonb_build_object('type', 'note', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_note_insert_send_push ON notes;
CREATE TRIGGER on_note_insert_send_push
  AFTER INSERT ON notes
  FOR EACH ROW EXECUTE FUNCTION notify_note_insert();

-- TAREAS (created_by puede ser UUID o texto identidad)
CREATE OR REPLACE FUNCTION notify_task_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.created_by, 'Nueva tarea', NEW.title, jsonb_build_object('type', 'task', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_task_insert_send_push ON tasks;
CREATE TRIGGER on_task_insert_send_push
  AFTER INSERT ON tasks
  FOR EACH ROW EXECUTE FUNCTION notify_task_insert();

-- TRANSACCIONES
CREATE OR REPLACE FUNCTION notify_transaction_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  lbl text := CASE WHEN NEW.type = 'income' THEN 'Nuevo ingreso' ELSE 'Nuevo gasto' END;
BEGIN
  PERFORM furi_notify_partner(NEW.user_id, lbl, coalesce(NEW.description, NEW.category), jsonb_build_object('type', 'transaction', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_transaction_insert_send_push ON transactions;
CREATE TRIGGER on_transaction_insert_send_push
  AFTER INSERT ON transactions
  FOR EACH ROW EXECUTE FUNCTION notify_transaction_insert();

-- FAVORITOS (pelis/juegos/etc.)
CREATE OR REPLACE FUNCTION notify_favorite_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.user_id, 'Nuevo favorito', NEW.title, jsonb_build_object('type', 'favorite', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_favorite_insert_send_push ON favorites;
CREATE TRIGGER on_favorite_insert_send_push
  AFTER INSERT ON favorites
  FOR EACH ROW EXECUTE FUNCTION notify_favorite_insert();

-- GALERÍA / FOTOS
CREATE OR REPLACE FUNCTION notify_gallery_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.user_id, 'Nueva foto', coalesce(NEW.label, NEW.description, 'en la galería'), jsonb_build_object('type', 'gallery', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_gallery_insert_send_push ON gallery;
CREATE TRIGGER on_gallery_insert_send_push
  AFTER INSERT ON gallery
  FOR EACH ROW EXECUTE FUNCTION notify_gallery_insert();

-- TIMELINE EVENTS
CREATE OR REPLACE FUNCTION notify_timeline_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.user_id, 'Nuevo evento', coalesce(NEW.content, NEW.type), jsonb_build_object('type', 'timeline', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_timeline_insert_send_push ON timeline_events;
CREATE TRIGGER on_timeline_insert_send_push
  AFTER INSERT ON timeline_events
  FOR EACH ROW EXECUTE FUNCTION notify_timeline_insert();

-- SCHEDULES (eventos)
CREATE OR REPLACE FUNCTION notify_schedule_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.user_id, 'Nuevo evento', NEW.title, jsonb_build_object('type', 'schedule', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_schedule_insert_send_push ON schedules;
CREATE TRIGGER on_schedule_insert_send_push
  AFTER INSERT ON schedules
  FOR EACH ROW EXECUTE FUNCTION notify_schedule_insert();

-- CLASS SCHEDULES (clases recurrentes)
CREATE OR REPLACE FUNCTION notify_class_schedule_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.user_id, 'Nueva clase', NEW.title, jsonb_build_object('type', 'class_schedule', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_class_schedule_insert_send_push ON class_schedules;
CREATE TRIGGER on_class_schedule_insert_send_push
  AFTER INSERT ON class_schedules
  FOR EACH ROW EXECUTE FUNCTION notify_class_schedule_insert();

-- DECK CARDS (mazo)
CREATE OR REPLACE FUNCTION notify_deck_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_partner(NEW.created_by, 'Nueva tarjeta', left(NEW.content, 120), jsonb_build_object('type', 'deck', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_deck_insert_send_push ON deck_cards;
CREATE TRIGGER on_deck_insert_send_push
  AFTER INSERT ON deck_cards
  FOR EACH ROW EXECUTE FUNCTION notify_deck_insert();

-- COUPLE ACHIEVEMENTS (logros): notificar a AMBOS
CREATE OR REPLACE FUNCTION notify_achievement_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM furi_notify_all('Logro desbloqueado', NEW.achievement_code, jsonb_build_object('type', 'achievement', 'code', NEW.achievement_code));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_achievement_insert_send_push ON couple_achievements;
CREATE TRIGGER on_achievement_insert_send_push
  AFTER INSERT ON couple_achievements
  FOR EACH ROW EXECUTE FUNCTION notify_achievement_insert();

-- WORKOUT LOGS
CREATE OR REPLACE FUNCTION notify_workout_log_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  who text;
BEGIN
  SELECT name INTO who FROM profiles WHERE id = NEW.user_id;
  PERFORM furi_notify_partner(NEW.user_id::text, who, 'entrenó: ' || NEW.exercise_name, jsonb_build_object('type', 'workout_log', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_workout_log_insert_send_push ON workout_logs;
CREATE TRIGGER on_workout_log_insert_send_push
  AFTER INSERT ON workout_logs
  FOR EACH ROW EXECUTE FUNCTION notify_workout_log_insert();

-- WORKOUT COMPLETIONS
CREATE OR REPLACE FUNCTION notify_workout_completion_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  who text;
BEGIN
  SELECT name INTO who FROM profiles WHERE id = NEW.user_id;
  PERFORM furi_notify_partner(NEW.user_id::text, who, 'completó su entrenamiento', jsonb_build_object('type', 'workout_completion', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_workout_completion_insert_send_push ON workout_completions;
CREATE TRIGGER on_workout_completion_insert_send_push
  AFTER INSERT ON workout_completions
  FOR EACH ROW EXECUTE FUNCTION notify_workout_completion_insert();

-- WORKOUT CHALLENGES
CREATE OR REPLACE FUNCTION notify_workout_challenge_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  who text;
BEGIN
  SELECT name INTO who FROM profiles WHERE id = NEW.created_by;
  PERFORM furi_notify_partner(NEW.created_by::text, who, 'nuevo reto de ejercicio: ' || NEW.title, jsonb_build_object('type', 'workout_challenge', 'id', NEW.id));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_workout_challenge_insert_send_push ON workout_challenges;
CREATE TRIGGER on_workout_challenge_insert_send_push
  AFTER INSERT ON workout_challenges
  FOR EACH ROW EXECUTE FUNCTION notify_workout_challenge_insert();
