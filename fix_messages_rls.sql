-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can insert messages into their chats" ON messages;

-- Policy: Users can view messages in chats they participate in
CREATE POLICY "Users can view messages in their chats"
ON messages
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM chats
    WHERE chats.id = messages.chat_id
    AND chats.participants @> ARRAY[auth.uid()]
  )
);

-- Policy: Users can insert messages into chats they participate in
CREATE POLICY "Users can insert messages into their chats"
ON messages
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM chats
    WHERE chats.id = messages.chat_id
    AND chats.participants @> ARRAY[auth.uid()]
  )
  AND sender_id = auth.uid()
);
