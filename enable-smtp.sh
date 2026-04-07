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
BACKUP="docker-compose.yml.bak-smtp"

cp "$COMPOSE" "$BACKUP"
echo "Backed up to $BACKUP"

if grep -q "GOTRUE_SMTP_HOST" "$COMPOSE"; then
  echo "SMTP already configured in $COMPOSE - skipping insert"
else
  sed -i "/API_EXTERNAL_URL/a\\
      GOTRUE_SMTP_HOST: smtp.gmail.com\\
      GOTRUE_SMTP_PORT: 587\\
      GOTRUE_SMTP_USER: jcdenterprisesokc@gmail.com\\
      GOTRUE_SMTP_PASS: ${APP_PASS}\\
      GOTRUE_SMTP_SENDER_NAME: Glass Aero Production Tracker\\
      GOTRUE_SMTP_ADMIN_EMAIL: jcdenterprisesokc@gmail.com\\
      GOTRUE_MAILER_URLPATHS_INVITE: /auth/v1/verify\\
      GOTRUE_MAILER_URLPATHS_CONFIRMATION: /auth/v1/verify\\
      GOTRUE_MAILER_URLPATHS_RECOVERY: /auth/v1/verify\\
      GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE: /auth/v1/verify" "$COMPOSE"
  echo "SMTP config added to $COMPOSE"
fi

echo ""
echo "=== Restarting auth container ==="
docker stop glass-aero-auth
docker rm glass-aero-auth
docker-compose up -d auth

sleep 10

echo ""
echo "=== Result ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep auth
echo ""
echo "=== Verify SMTP config ==="
docker exec glass-aero-auth env | grep SMTP | sed 's/GOTRUE_SMTP_PASS=.*/GOTRUE_SMTP_PASS=****/'
