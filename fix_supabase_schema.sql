-- 1. Fix get_nearby_doctors RPC
-- Drop all variations to be safe
DROP FUNCTION IF EXISTS get_nearby_doctors(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS get_nearby_doctors(json);
DROP FUNCTION IF EXISTS get_nearby_doctors(jsonb);

-- Re-create the function robustly
CREATE OR REPLACE FUNCTION get_nearby_doctors(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  full_name text,
  specialty text,
  avatar_url text,
  address text,
  latitude double precision,
  longitude double precision,
  dist_km double precision,
  is_video_available boolean,
  weekly_schedule jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.specialty,
    p.avatar_url,
    p.address,
    p.latitude,
    p.longitude,
    (
      6371 * acos(
        cos(radians(user_lat)) * cos(radians(p.latitude)) *
        cos(radians(p.longitude) - radians(user_lng)) +
        sin(radians(user_lat)) * sin(radians(p.latitude))
      )
    ) AS dist_km,
    p.is_video_available,
    ds.weekly_schedule
  FROM profiles p
  LEFT JOIN doctor_schedules ds ON p.id = ds.doctor_id
  WHERE
    p.role = 'doctor'
    AND p.latitude IS NOT NULL
    AND p.longitude IS NOT NULL
    AND (
      6371 * acos(
        cos(radians(user_lat)) * cos(radians(p.latitude)) *
        cos(radians(p.longitude) - radians(user_lng)) +
        sin(radians(user_lat)) * sin(radians(p.latitude))
      )
    ) < radius_km
  ORDER BY dist_km ASC;
END;
$$;

-- 2. Fix appointments table columns
DO $$ 
BEGIN 
    -- Ensure table exists (though it likely does)
    -- If it doesn't exist, this script won't create the whole thing but will at least try to add columns
    
    -- Add time if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='time') THEN
        ALTER TABLE public.appointments ADD COLUMN time TEXT;
    END IF;

    -- Add appointment_date if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='appointment_date') THEN
        ALTER TABLE public.appointments ADD COLUMN appointment_date DATE;
    END IF;

    -- Add status if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='status') THEN
        ALTER TABLE public.appointments ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;

    -- Add patient_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='patient_id') THEN
        ALTER TABLE public.appointments ADD COLUMN patient_id UUID REFERENCES profiles(id);
    END IF;

    -- Add doctor_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='doctor_id') THEN
        ALTER TABLE public.appointments ADD COLUMN doctor_id UUID REFERENCES profiles(id);
    END IF;
END $$;
