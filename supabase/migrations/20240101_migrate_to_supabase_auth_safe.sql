-- Migration to support Supabase Auth alongside Bluesky fields
-- This version handles existing users who don't have Supabase auth records

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

-- Step 4: Create an index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Step 5: Add a column to distinguish auth provider
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'bluesky';

-- Update existing users to have 'bluesky' as their auth provider
UPDATE users 
SET auth_provider = 'bluesky' 
WHERE did IS NOT NULL AND did != '';

-- Step 6: Add a column to optionally link to Supabase auth (instead of foreign key on id)
ALTER TABLE users ADD COLUMN IF NOT EXISTS supabase_auth_id UUID;

-- Create an index on the supabase_auth_id for performance
CREATE INDEX IF NOT EXISTS idx_users_supabase_auth_id ON users(supabase_auth_id);

-- Step 7: Add a foreign key ONLY on the new supabase_auth_id column
-- This allows existing Bluesky users to remain without Supabase auth records
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'users_supabase_auth_fkey' 
        AND table_name = 'users'
    ) THEN
        ALTER TABLE users
            ADD CONSTRAINT users_supabase_auth_fkey 
            FOREIGN KEY (supabase_auth_id) 
            REFERENCES auth.users(id) 
            ON DELETE SET NULL;
    END IF;
END $$;

-- Step 8: Create a trigger to auto-create user profile on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile for new Supabase auth users
  INSERT INTO public.users (
    id,
    supabase_auth_id,
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
    NEW.id, -- Use the Supabase auth ID as the primary key for new users
    NEW.id, -- Also store it in supabase_auth_id
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    'supabase',
    NOW(),
    '', -- Empty for Supabase users
    '', -- Empty for Supabase users
    ''  -- Empty for Supabase users
  )
  ON CONFLICT (id) DO UPDATE SET
    supabase_auth_id = EXCLUDED.supabase_auth_id,
    auth_provider = 'supabase'
  WHERE users.supabase_auth_id IS NULL; -- Only update if not already linked
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 10: Add RLS policies for Supabase auth users
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (
    auth.uid() = id -- For new Supabase users
    OR 
    auth.uid() = supabase_auth_id -- For migrated users
  );

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (
    auth.uid() = id -- For new Supabase users
    OR 
    auth.uid() = supabase_auth_id -- For migrated users
  );

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 11: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.users TO authenticated;

-- Step 12: Create a helper function to migrate a Bluesky user to Supabase
-- You can call this function when a user wants to switch from Bluesky to Supabase auth
CREATE OR REPLACE FUNCTION public.migrate_user_to_supabase(
  p_user_id UUID,
  p_supabase_auth_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE users
  SET 
    supabase_auth_id = p_supabase_auth_id,
    auth_provider = 'supabase'
  WHERE id = p_user_id
    AND supabase_auth_id IS NULL; -- Only if not already migrated
  
  RETURN FOUND; -- Returns true if a row was updated
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the migration
SELECT 
  'Total users:' as metric, 
  COUNT(*) as count 
FROM users
UNION ALL
SELECT 
  'Bluesky users:' as metric,
  COUNT(*) as count 
FROM users 
WHERE auth_provider = 'bluesky'
UNION ALL
SELECT 
  'Supabase users:' as metric,
  COUNT(*) as count 
FROM users 
WHERE auth_provider = 'supabase';