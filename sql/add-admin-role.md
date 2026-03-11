# Admin Role for BOM and Settings Access

The BOM and Settings tabs are restricted to users with admin rights. Standard users cannot see or access these tabs.

## How to Grant Admin Access

Admin status is stored in Supabase Auth `app_metadata.role`. Set it to `"admin"` for users who should have access.

### Option 1: Supabase Dashboard

1. Go to **Authentication** → **Users**
2. Click on the user you want to make an admin
3. Click **Edit user** (or the three-dots menu)
4. In **Raw User Meta Data** (or **User Metadata**), add or edit:
   ```json
   {
     "role": "admin"
   }
   ```
5. Save

### Option 2: SQL (Supabase SQL Editor)

Run this, replacing `USER_EMAIL_HERE` with the admin's email:

```sql
UPDATE auth.users
SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb
WHERE email = 'USER_EMAIL_HERE';
```

To remove admin access:

```sql
UPDATE auth.users
SET raw_app_meta_data = raw_app_meta_data - 'role'
WHERE email = 'USER_EMAIL_HERE';
```

### Option 3: Supabase Admin API

If using the service role key, you can update a user's metadata programmatically. See [Supabase Auth Admin API](https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid).
