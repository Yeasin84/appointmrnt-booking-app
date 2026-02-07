-- 1. Create 'avatars' bucket if it doesn't exist
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 2. Create 'chat-attachments' bucket if it doesn't exist (saw this used in ApiService)
insert into storage.buckets (id, name, public) 
values ('chat-attachments', 'chat-attachments', true)
on conflict (id) do nothing;

-- 3. Set up storage policies for 'avatars'
create policy "Public Access Avatars" on storage.objects 
for select using ( bucket_id = 'avatars' );

create policy "Authenticated Upload Avatars" on storage.objects 
for insert with check ( bucket_id = 'avatars' and auth.role() = 'authenticated' );

-- 4. Create Nearby Doctors RPC (Haversine Formula)
-- Drop if exists to ensure clean update
drop function if exists get_nearby_doctors;

create or replace function get_nearby_doctors(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision default 50
)
returns table (
  id uuid,
  full_name text,
  specialty text,
  avatar_url text,
  address text,
  latitude double precision,
  longitude double precision,
  dist_km double precision,
  is_video_available boolean,
  weekly_schedule jsonb -- ✅ Added schedule support
)
language plpgsql
as $$
begin
  return query
  select
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
    ) as dist_km,
    p.is_video_available,
    ds.weekly_schedule -- ✅ Added from join
  from profiles p
  left join doctor_schedules ds on p.id = ds.doctor_id -- ✅ Joined for schedule
  where
    p.role = 'doctor'
    and p.latitude is not null
    and p.longitude is not null
    and (
      6371 * acos(
        cos(radians(user_lat)) * cos(radians(p.latitude)) *
        cos(radians(p.longitude) - radians(user_lng)) +
        sin(radians(user_lat)) * sin(radians(p.latitude))
      )
    ) < radius_km
  order by dist_km asc;
end;
$$;

