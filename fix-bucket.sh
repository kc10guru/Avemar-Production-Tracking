#!/bin/bash
cd /opt/glass-aero-tracker

SK=$(grep SERVICE_KEY .env | head -1 | cut -d= -f2)

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
