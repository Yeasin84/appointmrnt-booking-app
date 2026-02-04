-- 1. Create categories table if it doesn't only exist
create table if not exists categories (
  id uuid default gen_random_uuid() primary key,
  name text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Cleanup potential duplicates (keep the one with latest creation time or random)
-- This ensures we can add a unique constraint safely
delete from categories a using categories b
where a.id > b.id and a.name = b.name;

-- 3. Add Unique Constraint on 'name' if it doesn't exist
-- We wrap in a DO block to avoid error if it already exists
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'categories_name_unique') then
    alter table categories add constraint categories_name_unique unique (name);
  end if;
end $$;

-- 4. Enable RLS and Policies
alter table categories enable row level security;

drop policy if exists "Public can view categories" on categories;
create policy "Public can view categories" on categories for select using (true);

-- 5. Seed data safely
insert into categories (name) values
  ('General Physician'),
  ('Cardiologist'),
  ('Dermatologist'),
  ('Pediatrician'),
  ('Neurologist'),
  ('Gynecologist'),
  ('Orthopedic'),
  ('Dentist'),
  ('ENT'),
  ('Psychiatrist'),
  ('Urologist'),
  ('Ophthalmologist')
on conflict (name) do nothing;
