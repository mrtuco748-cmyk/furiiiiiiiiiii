-- chat_typing: indicador "escribiendo..." del chat (una fila por usuario).
CREATE TABLE IF NOT EXISTS chat_typing (
  user_id TEXT PRIMARY KEY,
  is_typing BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE chat_typing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "full_access_chat_typing" ON chat_typing;
CREATE POLICY "full_access_chat_typing" ON chat_typing
  FOR ALL USING (true) WITH CHECK (true);

GRANT ALL ON TABLE chat_typing TO anon;
GRANT ALL ON TABLE chat_typing TO authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE chat_typing;