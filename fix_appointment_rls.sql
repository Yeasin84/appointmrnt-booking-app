-- ========================================
-- Fix Appointment RLS Policies
-- ========================================
-- This script adds Row Level Security policies to the appointments table
-- to allow authenticated users to create and view their appointments.

-- 1. Enable RLS on appointments table (if not already enabled)
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can insert their own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can view their own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update their own appointments" ON public.appointments;

-- 3. Create INSERT policy: Allow authenticated users to create appointments as patients
CREATE POLICY "Users can insert their own appointments"
ON public.appointments
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = patient_id
);

-- 4. Create SELECT policy: Allow users to view appointments where they are patient or doctor
CREATE POLICY "Users can view their own appointments"
ON public.appointments
FOR SELECT
TO authenticated
USING (
  auth.uid() = patient_id OR auth.uid() = doctor_id
);

-- 5. Create UPDATE policy: Allow users to update appointments where they are patient or doctor
CREATE POLICY "Users can update their own appointments"
ON public.appointments
FOR UPDATE
TO authenticated
USING (
  auth.uid() = patient_id OR auth.uid() = doctor_id
)
WITH CHECK (
  auth.uid() = patient_id OR auth.uid() = doctor_id
);

-- ========================================
-- Verification Query (Optional)
-- ========================================
-- Run this to verify policies are created:
-- SELECT * FROM pg_policies WHERE tablename = 'appointments';
