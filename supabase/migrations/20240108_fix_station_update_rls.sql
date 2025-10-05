-- Fix RLS policies to allow updating primary_station_id

-- Drop existing update policy
DROP POLICY IF EXISTS "Allow authenticated update" ON users;

-- Create a more permissive update policy that allows updating station ID
CREATE POLICY "Allow users to update their own profile" ON users
    FOR UPDATE
    USING (
        -- Allow users to update their own profile
        auth.uid() = id 
        OR auth.uid() = supabase_auth_id
        -- Or allow during registration (when email matches but station not set)
        OR (email = auth.jwt() ->> 'email' AND primary_station_id IS NULL)
    )
    WITH CHECK (
        -- Allow users to update their own profile
        auth.uid() = id 
        OR auth.uid() = supabase_auth_id
        -- Or allow during registration (when email matches but station not set)
        OR (email = auth.jwt() ->> 'email')
    );

-- Also ensure the insert policy allows setting station ID
DROP POLICY IF EXISTS "Allow authenticated insert" ON users;

CREATE POLICY "Allow authenticated insert" ON users
    FOR INSERT
    WITH CHECK (
        -- Allow creating a profile with same ID as auth user
        auth.uid() = id 
        OR auth.uid() = supabase_auth_id
        -- Or allow creating with email matching the auth user
        OR email = auth.jwt() ->> 'email'
    );

-- Grant update permission on primary_station_id column
GRANT UPDATE (primary_station_id, first_name, last_name, updated_at) ON users TO authenticated;