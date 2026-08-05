-- EJECUTAR EN SQL EDITOR DE SUPABASE DASHBOARD
-- Agrega las tablas que necesita el bot de WhatsApp

-- 1. Almacenar sesion de WhatsApp para persistir entre ejecuciones
CREATE TABLE IF NOT EXISTS bot_sessions (
  id INTEGER PRIMARY KEY DEFAULT 1,
  session_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tracking de notificaciones enviadas (evita duplicados)
CREATE TABLE IF NOT EXISTS bot_notificaciones (
  id BIGSERIAL PRIMARY KEY,
  tabla TEXT NOT NULL,
  registro_id TEXT NOT NULL,
  tipo TEXT NOT NULL,
  phone TEXT NOT NULL,
  mensaje TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index para busquedas rapidas
CREATE INDEX IF NOT EXISTS idx_bot_notif_tabla_registro
  ON bot_notificaciones(tabla, registro_id);

-- RLS
ALTER TABLE bot_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bot_notificaciones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "full_access_bot_sessions" ON bot_sessions FOR ALL USING (true);
CREATE POLICY "full_access_bot_notificaciones" ON bot_notificaciones FOR ALL USING (true);
