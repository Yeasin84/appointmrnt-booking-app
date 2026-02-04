-- Add latitude and longitude columns to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS latitude double precision,
ADD COLUMN IF NOT EXISTS longitude double precision;

-- Optional: Add a location column if you still want to support the JSON structure temporarily
-- ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location jsonb;
