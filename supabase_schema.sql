-- EJECUTAR EN SQL EDITOR DE SUPABASE DASHBOARD

-- 1. PROFILES (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  partner_id UUID REFERENCES profiles(id),
  couple_code TEXT UNIQUE,
  partner_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. MESSAGES (chat) — estilo WhatsApp
CREATE TABLE IF NOT EXISTS messages (
  id BIGSERIAL PRIMARY KEY,
  from_user UUID REFERENCES profiles(id) NOT NULL,
  to_user UUID REFERENCES profiles(id) NOT NULL,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  reply_to_id BIGINT REFERENCES messages(id),
  reply_content TEXT,
  message_type TEXT DEFAULT 'text',  -- text, image, voice, video, gif, document
  attachment_url TEXT,
  attachment_name TEXT,
  attachment_mime TEXT,
  attachment_size BIGINT,
  cloud_deleted BOOLEAN DEFAULT false,
  starred BOOLEAN DEFAULT false,
  edited BOOLEAN DEFAULT false,
  reactions JSONB DEFAULT '{}'::jsonb,  -- {"🥰": ["user-id-1"], "xD": ["user-id-1", "user-id-2"]}
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. MOODS
CREATE TABLE IF NOT EXISTS moods (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  mood TEXT NOT NULL,
  note TEXT,
  date DATE DEFAULT CURRENT_DATE,
  UNIQUE(user_id, date),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. LETTERS
CREATE TABLE IF NOT EXISTS letters (
  id BIGSERIAL PRIMARY KEY,
  from_user UUID REFERENCES profiles(id) NOT NULL,
  to_user UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_opened BOOLEAN DEFAULT false,
  seen_by JSONB DEFAULT '[]'::jsonb,  -- array de user_id que ya lo vieron
  scheduled_open TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ANNIVERSARIES
CREATE TABLE IF NOT EXISTS anniversaries (
  id BIGSERIAL PRIMARY KEY,
  couple_id UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  date DATE NOT NULL,
  reminder_days_before INT DEFAULT 7,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. GOALS
CREATE TABLE IF NOT EXISTS goals (
  id BIGSERIAL PRIMARY KEY,
  couple_id UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  completed BOOLEAN DEFAULT false,
  completed_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. CHALLENGES
CREATE TABLE IF NOT EXISTS challenges (
  id BIGSERIAL PRIMARY KEY,
  couple_id UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  duration_days INT,
  current_day INT DEFAULT 0,
  started BOOLEAN DEFAULT false,
  completed BOOLEAN DEFAULT false,
  seen_by JSONB DEFAULT '[]'::jsonb,  -- array de user_id que ya lo vieron
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. DAILY QUESTIONS
CREATE TABLE IF NOT EXISTS daily_questions (
  id BIGSERIAL PRIMARY KEY,
  question TEXT NOT NULL,
  options JSONB,  -- opciones de opción múltiple (trivia de pareja)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. QUESTION ANSWERS
CREATE TABLE IF NOT EXISTS question_answers (
  id BIGSERIAL PRIMARY KEY,
  question_id BIGINT REFERENCES daily_questions(id),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  answer TEXT NOT NULL,
  guess TEXT,  -- predicción de la respuesta de la pareja (trivia)
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TriviaProvider.submit usa upsert onConflict 'user_id,date'; sin este índice
-- el ON CONFLICT en una DB nueva falla ("no unique or exclusion constraint...").
CREATE UNIQUE INDEX IF NOT EXISTS idx_question_answers_user_date
  ON question_answers(user_id, date);

-- 10. DEVICE TOKENS (FCM push notifications)
CREATE TABLE IF NOT EXISTS device_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

 -- 11. NOTIFICATIONS (in-app history)
 CREATE TABLE IF NOT EXISTS notifications (
   id BIGSERIAL PRIMARY KEY,
   user_id UUID REFERENCES profiles(id) NOT NULL,
   from_user UUID REFERENCES profiles(id),
   type TEXT NOT NULL,
   title TEXT NOT NULL,
   body TEXT NOT NULL,
   data JSONB DEFAULT '{}'::jsonb,
   read BOOLEAN DEFAULT false,
   created_at TIMESTAMPTZ DEFAULT NOW()
 );
 ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

 -- 12. COUPLE DATA (shared config)
CREATE TABLE IF NOT EXISTS couple_data (
  id BIGSERIAL PRIMARY KEY,
  couple_id UUID REFERENCES profiles(id) NOT NULL,
  start_date DATE,
  key TEXT NOT NULL,
  value JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. CUSTOM QUESTIONS (pareja se pregunta cosas)
CREATE TABLE IF NOT EXISTS custom_questions (
  id BIGSERIAL PRIMARY KEY,
  from_user UUID REFERENCES profiles(id) NOT NULL,
  to_user UUID REFERENCES profiles(id) NOT NULL,
  question TEXT NOT NULL,
  answer TEXT,
  answered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TRIGGER: send FCM push notification on new message (works when app is closed)
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  supa_anon TEXT := 'sb_publishable_JP4QgTreyVi-Mm3EYyiQtQ_YuvAxguu';
  sender_name TEXT;
BEGIN
  SELECT name INTO sender_name FROM profiles WHERE id = NEW.from_user;
  IF sender_name IS NULL THEN sender_name := 'Alguien'; END IF;

  PERFORM
    net.http_post(
      url := 'https://nruyjpvoplkilcxqnees.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', concat('Bearer ', supa_anon)
      ),
      body := jsonb_build_object(
        'user_id', NEW.to_user,
        'title', sender_name,
        'body', NEW.content,
        'data', jsonb_build_object('type', 'message')
      )
    );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_message_insert_send_push ON messages;
CREATE TRIGGER on_message_insert_send_push
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_message();

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_messages_participants ON messages(from_user, to_user);
-- Indice unico para device_tokens: evita duplicados (mismo token, dos filas)
-- y permite upsert limpio desde la app. La Edge Function send-push poda los
-- tokens UNREGISTERED (instalaciones viejas) que antes se acumulaban para
-- siempre y hacian que el push "no llegara".
CREATE UNIQUE INDEX IF NOT EXISTS idx_device_tokens_user_token
  ON device_tokens(user_id, token);
CREATE INDEX IF NOT EXISTS idx_messages_read ON messages(read) WHERE read = false;
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_letters_recipient ON letters(to_user, is_opened);
CREATE INDEX IF NOT EXISTS idx_moods_user_date ON moods(user_id, date);
CREATE INDEX IF NOT EXISTS idx_goals_couple ON goals(couple_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

-- RLS (Row Level Security) - enable on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE anniversaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_questions ENABLE ROW LEVEL SECURITY;

-- Policies: allow full access for now (simplified)
DO $$ BEGIN
  DROP POLICY IF EXISTS "full_access_profiles" ON profiles;
  DROP POLICY IF EXISTS "full_access_messages" ON messages;
  DROP POLICY IF EXISTS "full_access_moods" ON moods;
  DROP POLICY IF EXISTS "full_access_letters" ON letters;
  DROP POLICY IF EXISTS "full_access_anniversaries" ON anniversaries;
  DROP POLICY IF EXISTS "full_access_goals" ON goals;
  DROP POLICY IF EXISTS "full_access_challenges" ON challenges;
  DROP POLICY IF EXISTS "full_access_daily_questions" ON daily_questions;
  DROP POLICY IF EXISTS "full_access_question_answers" ON question_answers;
  DROP POLICY IF EXISTS "full_access_couple_data" ON couple_data;
  DROP POLICY IF EXISTS "full_access_device_tokens" ON device_tokens;
  DROP POLICY IF EXISTS "full_access_notifications" ON notifications;
  DROP POLICY IF EXISTS "full_access_custom_questions" ON custom_questions;
END $$;

CREATE POLICY "full_access_profiles" ON profiles FOR ALL USING (true);
CREATE POLICY "full_access_messages" ON messages FOR ALL USING (true);
CREATE POLICY "full_access_moods" ON moods FOR ALL USING (true);
CREATE POLICY "full_access_letters" ON letters FOR ALL USING (true);
CREATE POLICY "full_access_anniversaries" ON anniversaries FOR ALL USING (true);
CREATE POLICY "full_access_goals" ON goals FOR ALL USING (true);
CREATE POLICY "full_access_challenges" ON challenges FOR ALL USING (true);
CREATE POLICY "full_access_daily_questions" ON daily_questions FOR ALL USING (true);
CREATE POLICY "full_access_question_answers" ON question_answers FOR ALL USING (true);
CREATE POLICY "full_access_couple_data" ON couple_data FOR ALL USING (true);
CREATE POLICY "full_access_device_tokens" ON device_tokens FOR ALL USING (true);
CREATE POLICY "full_access_notifications" ON notifications FOR ALL USING (true);
CREATE POLICY "full_access_custom_questions" ON custom_questions FOR ALL USING (true);

-- 14. NOTES
CREATE TABLE IF NOT EXISTS notes (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL,
  content TEXT NOT NULL,
  color TEXT DEFAULT '#7000FF',
  pinned BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. TASKS
CREATE TABLE IF NOT EXISTS tasks (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  priority INT DEFAULT 1,
  "column" INT DEFAULT 1,
  created_by TEXT,
  assigned_to TEXT,
  shared BOOLEAN DEFAULT false,
  due_date TEXT,
  category TEXT,
  estimated_minutes INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. TRANSACTIONS
CREATE TABLE IF NOT EXISTS transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'expense',
  category TEXT NOT NULL DEFAULT 'other',
  amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  description TEXT,
  date TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17. FAVORITES
CREATE TABLE IF NOT EXISTS favorites (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  critica TEXT,
  emoji TEXT DEFAULT '⭐',
  rating_facu DOUBLE PRECISION DEFAULT 0,
  rating_rocio DOUBLE PRECISION DEFAULT 0,
  favorited BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18. BOARD ELEMENTS
CREATE TABLE IF NOT EXISTS board_elements (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'note',
  content TEXT DEFAULT '',
  x DOUBLE PRECISION DEFAULT 20,
  y DOUBLE PRECISION DEFAULT 20,
  width DOUBLE PRECISION DEFAULT 100,
  height DOUBLE PRECISION DEFAULT 80,
  rotation DOUBLE PRECISION DEFAULT 0,
  color TEXT,
  z INTEGER DEFAULT 0,
  data JSONB DEFAULT '{}'::jsonb,
  board_id BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_board_elements_board_id ON board_elements(board_id);

-- 18a. BOARD ELEMENTS V2 (espejo del schema SQLite local; el cloud_id es
--      columna solo-local de SQLite, no existe en la nube)
CREATE TABLE IF NOT EXISTS board_elements_v2 (
  id BIGSERIAL PRIMARY KEY,
  type TEXT NOT NULL DEFAULT 'note',
  title TEXT DEFAULT '',
  content TEXT DEFAULT '',
  x DOUBLE PRECISION NOT NULL DEFAULT 0,
  y DOUBLE PRECISION NOT NULL DEFAULT 0,
  width DOUBLE PRECISION,
  height DOUBLE PRECISION,
  rotation DOUBLE PRECISION NOT NULL DEFAULT 0,
  color TEXT,
  text_color TEXT,
  font_family TEXT,
  font_size DOUBLE PRECISION,
  text_align TEXT DEFAULT 'left',
  is_bold BOOLEAN NOT NULL DEFAULT false,
  is_italic BOOLEAN NOT NULL DEFAULT false,
  is_underline BOOLEAN NOT NULL DEFAULT false,
  emoji_header TEXT,
  tags JSONB DEFAULT '[]'::jsonb,
  priority TEXT DEFAULT 'normal',
  assigned_to TEXT,
  user_id TEXT DEFAULT '',
  status TEXT DEFAULT 'draft',
  is_collapsed BOOLEAN NOT NULL DEFAULT false,
  is_locked BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  board_id BIGINT NOT NULL DEFAULT 1,
  z INTEGER NOT NULL DEFAULT 0,
  data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_new BOOLEAN NOT NULL DEFAULT true,
  synced INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_board_elements_v2_board_id
  ON board_elements_v2(board_id);

ALTER TABLE board_elements_v2 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "full_access_board_elements_v2" ON board_elements_v2;
CREATE POLICY "full_access_board_elements_v2" ON board_elements_v2 FOR ALL USING (true);
GRANT ALL ON board_elements_v2 TO authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE board_elements_v2_id_seq TO authenticated, service_role;

-- 18b. BOARDS (tableros anidables, proyecto a proyecto)
CREATE TABLE IF NOT EXISTS boards (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'Pizarra',
  parent_id BIGINT REFERENCES boards(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE boards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "full_access_boards" ON boards;
CREATE POLICY "full_access_boards" ON boards FOR ALL USING (true);

-- 19. STUDY SESSIONS
CREATE TABLE IF NOT EXISTS study_sessions (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,
  duration_seconds INT NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20. GALLERY
CREATE TABLE IF NOT EXISTS gallery (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  url TEXT NOT NULL,
  thumbnail TEXT,
  type TEXT DEFAULT 'photo',
  album TEXT,
  label TEXT,
  description TEXT,
  reactions JSONB DEFAULT '{}'::jsonb,  -- {"key": ["user-id-1", ...]}
  rotation DOUBLE PRECISION DEFAULT 0,
  size DOUBLE PRECISION DEFAULT 1.0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20b. GALLERY COMMENTS (comentarios por foto)
CREATE TABLE IF NOT EXISTS gallery_comments (
  id BIGSERIAL PRIMARY KEY,
  gallery_id BIGINT NOT NULL REFERENCES gallery(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 21. TIMELINE EVENTS
CREATE TABLE IF NOT EXISTS timeline_events (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,
  emoji TEXT,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 22. SCHEDULES
CREATE TABLE IF NOT EXISTS schedules (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  date TEXT NOT NULL,
  startTime TEXT NOT NULL,
  endTime TEXT NOT NULL,
  location TEXT DEFAULT '',
  instructor TEXT DEFAULT '',
  type TEXT DEFAULT 'Clase',
  color BIGINT DEFAULT 4286262670,
  user_id TEXT DEFAULT '',
  createdAt TIMESTAMPTZ DEFAULT NOW(),
  updatedAt TIMESTAMPTZ DEFAULT NOW()
);

-- 23. CLASS SCHEDULES (clases recurrentes por dia de semana)
CREATE TABLE IF NOT EXISTS class_schedules (
  id BIGSERIAL PRIMARY KEY,
  day_of_week INTEGER NOT NULL,  -- convencion Dart: 1=lunes ... 7=domingo
  class_type_id BIGINT,
  start_time TEXT NOT NULL,
  title TEXT NOT NULL,
  end_time TEXT DEFAULT '',
  professor TEXT DEFAULT '',
  user_id TEXT DEFAULT '',
  color BIGINT DEFAULT 4286262670,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 24. DECK CARDS (mazo swipe tipo Tinder)
CREATE TABLE IF NOT EXISTS deck_cards (
  id BIGSERIAL PRIMARY KEY,
  category TEXT NOT NULL DEFAULT 'random',
  content TEXT NOT NULL,
  created_by TEXT NOT NULL DEFAULT '',
  reactions JSONB DEFAULT '{}'::jsonb,  -- {"<user_id>": "encanta"|"me_gusta"|"meh"|"no_me_gusta"}
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 24b. COUPLE ACHIEVEMENTS (logros de pareja que se desbloquean al cumplir hitos)
CREATE TABLE IF NOT EXISTS couple_achievements (
  id BIGSERIAL PRIMARY KEY,
  achievement_code TEXT NOT NULL UNIQUE,  -- código de la regla (ej: streak_7)
  awarded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 24c. COUPLE REWARDS + POINTS (cajita de deseos y puntos de pareja)
CREATE TABLE IF NOT EXISTS couple_rewards (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '🎁',
  cost INTEGER NOT NULL DEFAULT 10,
  fulfilled BOOLEAN NOT NULL DEFAULT false,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS couple_points (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  delta INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unicidad (user_id, reason): premisa del awardOnce idempotente (ON CONFLICT).
CREATE UNIQUE INDEX IF NOT EXISTS idx_couple_points_user_reason
  ON couple_points(user_id, reason);

-- 24d. COUPLE LOCATIONS (última ubicación de cada miembro → distancia realtime)
CREATE TABLE IF NOT EXISTS couple_locations (
  user_id TEXT PRIMARY KEY,
  lat DOUBLE PRECISION NOT NULL DEFAULT 0,
  lng DOUBLE PRECISION NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 25. WORKOUT LOGS (ejercicios registrados, sueltos o de rutina)
CREATE TABLE IF NOT EXISTS workout_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  exercise_name TEXT NOT NULL,
  muscle_group TEXT,
  series INT,
  reps INT,
  weight NUMERIC,
  rest_seconds INT,
  notes TEXT,
  routine_id BIGINT,
  logged_on DATE DEFAULT CURRENT_DATE,
  social JSONB DEFAULT '{}'::jsonb,  -- {"reactions": {"🔥": ["uuid"]}, "comments": [...]}
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 26. WORKOUT ROUTINES (rutinas con plan semanal por dia)
CREATE TABLE IF NOT EXISTS workout_routines (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  name TEXT NOT NULL,
  day_of_week INT,  -- 1=lunes ... 7=domingo, NULL = sin dia
  items JSONB DEFAULT '[]'::jsonb,  -- [{exerciseName, series, reps, weight, restSeconds, notes}]
  social JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 27. WORKOUT COMPLETIONS (cada persona marca su entrenamiento del dia)
CREATE TABLE IF NOT EXISTS workout_completions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  completed_on DATE DEFAULT CURRENT_DATE,
  -- NOT NULL para que la UNIQUE (user_id, completed_on, routine_id) funcione:
  -- en Postgres dos NULL en una columna UNIQUE se consideran DISTINTOS, así que
  -- con routine_id nullable el mismo día sin rutina podía duplicarse.
  routine_id BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, completed_on, routine_id)
);

-- Migración de filas existentes con routine_id NULL (backfill antes del NOT NULL).
UPDATE workout_completions SET routine_id = 0 WHERE routine_id IS NULL;
ALTER TABLE workout_completions ALTER COLUMN routine_id DROP DEFAULT;
ALTER TABLE workout_completions ALTER COLUMN routine_id SET NOT NULL;
ALTER TABLE workout_completions ALTER COLUMN routine_id SET DEFAULT 0;

-- 28. WORKOUT CHALLENGES (retos con aprobacion y completado conjuntos)
CREATE TABLE IF NOT EXISTS workout_challenges (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES profiles(id) NOT NULL,
  approved_by JSONB DEFAULT '[]'::jsonb,
  completed_by JSONB DEFAULT '[]'::jsonb,
  social JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES for new tables
CREATE INDEX IF NOT EXISTS idx_deck_cards_category ON deck_cards(category);
CREATE INDEX IF NOT EXISTS idx_deck_cards_created_at ON deck_cards(created_at);
CREATE INDEX IF NOT EXISTS idx_tasks_column ON tasks("column");
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_board_elements_user_id ON board_elements(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_type ON study_sessions(type);
CREATE INDEX IF NOT EXISTS idx_gallery_user_id ON gallery(user_id);
CREATE INDEX IF NOT EXISTS idx_timeline_events_user_id ON timeline_events(user_id);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON schedules(date);
CREATE INDEX IF NOT EXISTS idx_class_schedules_day ON class_schedules(day_of_week);
CREATE INDEX IF NOT EXISTS gallery_comments_gallery_id_idx ON gallery_comments(gallery_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_logged_on ON workout_logs(logged_on);
CREATE INDEX IF NOT EXISTS idx_workout_logs_name ON workout_logs(exercise_name);
CREATE INDEX IF NOT EXISTS idx_workout_routines_day ON workout_routines(day_of_week);
CREATE INDEX IF NOT EXISTS idx_workout_completions_on ON workout_completions(completed_on);
CREATE INDEX IF NOT EXISTS idx_couple_achievements_awarded ON couple_achievements(awarded_at DESC);
CREATE INDEX IF NOT EXISTS idx_couple_rewards_created ON couple_rewards(created_at);
CREATE INDEX IF NOT EXISTS idx_couple_points_user ON couple_points(user_id);

-- RLS for new tables
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_elements ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE couple_locations ENABLE ROW LEVEL SECURITY;

-- Policies for new tables
DO $$ BEGIN
  DROP POLICY IF EXISTS "full_access_tasks" ON tasks;
  DROP POLICY IF EXISTS "full_access_transactions" ON transactions;
  DROP POLICY IF EXISTS "full_access_favorites" ON favorites;
  DROP POLICY IF EXISTS "full_access_board_elements" ON board_elements;
  DROP POLICY IF EXISTS "full_access_study_sessions" ON study_sessions;
  DROP POLICY IF EXISTS "full_access_gallery" ON gallery;
  DROP POLICY IF EXISTS "full_access_gallery_comments" ON gallery_comments;
  DROP POLICY IF EXISTS "full_access_timeline_events" ON timeline_events;
  DROP POLICY IF EXISTS "full_access_schedules" ON schedules;
  DROP POLICY IF EXISTS "full_access_class_schedules" ON class_schedules;
  DROP POLICY IF EXISTS "full_access_deck_cards" ON deck_cards;
  DROP POLICY IF EXISTS "full_access_workout_logs" ON workout_logs;
  DROP POLICY IF EXISTS "full_access_workout_routines" ON workout_routines;
  DROP POLICY IF EXISTS "full_access_workout_completions" ON workout_completions;
  DROP POLICY IF EXISTS "full_access_workout_challenges" ON workout_challenges;
  DROP POLICY IF EXISTS "full_access_couple_achievements" ON couple_achievements;
  DROP POLICY IF EXISTS "full_access_couple_rewards" ON couple_rewards;
  DROP POLICY IF EXISTS "full_access_couple_points" ON couple_points;
  DROP POLICY IF EXISTS "full_access_couple_locations" ON couple_locations;
END $$;

CREATE POLICY "full_access_tasks" ON tasks FOR ALL USING (true);
CREATE POLICY "full_access_transactions" ON transactions FOR ALL USING (true);
CREATE POLICY "full_access_favorites" ON favorites FOR ALL USING (true);
CREATE POLICY "full_access_board_elements" ON board_elements FOR ALL USING (true);
CREATE POLICY "full_access_study_sessions" ON study_sessions FOR ALL USING (true);
CREATE POLICY "full_access_gallery" ON gallery FOR ALL USING (true);
CREATE POLICY "full_access_gallery_comments" ON gallery_comments FOR ALL USING (true);
CREATE POLICY "full_access_timeline_events" ON timeline_events FOR ALL USING (true);
CREATE POLICY "full_access_schedules" ON schedules FOR ALL USING (true);
CREATE POLICY "full_access_class_schedules" ON class_schedules FOR ALL USING (true);
CREATE POLICY "full_access_deck_cards" ON deck_cards FOR ALL USING (true);
CREATE POLICY "full_access_workout_logs" ON workout_logs FOR ALL USING (true);
CREATE POLICY "full_access_workout_routines" ON workout_routines FOR ALL USING (true);
CREATE POLICY "full_access_workout_completions" ON workout_completions FOR ALL USING (true);
CREATE POLICY "full_access_workout_challenges" ON workout_challenges FOR ALL USING (true);
CREATE POLICY "full_access_couple_achievements" ON couple_achievements FOR ALL USING (true);
CREATE POLICY "full_access_couple_rewards" ON couple_rewards FOR ALL USING (true);
CREATE POLICY "full_access_couple_points" ON couple_points FOR ALL USING (true);
CREATE POLICY "full_access_couple_locations" ON couple_locations FOR ALL USING (true);

-- 29. RPC DE MERGE ATÓMICO DE REACCIONES (Fase 0 — mismos orígenes que
--     supabase/migration_reaction_rpc.sql). Eliminan el race de "último write
--     gana" haciendo el merge dentro de Postgres con row-level lock.
--     29a. toggle_reaction: forma {key: [userIds]}, max 5 keys, toggle on/off.
--          Cubre messages.reactions, gallery.reactions, workout_*.social y
--          board_elements_v2.data.
--     29b. react_deck_card: forma {userId: emoji} (mazo), reemplazo atómico.
CREATE OR REPLACE FUNCTION public.toggle_reaction(
  target_table TEXT,
  target_col   TEXT,
  row_id       BIGINT,
  reaction_key TEXT,
  user_id      TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  doc     JSONB;
  base    JSONB;
  reac    JSONB;
  w       JSONB;
  k       TEXT;
  arr     JSONB;
  new_arr JSONB;
  already BOOLEAN;
  nkeys   INT;
BEGIN
  IF NOT (
        (target_table = 'messages'   AND target_col = 'reactions')
     OR (target_table = 'gallery'    AND target_col = 'reactions')
     OR (target_table = 'workout_logs'       AND target_col = 'social')
     OR (target_table = 'workout_routines'   AND target_col = 'social')
     OR (target_table = 'workout_challenges' AND target_col = 'social')
     OR (target_table = 'board_elements_v2'  AND target_col = 'data')
  ) THEN
    RAISE EXCEPTION 'tabla/columna no permitida: %.%', target_table, target_col;
  END IF;

  IF reaction_key IS NULL OR reaction_key = '' OR user_id IS NULL OR user_id = '' THEN
    RAISE EXCEPTION 'reaction_key y user_id son requeridos';
  END IF;

  EXECUTE format('SELECT %I FROM %I WHERE id = $1 FOR UPDATE', target_col, target_table)
    INTO doc USING row_id;
  IF doc IS NULL THEN
    RAISE EXCEPTION 'registro no encontrado: %', row_id;
  END IF;

  IF target_col IN ('social', 'data') THEN
    base := doc;
    reac := doc -> 'reactions';
  ELSE
    base := NULL;
    reac := doc;
  END IF;
  IF reac IS NULL OR jsonb_typeof(reac) != 'object' THEN
    reac := '{}'::jsonb;
  END IF;

  already := (reac -> reaction_key) IS NOT NULL
             AND EXISTS (
               SELECT 1 FROM jsonb_array_elements_text(reac -> reaction_key) AS e
               WHERE e = user_id
             );

  SELECT count(*)::int INTO nkeys FROM jsonb_object_keys(reac);
  IF NOT already AND NOT (reac ? reaction_key) AND nkeys >= 5 THEN
    RETURN reac;
  END IF;

  FOR k IN SELECT key FROM jsonb_object_keys(reac) AS key LOOP
    arr := reac -> k;
    IF jsonb_typeof(arr) = 'array' THEN
      new_arr := (
        SELECT COALESCE(jsonb_agg(e), '[]'::jsonb)
        FROM jsonb_array_elements_text(arr) AS e
        WHERE e <> user_id
      );
      IF jsonb_array_length(new_arr) = 0 THEN
        reac := reac - k;
      ELSE
        reac := jsonb_set(reac, ARRAY[k], new_arr);
      END IF;
    END IF;
  END LOOP;

  IF NOT already THEN
    reac := jsonb_set(reac, ARRAY[reaction_key],
      COALESCE(reac -> reaction_key, '[]'::jsonb) || to_jsonb(user_id));
  END IF;

  IF target_col IN ('social', 'data') THEN
    w := jsonb_set(base, ARRAY['reactions'], reac);
  ELSE
    w := reac;
  END IF;

  IF target_table IN ('workout_logs','workout_routines','workout_challenges','board_elements_v2') THEN
    EXECUTE format('UPDATE %I SET %I = $1, updated_at = NOW() WHERE id = $2', target_table, target_col) USING w, row_id;
  ELSE
    EXECUTE format('UPDATE %I SET %I = $1 WHERE id = $2', target_table, target_col) USING w, row_id;
  END IF;

  RETURN reac;
END;
$$;

CREATE OR REPLACE FUNCTION public.react_deck_card(
  row_id   BIGINT,
  user_id  TEXT,
  reaction TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  reac JSONB;
BEGIN
  IF user_id IS NULL OR user_id = '' OR reaction IS NULL OR reaction = '' THEN
    RAISE EXCEPTION 'user_id y reaction son requeridos';
  END IF;

  SELECT reactions INTO reac FROM deck_cards WHERE id = row_id FOR UPDATE;
  IF reac IS NULL OR jsonb_typeof(reac) != 'object' THEN reac := '{}'::jsonb; END IF;

  reac := jsonb_set(reac, ARRAY[user_id], to_jsonb(reaction));
  UPDATE deck_cards SET reactions = reac, updated_at = NOW() WHERE id = row_id;
  RETURN reac;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_reaction(TEXT, TEXT, BIGINT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.react_deck_card(BIGINT, TEXT, TEXT) TO anon, authenticated;
