-- ========================================
-- Fix Appointment Relationships (Foreign Keys)
-- ========================================
-- This script adds missing Foreign Key constraints to the 'appointments' table.
-- This allows Supabase to resolve relationships like:
--   - appointments.doctor_id -> profiles.id
--   - appointments.patient_id -> profiles.id

-- 1. Add Foreign Key for Doctor
ALTER TABLE public.appointments
ADD CONSTRAINT appointments_doctor_id_fkey
FOREIGN KEY (doctor_id)
REFERENCES public.profiles (id)
ON DELETE CASCADE;

-- 2. Add Foreign Key for Patient
ALTER TABLE public.appointments
ADD CONSTRAINT appointments_patient_id_fkey
FOREIGN KEY (patient_id)
REFERENCES public.profiles (id)
ON DELETE CASCADE;

-- 3. Verify Constraints (Optional)
-- SELECT conname, confrelid::regclass, a.attname
-- FROM pg_constraint c
-- JOIN pg_attribute a ON a.attnum = ANY(c.conkey)
-- WHERE c.conrelid = 'public.appointments'::regclass;
