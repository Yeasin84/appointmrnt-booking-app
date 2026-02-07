-- Create appointments bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('appointments', 'appointments', true) 
ON CONFLICT (id) DO NOTHING;

-- RLS for bucket
-- 1. Allow public read access (for viewing documents/receipts)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage' 
        AND policyname = 'Public Access Appointments'
    ) THEN
        CREATE POLICY "Public Access Appointments" 
        ON storage.objects FOR SELECT 
        USING (bucket_id = 'appointments');
    END IF;
END $$;

-- 2. Allow authenticated users to upload (for booking)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage' 
        AND policyname = 'Authenticated Upload Appointments'
    ) THEN
        CREATE POLICY "Authenticated Upload Appointments" 
        ON storage.objects FOR INSERT 
        WITH CHECK (bucket_id = 'appointments' AND auth.role() = 'authenticated');
    END IF;
END $$;
