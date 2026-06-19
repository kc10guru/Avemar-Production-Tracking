-- IT Admin User Management Functions
-- Run this in the Supabase SQL Editor or via psql on the VM
-- This creates functions for IT Admins and Super Admins to manage users (CRUD operations)
--
-- Roles:
--   super_admin - Full access to everything (production + user CRUD)
--   admin       - Production management only (can VIEW users but not modify)
--   it_admin    - User CRUD only (no production access)
--   user        - Standard user (no admin access)

-- Ensure pgcrypto is available for bcrypt password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE USER - IT Admin or Super Admin can create new user accounts
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.it_admin_create_user(
  user_email text,
  user_password text,
  user_role text DEFAULT 'user'
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  new_user_id uuid;
  caller_role text;
BEGIN
  -- Check caller is it_admin or super_admin (regular admin cannot create users)
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  IF caller_role NOT IN ('it_admin', 'super_admin') THEN
    RAISE EXCEPTION 'Access denied: it_admin or super_admin role required';
  END IF;

  -- Validate email
  IF user_email IS NULL OR user_email = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;

  -- Validate password
  IF length(user_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  -- Check email doesn't already exist
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = user_email) THEN
    RAISE EXCEPTION 'A user with this email already exists';
  END IF;

  -- IT Admins cannot create other IT Admins or Super Admins
  IF caller_role = 'it_admin' AND user_role IN ('it_admin', 'super_admin') THEN
    RAISE EXCEPTION 'IT Admins cannot create IT Admin or Super Admin accounts';
  END IF;

  -- Only allow valid roles (super_admin can create any role)
  IF caller_role = 'super_admin' THEN
    IF user_role NOT IN ('user', 'admin', 'it_admin') THEN
      RAISE EXCEPTION 'Invalid role. Must be "user", "admin", or "it_admin"';
    END IF;
  ELSE
    IF user_role NOT IN ('user', 'admin') THEN
      RAISE EXCEPTION 'Invalid role. Must be "user" or "admin"';
    END IF;
  END IF;

  -- Create the user in auth.users
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token
  ) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    user_email,
    crypt(user_password, gen_salt('bf')),
    now(),
    CASE WHEN user_role = 'user' THEN '{}'::jsonb ELSE jsonb_build_object('role', user_role) END,
    '{}'::jsonb,
    'authenticated',
    'authenticated',
    now(),
    now(),
    '',
    ''
  )
  RETURNING id INTO new_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', new_user_id,
    'email', user_email,
    'role', user_role
  );
END;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- DELETE USER - IT Admin or Super Admin can delete user accounts
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.it_admin_delete_user(target_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  caller_role text;
  target_role text;
  target_email text;
BEGIN
  -- Check caller is it_admin or super_admin (regular admin cannot delete users)
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  IF caller_role NOT IN ('it_admin', 'super_admin') THEN
    RAISE EXCEPTION 'Access denied: it_admin or super_admin role required';
  END IF;

  -- Get target user info
  SELECT email, COALESCE(raw_app_meta_data->>'role', 'user') 
  INTO target_email, target_role
  FROM auth.users WHERE id = target_user_id;

  IF target_email IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Prevent self-deletion
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot delete your own account';
  END IF;

  -- IT Admins cannot delete Super Admins or other IT Admins
  IF caller_role = 'it_admin' AND target_role IN ('super_admin', 'it_admin') THEN
    RAISE EXCEPTION 'IT Admins cannot delete Super Admin or IT Admin accounts';
  END IF;
  
  -- Nobody can delete a super_admin except another super_admin
  IF target_role = 'super_admin' AND caller_role != 'super_admin' THEN
    RAISE EXCEPTION 'Only Super Admins can delete other Super Admin accounts';
  END IF;

  -- Delete the user
  DELETE FROM auth.users WHERE id = target_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'deleted_email', target_email
  );
