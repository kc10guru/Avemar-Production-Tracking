#!/bin/bash
cd /opt/glass-aero-tracker

EMAIL="${1:?Usage: bash create-user.sh email@example.com password [admin]}"
PASS="${2:?Usage: bash create-user.sh email@example.com password [admin]}"
ROLE="${3:-user}"
ANON="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE3OTk1MzU2MDB9.Z7TQV4VxWaN_eGuMgccr_8q55wyu2rjBQhlwU_w3xJE"

echo "=== Creating user: $EMAIL (role: $ROLE) ==="

echo "Step 1: Clean up if exists..."
docker exec glass-aero-db psql -h 127.0.0.1 -U postgres -d postgres -c "
DELETE FROM auth.identities WHERE user_id IN (SELECT id FROM auth.users WHERE email = '$EMAIL');
DELETE FROM auth.sessions WHERE user_id IN (SELECT id FROM auth.users WHERE email = '$EMAIL');
DELETE FROM auth.refresh_tokens WHERE session_id IN (SELECT id FROM auth.sessions WHERE user_id IN (SELECT id FROM auth.users WHERE email = '$EMAIL'));
DELETE FROM auth.users WHERE email = '$EMAIL';
" 2>/dev/null

echo "Step 2: Signup via API..."
curl -s -X POST http://localhost:8080/auth/v1/signup \
  -H "apikey: $ANON" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" > /dev/null

if [ "$ROLE" = "admin" ]; then
  echo "Step 3: Setting admin role..."
  docker exec glass-aero-db psql -h 127.0.0.1 -U postgres -d postgres -c "
  UPDATE auth.users SET raw_app_meta_data = raw_app_meta_data || '{\"role\":\"admin\"}' WHERE email = '$EMAIL';
  " > /dev/null
fi

echo ""
echo "=== Verify ==="
docker exec glass-aero-db psql -h 127.0.0.1 -U postgres -d postgres -c "SELECT email, raw_app_meta_data->>'role' as role FROM auth.users WHERE email = '$EMAIL';"
