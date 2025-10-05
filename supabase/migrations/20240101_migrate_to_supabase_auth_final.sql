-- Migration to support Supabase Auth alongside Bluesky fields
-- This version uses the correct column names from your database

-- Step 1: Make Bluesky-specific fields nullable
ALTER TABLE users 
  ALTER COLUMN did DROP NOT NULL,
  ALTER COLUMN handle DROP NOT NULL,
  ALTER COLUMN pds_url DROP NOT NULL;

-- Step 2: Set default empty strings for NULL values
UPDATE users 
SET 
  did = COALESCE(did, ''),
  handle = COALESCE(handle, ''),
  pds_url = COALESCE(pds_url, '')
WHERE did IS NULL OR handle IS NULL OR pds_url IS NULL;

-- Step 3: Add missing columns if they don't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS primary_station_id UUID;
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 4: Create a foreign key relationship with Supabase auth.users table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'users_auth_id_fkey' 
        AND table_name = 'users'
    ) THEN
        ALTER TABLE users
            ADD CONSTRAINT users_auth_id_fkey 
            FOREIGN KEY (id) 
            REFERENCES auth.users(id) 
            ON DELETE CASCADE;
    END IF;
END $$;

-- Step 5: Create an index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Step 6: Add a column to distinguish auth provider
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'bluesky';

-- Update existing users to have 'bluesky' as their auth provider
UPDATE users 
SET auth_provider = 'bluesky' 
WHERE did IS NOT NULL AND did != '';

-- Step 7: Create a trigger to auto-create user profile on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Only create profile if it doesn't exist
  INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    auth_provider,
    created_at,
    did,
    handle,
    pds_url
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    'supabase',
    NOW(),
    '', -- Empty for Supabase users
    '', -- Empty for Supabase users
    ''  -- Empty for Supabase users
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 8: Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 9: Add RLS policies for Supabase auth users
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 10: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.users TO authenticated;

-- Verify the migration
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;