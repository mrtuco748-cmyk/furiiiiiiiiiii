-- ============================================================================
-- F.U.R.I - Seed de secretos en Supabase Vault (para las funciones de push)
-- ============================================================================
-- Las funciones plpgsql notify_new_message() y furi_push() ya NO hardcodean la
-- URL ni la anon key: leen de Vault. Este archivo siembra esos secretos UNA
-- SOLA VEZ en el SQL Editor de Supabase.
--
-- ⚠️ REEMPLAZÁ los valores por los reales de tu proyecto (Dashboard > Settings
--    > API). La anon key de este `.sql` NO se commitea (0 secretos en el repo).
--
-- Requiere la extensión supabase_vault (en los proyectos de Supabase ya está
-- habilitada por defecto).
-- ============================================================================

-- 1. URL del proyecto Supabase (Dashboard > Settings > API > Project URL)
select vault.create_secret('https://nruyjpvoplkilcxqnees.supabase.co', 'SUPABASE_URL');

-- 2. Anon key publishable (Dashboard > Settings > API > anon public key)
--    Reemplazá 'TU_ANON_KEY_AQUI' por tu anon key real.
select vault.create_secret('TU_ANON_KEY_AQUI', 'SUPABASE_ANON_KEY');

-- ============================================================================
-- EDGE FUNCTION send-push (Deno) — secretos:
--   Se readen de scripts/.env + scripts/.env.firebase (gitignoreados) y se
--   setean + deployan con el helper local (sin CLI de supabase):
--     & .\scripts\deploy-send-push.ps1
--   ...que hace POST /v1/projects/{ref}/secrets (FIREBASE_SERVICE_ACCOUNT) y
--   POST /v1/projects/{ref}/functions/deploy?slug=send-push contra la
--   Management API. SUPABASE_URL / SUPABASE_ANON_KEY los inyecta Supabase solos.
--   Consulte supabase/functions/send-push/index.ts (lee todo de Deno.env).
-- ============================================================================
