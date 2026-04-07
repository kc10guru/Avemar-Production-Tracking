#!/bin/bash
cd /opt/glass-aero-tracker

echo "=== Enable Gmail SMTP for GoTrue ==="
echo ""
read -sp "Enter your Gmail App Password (16 chars, no spaces): " APP_PASS
echo ""

if [ ${#APP_PASS} -lt 16 ]; then
  echo "ERROR: App password should be 16 characters. Got ${#APP_PASS}."
  exit 1
fi

COMPOSE="docker-compose.yml"

cp "$COMPOSE" "${COMPOSE}.bak-smtp2"
echo "Backed up to ${COMPOSE}.bak-smtp2"

if grep -q "GOTRUE_SMTP_HOST" "$COMPOSE"; then
  echo "SMTP already configured - removing old config first"
  grep -v "GOTRUE_SMTP_\|GOTRUE_MAILER_URLPATHS_" "$COMPOSE" > "${COMPOSE}.tmp"
  mv "${COMPOSE}.tmp" "$COMPOSE"
fi

python3 -c "
import sys
lines = open('$COMPOSE').readlines()
out = []
for line in lines:
    out.append(line)
    if 'API_EXTERNAL_URL' in line:
        indent = '      '
        out.append(indent + 'GOTRUE_SMTP_HOST: smtp.gmail.com\n')
        out.append(indent + 'GOTRUE_SMTP_PORT: 587\n')
        out.append(indent + 'GOTRUE_SMTP_USER: jcdenterprisesokc@gmail.com\n')
        out.append(indent + 'GOTRUE_SMTP_PASS: $APP_PASS\n')
        out.append(indent + 'GOTRUE_SMTP_SENDER_NAME: Glass Aero Production Tracker\n')
        out.append(indent + 'GOTRUE_SMTP_ADMIN_EMAIL: jcdenterprisesokc@gmail.com\n')
        out.append(indent + 'GOTRUE_MAILER_URLPATHS_INVITE: /auth/v1/verify\n')
        out.append(indent + 'GOTRUE_MAILER_URLPATHS_CONFIRMATION: /auth/v1/verify\n')
        out.append(indent + 'GOTRUE_MAILER_URLPATHS_RECOVERY: /auth/v1/verify\n')
        out.append(indent + 'GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE: /auth/v1/verify\n')
open('$COMPOSE', 'w').writelines(out)
"

echo "SMTP config added to $COMPOSE"

echo ""
echo "=== Restarting auth container ==="
docker stop glass-aero-auth 2>/dev/null
docker rm glass-aero-auth 2>/dev/null
docker-compose up -d auth

sleep 10

echo ""
echo "=== Result ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep auth
echo ""
echo "=== Verify SMTP config ==="
docker exec glass-aero-auth env 2>/dev/null | grep SMTP | sed 's/GOTRUE_SMTP_PASS=.*/GOTRUE_SMTP_PASS=****/'
