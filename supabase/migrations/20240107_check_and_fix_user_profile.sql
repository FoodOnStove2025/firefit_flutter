-- Check if the user profile already exists and link it to the auth user

-- 1. Check existing user profiles for this email
SELECT id, email, supabase_auth_id, created_at 
FROM users 
WHERE email = 'brileydeveloper@gmail.com';

-- 2. Get the latest auth user with this email
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'brileydeveloper@gmail.com'
ORDER BY created_at DESC
LIMIT 1;

-- 3. If the profile exists but isn't linked to the auth user, update it
-- Replace 'AUTH_USER_ID' with the actual ID from step 2
UPDATE users 
SET 
    supabase_auth_id = (SELECT id FROM auth.users WHERE email = 'brileydeveloper@gmail.com' ORDER BY created_at DESC LIMIT 1),
    id = (SELECT id FROM auth.users WHERE email = 'brileydeveloper@gmail.com' ORDER BY created_at DESC LIMIT 1)
WHERE email = 'brileydeveloper@gmail.com';

-- 4. Alternative: If you want to start fresh, delete everything and try again
-- DELETE FROM users WHERE email = 'brileydeveloper@gmail.com';
-- DELETE FROM auth.users WHERE email = 'brileydeveloper@gmail.com';