-- Trivia de pareja (Fase 3.1): pregunta del día con opciones + predicciones.
-- Reusa daily_questions y question_answers (hasta ahora vacías). Idempotente.

ALTER TABLE daily_questions ADD COLUMN IF NOT EXISTS options JSONB;

ALTER TABLE question_answers ADD COLUMN IF NOT EXISTS guess TEXT;

CREATE INDEX IF NOT EXISTS idx_question_answers_question
  ON question_answers (question_id);
CREATE INDEX IF NOT EXISTS idx_question_answers_date
  ON question_answers (date);

-- Una respuesta por usuario por día: permite upsert atómico (submit idempotente
-- en vez de delete-then-insert, que podía perder la respuesta si el insert fallaba).
CREATE UNIQUE INDEX IF NOT EXISTS idx_question_answers_user_date
  ON question_answers (user_id, date);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'question_answers'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE question_answers;
  END IF;
END $$;