END;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- SET USER ROLE - IT Admin or Super Admin can change a user's role
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.it_admin_set_role(target_user_id uuid, new_role text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  caller_role text;
  target_role text;
  target_email text;
BEGIN
  -- Check caller is it_admin or super_admin (regular admin cannot change roles)
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  IF caller_role NOT IN ('it_admin', 'super_admin') THEN
    RAISE EXCEPTION 'Access denied: it_admin or super_admin role required';
  END IF;

  -- Get target user info
  SELECT email, COALESCE(raw_app_meta_data->>'role', 'user') 
  INTO target_email, target_role
  FROM auth.users WHERE id = target_user_id;

  IF target_email IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Prevent changing own role
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot change your own role';
  END IF;

  -- IT Admins can only set 'user' or 'admin' roles (not it_admin or super_admin)
  IF caller_role = 'it_admin' THEN
    IF new_role NOT IN ('user', 'admin') THEN
      RAISE EXCEPTION 'IT Admins can only assign "user" or "admin" roles';
    END IF;
    -- IT Admins cannot modify other IT Admins or Super Admins
    IF target_role IN ('it_admin', 'super_admin') THEN
      RAISE EXCEPTION 'IT Admins cannot modify IT Admin or Super Admin accounts';
    END IF;
  END IF;

  -- Super admins can set any role except super_admin (protect super_admin accounts)
  IF caller_role = 'super_admin' THEN
    IF new_role NOT IN ('user', 'admin', 'it_admin') THEN
      RAISE EXCEPTION 'Invalid role. Must be "user", "admin", or "it_admin"';
    END IF;
    -- Cannot demote another super_admin
    IF target_role = 'super_admin' THEN
      RAISE EXCEPTION 'Cannot change role of another Super Admin account';
    END IF;
  END IF;

  -- Update the role
  IF new_role = 'user' THEN
    -- Remove role from metadata (default is user)
    UPDATE auth.users 
    SET raw_app_meta_data = raw_app_meta_data - 'role',
        updated_at = now()
    WHERE id = target_user_id;
  ELSE
    -- Set the role
    UPDATE auth.users 
    SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object('role', new_role),
        updated_at = now()
    WHERE id = target_user_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'email', target_email,
    'old_role', target_role,
    'new_role', new_role
  );
END;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- LIST USERS - Admin, IT Admin, and Super Admin can view users
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.admin_list_users()
RETURNS TABLE(id uuid, email text, role text, created_at timestamptz, last_sign_in timestamptz)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  caller_role text;
BEGIN
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  -- admin can VIEW users (but not modify), it_admin and super_admin have full access
  IF caller_role NOT IN ('admin', 'it_admin', 'super_admin') THEN
    RAISE EXCEPTION 'Access denied: admin, it_admin, or super_admin role required';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    u.email::text,
    COALESCE(u.raw_app_meta_data->>'role', 'user')::text AS role,
    u.created_at,
    u.last_sign_in_at
  FROM auth.users u
  ORDER BY u.email;
END;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- RESET PASSWORD - IT Admin or Super Admin can reset user passwords
-- ════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.admin_reset_password(target_user_id uuid, new_password text)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  caller_role text;
  target_role text;
BEGIN
  -- Check caller is it_admin or super_admin
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  IF caller_role NOT IN ('it_admin', 'super_admin') THEN
    RAISE EXCEPTION 'Access denied: it_admin or super_admin role required';
  END IF;

  -- Get target user role
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO target_role
  FROM auth.users WHERE id = target_user_id;

  IF target_role IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- IT Admins cannot reset passwords for super_admin or other it_admin
  IF caller_role = 'it_admin' AND target_role IN ('super_admin', 'it_admin') THEN
    RAISE EXCEPTION 'IT Admins cannot reset passwords for Super Admin or IT Admin accounts';
  END IF;

  -- Cannot reset super_admin password unless you are super_admin
  IF target_role = 'super_admin' AND caller_role != 'super_admin' THEN
    RAISE EXCEPTION 'Only Super Admins can reset Super Admin passwords';
  END IF;

  IF length(new_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf')),
      updated_at = now()
  WHERE id = target_user_id;

  RETURN true;
END;
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- GRANT PERMISSIONS
-- ════════════════════════════════════════════════════════════════════════════
GRANT EXECUTE ON FUNCTION public.it_admin_create_user(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.it_admin_delete_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.it_admin_set_role(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_reset_password(uuid, text) TO authenticated;
