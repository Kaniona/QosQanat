-- QosQanat Database Schema

-- Students table
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  grade INTEGER CHECK (grade >= 5 AND grade <= 11),
  school VARCHAR(200),
  email VARCHAR(100),
  preferred_assistant VARCHAR(20) DEFAULT 'bektur',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_active TIMESTAMP,
  total_questions INTEGER DEFAULT 0
);

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject VARCHAR(100),
  topic VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Messages table (conversation history)
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  role VARCHAR(20) CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  assistant_type VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Feedback table (for improvements)
CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id),
  message_id UUID REFERENCES messages(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Activity logs table
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id),
  action VARCHAR(100),
  details JSONB,
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_conversations_student_id ON conversations(student_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_feedback_student_id ON feedback(student_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_student_id ON activity_logs(student_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO qosqanat;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO qosqanat;

-- Sample data
INSERT INTO students (name, grade, school, email, preferred_assistant) VALUES
  ('Айбек', 8, 'Нурсултан Назарбаев атындағы мектеп', 'aibek@example.com', 'bektur'),
  ('Сана', 9, 'Төле Би мектебі', 'sana@example.com', 'nazym'),
  ('Марат', 7, 'Абай мектебі', 'marat@example.com', 'bektur')
ON CONFLICT DO NOTHING;
