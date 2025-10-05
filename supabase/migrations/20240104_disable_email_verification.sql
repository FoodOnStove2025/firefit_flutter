-- Disable email verification for Supabase Auth
-- This allows users to login immediately after registration without confirming email

-- Update auth config to disable email confirmation
UPDATE auth.config 
SET 
    enable_signup = true,
    enable_confirmations = false
WHERE id = 1;

-- Alternative: If the above doesn't work, you can also update via the auth.config table
-- Note: This may vary based on your Supabase version
ALTER TABLE auth.users 
ALTER COLUMN email_confirmed_at 
SET DEFAULT NOW();

-- For any existing unconfirmed users, mark them as confirmed
UPDATE auth.users 
SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    confirmed_at = COALESCE(confirmed_at, NOW())
WHERE email_confirmed_at IS NULL;

-- Ensure new users are automatically confirmed
CREATE OR REPLACE FUNCTION public.auto_confirm_users()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Automatically confirm email for new users
    UPDATE auth.users
    SET 
        email_confirmed_at = NOW(),
        confirmed_at = NOW()
    WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created_confirm ON auth.users;

-- Create trigger to auto-confirm new users
CREATE TRIGGER on_auth_user_created_confirm
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_users();