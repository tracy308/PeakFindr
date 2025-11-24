-- Adds point tracking, leveling, and social chat room tables
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Ensure users have points and levels
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS points INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS level INTEGER NOT NULL DEFAULT 1;

-- Track how many points each visit granted
ALTER TABLE user_visits
    ADD COLUMN IF NOT EXISTS points_earned INTEGER NOT NULL DEFAULT 0;

-- Social chat rooms (category optional)
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Messages posted inside a chat room
CREATE TABLE IF NOT EXISTS chat_room_messages (
    id SERIAL PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_room_messages_room_id ON chat_room_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_room_messages_user_id ON chat_room_messages(user_id);
