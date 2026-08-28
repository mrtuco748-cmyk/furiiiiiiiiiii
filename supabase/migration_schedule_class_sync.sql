-- Fix de sync de calendario para ambos usuarios:
-- los eventos (schedules) y las clases (class_schedules) deben poder leerse
-- por ambos (RLS full access) y publicarse por realtime para que se reflejen
-- al instante en el otro dispositivo. Idempotente.

DROP POLICY IF EXISTS "full_access_schedules" ON schedules;
DROP POLICY IF EXISTS "full_access_class_schedules" ON class_schedules;

ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "full_access_schedules" ON schedules
  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "full_access_class_schedules" ON class_schedules
  FOR ALL USING (true) WITH CHECK (true);

GRANT ALL ON TABLE schedules TO anon;
GRANT ALL ON TABLE schedules TO authenticated;
GRANT ALL ON TABLE class_schedules TO anon;
GRANT ALL ON TABLE class_schedules TO authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE schedules;
ALTER PUBLICATION supabase_realtime ADD TABLE class_schedules;