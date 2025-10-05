-- Fix the did unique constraint issue for Supabase users

-- Option 1: Make did nullable and remove the unique constraint for empty values
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_did_key;

-- Add a partial unique index that only enforces uniqueness for non-empty did values
CREATE UNIQUE INDEX users_did_unique ON users(did) 
WHERE did IS NOT NULL AND did != '';

-- Update existing empty did values to NULL
UPDATE users 
SET did = NULL 
WHERE did = '';

-- Also make handle and pds_url nullable if they aren't already
ALTER TABLE users 
ALTER COLUMN did DROP NOT NULL,
ALTER COLUMN handle DROP NOT NULL,
ALTER COLUMN pds_url DROP NOT NULL;

-- Update the trigger to use NULL instead of empty strings for Bluesky fields
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if user profile already exists
    IF EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id OR email = NEW.email) THEN
        -- Update existing profile instead of creating new one
        UPDATE public.users
        SET 
            first_name = COALESCE(NEW.raw_user_meta_data->>'first_name', first_name),
            last_name = COALESCE(NEW.raw_user_meta_data->>'last_name', last_name),
            updated_at = NOW(),
            supabase_auth_id = NEW.id
        WHERE id = NEW.id OR email = NEW.email;
    ELSE
        -- Create new profile with NULL for Bluesky fields
        INSERT INTO public.users (
            id,
            email,
            first_name,
            last_name,
            created_at,
            updated_at,
            supabase_auth_id,
            did,      -- NULL for Supabase users
            handle,   -- NULL for Supabase users
            pds_url   -- NULL for Supabase users
        )
        VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
            NOW(),
            NOW(),
            NEW.id,
            NULL,  -- Use NULL instead of empty string
            NULL,  -- Use NULL instead of empty string
            NULL   -- Use NULL instead of empty string
        );
    END IF;
    
    RETURN NEW;
END;
$$;