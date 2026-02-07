-- Fix missing foreign key relationship between posts and profiles
-- This enables PostgREST to perform joins for the doctor feed

ALTER TABLE posts
DROP CONSTRAINT IF EXISTS posts_user_id_fkey;

ALTER TABLE posts
ADD CONSTRAINT posts_user_id_fkey
FOREIGN KEY (user_id) REFERENCES profiles(id)
ON DELETE CASCADE;

-- Also ensure comments have the same relationship if missing
ALTER TABLE post_comments
DROP CONSTRAINT IF EXISTS post_comments_user_id_fkey;

ALTER TABLE post_comments
ADD CONSTRAINT post_comments_user_id_fkey
FOREIGN KEY (user_id) REFERENCES profiles(id)
ON DELETE CASCADE;
