-- IT Admin User Management Functions
-- Run this in the Supabase SQL Editor or via psql on the VM
-- This creates functions for IT Admins to manage users (CRUD operations)

-- Ensure pgcrypto is available for bcrypt password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE USER - IT Admin can create new user accounts
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
  -- Check caller is admin or it_admin
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  IF caller_role NOT IN ('admin', 'it_admin') THEN
    RAISE EXCEPTION 'Access denied: admin or it_admin role required';
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

  -- IT Admins cannot create other IT Admins (only full admins can)
  IF caller_role = 'it_admin' AND user_role = 'it_admin' THEN
    RAISE EXCEPTION 'IT Admins cannot create other IT Admin accounts';
  END IF;

  -- Only allow valid roles
  IF user_role NOT IN ('user', 'admin') THEN
    RAISE EXCEPTION 'Invalid role. Must be "user" or "admin"';
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
-- DELETE USER - IT Admin can delete user accounts
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
  -- Check caller is admin or it_admin
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  IF caller_role NOT IN ('admin', 'it_admin') THEN
    RAISE EXCEPTION 'Access denied: admin or it_admin role required';
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

  -- IT Admins cannot delete other IT Admins or full Admins
  IF caller_role = 'it_admin' AND target_role IN ('admin', 'it_admin') THEN
    RAISE EXCEPTION 'IT Admins cannot delete Admin or IT Admin accounts';
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
-- SET USER ROLE - IT Admin can change a user's role
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
  -- Check caller is admin or it_admin
  SELECT COALESCE(raw_app_meta_data->>'role', 'user') INTO caller_role
  FROM auth.users WHERE id = auth.uid();
  
  IF caller_role NOT IN ('admin', 'it_admin') THEN
    RAISE EXCEPTION 'Access denied: admin or it_admin role required';
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

  -- IT Admins can only set 'user' or 'admin' roles (not it_admin)
  IF caller_role = 'it_admin' THEN
    IF new_role NOT IN ('user', 'admin') THEN
      RAISE EXCEPTION 'IT Admins can only assign "user" or "admin" roles';
    END IF;
    -- IT Admins cannot modify other IT Admins
    IF target_role = 'it_admin' THEN
      RAISE EXCEPTION 'IT Admins cannot modify other IT Admin accounts';
    END IF;
  END IF;

  -- Full admins can set any role including it_admin
  IF caller_role = 'admin' AND new_role NOT IN ('user', 'admin', 'it_admin') THEN
    RAISE EXCEPTION 'Invalid role. Must be "user", "admin", or "it_admin"';
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
-- LIST USERS (updated) - Also works for IT Admins
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
  
  IF caller_role NOT IN ('admin', 'it_admin') THEN
    RAISE EXCEPTION 'Access denied: admin or it_admin role required';
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
-- GRANT PERMISSIONS
-- ════════════════════════════════════════════════════════════════════════════
GRANT EXECUTE ON FUNCTION public.it_admin_create_user(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.it_admin_delete_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.it_admin_set_role(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_users() TO authenticated;
