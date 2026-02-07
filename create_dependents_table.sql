-- Create dependents table
CREATE TABLE IF NOT EXISTS public.dependents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    relationship TEXT,
    gender TEXT,
    dob DATE,
    phone TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.dependents ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own dependents"
    ON public.dependents FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own dependents"
    ON public.dependents FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own dependents"
    ON public.dependents FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own dependents"
    ON public.dependents FOR DELETE
    USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_dependents_updated_at
    BEFORE UPDATE ON public.dependents
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();
