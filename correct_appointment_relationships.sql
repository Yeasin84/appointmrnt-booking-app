-- ========================================
-- Correct Appointment Relationships
-- ========================================
-- The previous verification showed the Foreign Keys point to 'auth.users'.
-- They MUST point to 'public.profiles' for the app's code to work.

-- 1. Drop the incorrect constraints (pointing to auth.users)
ALTER TABLE public.appointments
DROP CONSTRAINT IF EXISTS appointments_doctor_id_fkey;

ALTER TABLE public.appointments
DROP CONSTRAINT IF EXISTS appointments_patient_id_fkey;

-- 2. Re-create them pointing to public.profiles
ALTER TABLE public.appointments
ADD CONSTRAINT appointments_doctor_id_fkey
FOREIGN KEY (doctor_id)
REFERENCES public.profiles (id)
ON DELETE CASCADE;

ALTER TABLE public.appointments
ADD CONSTRAINT appointments_patient_id_fkey
FOREIGN KEY (patient_id)
REFERENCES public.profiles (id)
ON DELETE CASCADE;

-- 3. Verify Constraints targets 'public.profiles' (relname = 'profiles')
SELECT 
    c.conname, 
    cl.relname as target_table 
FROM pg_constraint c 
JOIN pg_class cl ON c.confrelid = cl.oid 
WHERE c.conrelid = 'public.appointments'::regclass;
