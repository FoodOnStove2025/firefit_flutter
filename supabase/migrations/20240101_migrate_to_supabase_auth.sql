-- Migration to support Supabase Auth alongside Bluesky fields
-- This migration makes Bluesky fields nullable to support both auth methods

-- Step 1: Make Bluesky-specific fields nullable
ALTER TABLE "Users" 
  ALTER COLUMN "did" DROP NOT NULL,
  ALTER COLUMN "handle" DROP NOT NULL,
  ALTER COLUMN "pdsUrl" DROP NOT NULL;

-- Step 2: Add default empty strings for existing NOT NULL constraints (if needed)
UPDATE "Users" 
SET 
  "did" = COALESCE("did", ''),
  "handle" = COALESCE("handle", ''),
  "pdsUrl" = COALESCE("pdsUrl", '')
WHERE "did" IS NULL OR "handle" IS NULL OR "pdsUrl" IS NULL;

-- Step 3: Create a foreign key relationship with Supabase auth.users table
-- Note: The Users.id column should match the auth.users.id for Supabase users
ALTER TABLE "Users"
  ADD CONSTRAINT users_auth_id_fkey 
  FOREIGN KEY (id) 
  REFERENCES auth.users(id) 
  ON DELETE CASCADE;

-- Step 4: Create an index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON "Users"(email);

-- Step 5: Add a column to distinguish auth provider (optional but useful)
ALTER TABLE "Users" 
  ADD COLUMN IF NOT EXISTS "authProvider" TEXT DEFAULT 'bluesky';

-- Update existing users to have 'bluesky' as their auth provider
UPDATE "Users" 
SET "authProvider" = 'bluesky' 
WHERE "did" IS NOT NULL AND "did" != '';

-- Step 6: Create a trigger to auto-create user profile on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Only create profile if it doesn't exist
  INSERT INTO public."Users" (
    id,
    email,
    "firstName",
    "lastName",
    "authProvider",
    "createdAt",
    "did",
    "handle",
    "pdsUrl"
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

-- Step 7: Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 8: Add RLS policies for Supabase auth users
-- Users can read their own profile
CREATE POLICY "Users can view own profile" ON "Users"
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON "Users"
  FOR UPDATE USING (auth.uid() = id);

-- Enable RLS on Users table
ALTER TABLE "Users" ENABLE ROW LEVEL SECURITY;

-- Step 9: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public."Users" TO authenticated;

-- Note: After running this migration, you'll need to:
-- 1. Update your application to use the useSupabaseAuth flag
-- 2. Test both auth methods thoroughly
-- 3. Eventually migrate existing Bluesky users to Supabase if desired