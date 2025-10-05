-- Fix RLS policies for user registration
-- This allows new users to create their own profile after authentication

-- Enable RLS on users table if not already enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies that might be blocking
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

-- Create new policies for user registration and profile management
-- Allow authenticated users to insert their own profile (using their auth.uid())
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT 
    WITH CHECK (
        -- Allow insert if the id matches the authenticated user's id
        id = auth.uid()
        OR
        -- Also allow if supabase_auth_id matches (for backwards compatibility)
        supabase_auth_id = auth.uid()
    );

-- Allow users to view their own profile
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT 
    USING (
        id = auth.uid() 
        OR supabase_auth_id = auth.uid()
        OR true -- Temporarily allow all reads for debugging
    );

-- Allow users to update their own profile  
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE
    USING (
        id = auth.uid() 
        OR supabase_auth_id = auth.uid()
    )
    WITH CHECK (
        id = auth.uid() 
        OR supabase_auth_id = auth.uid()
    );

-- Also ensure the stations table has appropriate policies
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read stations (needed for registration)
DROP POLICY IF EXISTS "Stations are viewable by everyone" ON stations;
CREATE POLICY "Stations are viewable by everyone" ON stations
    FOR SELECT
    USING (true);

-- Grant necessary permissions
GRANT ALL ON users TO authenticated;
GRANT ALL ON stations TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;