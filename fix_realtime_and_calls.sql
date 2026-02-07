-- 1. Enable Realtime for Messaging
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    ) THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chats;

-- 2. Setup Calls Table correctly (if not already there or needs fix)
CREATE TABLE IF NOT EXISTS calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    caller_id UUID REFERENCES profiles(id),
    receiver_id UUID REFERENCES profiles(id),
    call_type TEXT CHECK (call_type IN ('audio', 'video')),
    status TEXT DEFAULT 'initiated',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS for calls
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for calls
DROP POLICY IF EXISTS "Users can view their own calls" ON calls;
DROP POLICY IF EXISTS "Users can initiate calls" ON calls;
DROP POLICY IF EXISTS "Users can update their own calls" ON calls;

-- Policy: Users can view calls they are part of
CREATE POLICY "Users can view their own calls"
ON calls
FOR SELECT
USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Policy: Users can initiate calls
CREATE POLICY "Users can initiate calls"
ON calls
FOR INSERT
WITH CHECK (auth.uid() = caller_id);

-- Policy: Users can update calls they are part of
CREATE POLICY "Users can update their own calls"
ON calls
FOR UPDATE
USING (auth.uid() = caller_id OR auth.uid() = receiver_id);
