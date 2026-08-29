-- ============================================================================
-- F.U.R.I - Bot WhatsApp en tiempo real (Opción 1)
-- Dispara GitHub Actions segundos después de cada INSERT vía pg_net
-- ============================================================================
-- Requiere: CREATE EXTENSION pg_net (ya existe por push FCM)
-- El PAT de GitHub se guarda en Vault (vault.secrets) con nombre github_bot_pat
-- Ver docs/contexto/bot-whatsapp.md para setup.
-- Idempotente.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

-- Función genérica: dispara workflow_dispatch via GitHub API
-- Lee el PAT desde vault.secrets (si no existe, hace no-op y loguea)
CREATE OR REPLACE FUNCTION furi_trigger_bot()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  pat text;
BEGIN
  -- Intentar leer PAT desde vault (Supabase Vault)
  BEGIN
    SELECT decrypted_secret INTO pat FROM vault.decrypted_secrets WHERE name = 'github_bot_pat' LIMIT 1;
  EXCEPTION WHEN others THEN
    pat := NULL;
  END;

  IF pat IS NULL OR pat = '' THEN
    -- Sin PAT no se puede disparar, no bloquear el INSERT
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := 'https://api.github.com/repos/mrtuco748-cmyk/furiiiiiiiiiii/actions/workflows/bot-whatsapp.yml/dispatches',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Accept', 'application/vnd.github+json',
      'Authorization', concat('Bearer ', pat),
      'X-GitHub-Api-Version', '2022-11-28'
    ),
    body := jsonb_build_object('ref', 'main')
  );
  RETURN NEW;
EXCEPTION WHEN others THEN
  -- Nunca bloquear el INSERT del usuario por fallo del webhook
  RETURN NEW;
END;
$$;

-- Helper para crear trigger idempotente
-- Tablas que deben disparar el bot (22 categorías + trivia)
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'moods','letters','challenges','goals','tasks','transactions',
    'favorites','notes','gallery','timeline_events','custom_questions',
    'deck_cards','workout_logs','workout_completions','workout_challenges',
    'couple_achievements','question_answers','schedules','class_schedules',
    'anniversaries'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_furi_bot_dispatch ON %I', t);
    EXECUTE format('CREATE TRIGGER trg_furi_bot_dispatch AFTER INSERT ON %I FOR EACH ROW EXECUTE FUNCTION furi_trigger_bot()', t);
  END LOOP;
END;
$$;
