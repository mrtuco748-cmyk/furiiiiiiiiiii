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
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE question_answers;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;