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
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. QUESTION ANSWERS
CREATE TABLE IF NOT EXISTS question_answers (
  id BIGSERIAL PRIMARY KEY,
  question_id BIGINT REFERENCES daily_questions(id),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  answer TEXT NOT NULL,
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

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
  created_at TIMESTAMPTZ DEFAULT NOW()
);

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
  color INT DEFAULT 0xFF7B2D8E,
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
  color INTEGER DEFAULT 4286262670,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES for new tables
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
