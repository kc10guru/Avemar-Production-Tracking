-- Create user with password hash from home server
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, role, aud,
  created_at, updated_at, confirmation_token
) VALUES (
  gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
  'jcdenterprisesokc@gmail.com',
  '$2a$10$Wu0CqSltMv.j4OKIw00es.iO8HrGK.GSD5RKB3VzGd.A0R9qHu/2a',
  NOW(),
  '{"provider":"email","providers":["email"],"role":"admin"}'::jsonb,
  '{}'::jsonb, 'authenticated', 'authenticated',
  NOW(), NOW(), ''
);

INSERT INTO auth.identities (
  provider_id, user_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at, id
)
SELECT
  u.id::text, u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true, 'phone_verified', false),
  'email', NOW(), NOW(), NOW(), gen_random_uuid()
FROM auth.users u
WHERE u.email = 'jcdenterprisesokc@gmail.com';
