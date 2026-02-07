-- Update appointments table
-- Add booked_for if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='booked_for') THEN
        ALTER TABLE public.appointments ADD COLUMN booked_for JSONB;
    END IF;

    -- Add medical_documents if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='medical_documents') THEN
        ALTER TABLE public.appointments ADD COLUMN medical_documents TEXT[];
    END IF;

    -- Add payment_screenshot if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='payment_screenshot') THEN
        ALTER TABLE public.appointments ADD COLUMN payment_screenshot TEXT;
    END IF;

    -- Add appointment_type if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='appointment_type') THEN
        ALTER TABLE public.appointments ADD COLUMN appointment_type TEXT DEFAULT 'physical';
    END IF;

    -- Add symptoms if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='symptoms') THEN
        ALTER TABLE public.appointments ADD COLUMN symptoms TEXT;
    END IF;

    -- Add notes if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='notes') THEN
        ALTER TABLE public.appointments ADD COLUMN notes TEXT;
    END IF;
END $$;
