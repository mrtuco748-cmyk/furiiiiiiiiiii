-- device_tokens: dedupe + limpieza
-- Causa raiz del "push no llega": la tabla acumulaba tokens de instalaciones
-- viejas (FCM responde UNREGISTERED) y nunca se podaban. La Edge Function
-- send-push ahora poda automaticamente los tokens UNREGISTERED; esta migracion
-- evita ademas filas duplicadas del mismo token (mismo dispositivo, dos
-- identidades o reintentos) con un indice unico (user_id, token).
-- IDEMPOTENTE: puede ejecutarse varias veces.

-- 1. Limpiar duplicados (user_id, token) conservando el mas reciente
DELETE FROM device_tokens a
USING device_tokens b
WHERE a.user_id = b.user_id
  AND a.token = b.token
  AND a.id < b.id;

-- 2. Indice unico para que _storeToken pueda usar upsert y no duplique
CREATE UNIQUE INDEX IF NOT EXISTS idx_device_tokens_user_token
  ON device_tokens(user_id, token);
