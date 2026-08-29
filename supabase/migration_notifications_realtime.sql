-- ============================================================================
-- F.U.R.I - Agregar tabla notifications a supabase_realtime
-- ============================================================================
-- Permite que el panel de notificaciones se actualice en tiempo real
-- cuando se inserta una nueva fila en la tabla notifications.
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  END IF;
END $$;

-- Asegurar RLS y policies estén activos (idempotente)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "full_access_notifications" ON notifications;
END $$;
CREATE POLICY "full_access_notifications" ON notifications FOR ALL USING (true);

GRANT ALL ON notifications TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO authenticated, service_role;