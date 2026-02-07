-- Enable RLS
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own chats" ON chats;
DROP POLICY IF EXISTS "Users can insert their own chats" ON chats;
DROP POLICY IF EXISTS "Users can update their own chats" ON chats;

-- Policy: Users can view chats they are a participant in
CREATE POLICY "Users can view their own chats"
ON chats
FOR SELECT
USING (
  participants @> ARRAY[auth.uid()]
);

-- Policy: Users can insert chats if they are a participant
CREATE POLICY "Users can insert their own chats"
ON chats
FOR INSERT
WITH CHECK (
  participants @> ARRAY[auth.uid()]
);

-- Policy: Users can update chats they are a participant in (e.g. updated_at)
CREATE POLICY "Users can update their own chats"
ON chats
FOR UPDATE
USING (
  participants @> ARRAY[auth.uid()]
);
