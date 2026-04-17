#!/bin/bash
cd /opt/glass-aero-tracker

JWT_SECRET=$(grep JWT_SECRET .env | head -1 | cut -d= -f2)
HEADER=$(printf '{"alg":"HS256","typ":"JWT"}' | openssl enc -base64 -A | tr '+/' '-_' | tr -d '=')
PAYLOAD=$(printf '{"role":"service_role","iss":"supabase","iat":1641769200,"exp":1799535600}' | openssl enc -base64 -A | tr '+/' '-_' | tr -d '=')
SIGNATURE=$(printf '%s.%s' "$HEADER" "$PAYLOAD" | openssl dgst -binary -sha256 -hmac "$JWT_SECRET" | openssl enc -base64 -A | tr '+/' '-_' | tr -d '=')
SK="${HEADER}.${PAYLOAD}.${SIGNATURE}"

echo "=== Creating bucket via Storage API ==="
RESULT=$(curl -s -X POST http://localhost:8080/storage/v1/bucket \
  -H "apikey: $SK" \
  -H "Authorization: Bearer $SK" \
  -H "Content-Type: application/json" \
  -d '{"id":"repair-order-docs","name":"repair-order-docs","public":false}')
echo "Result: $RESULT"

echo ""
echo "=== Verify bucket ==="
curl -s http://localhost:8080/storage/v1/bucket \
  -H "apikey: $SK" \
  -H "Authorization: Bearer $SK"
echo ""

echo ""
echo "=== Test upload directory ==="
docker exec glass-aero-storage ls -la /var/lib/storage/
