#!/bin/bash
cd /opt/glass-aero-tracker

# Copy HTML and JS files
cp *.html frontend/
cp js/*.js frontend/js/

# Fix supabase-config.js with on-premises settings from .env
ANON=$(grep ANON_KEY .env | cut -d= -f2)
SITE=$(grep SITE_URL .env | cut -d= -f2)
sed -i "s|const SUPABASE_URL = '.*'|const SUPABASE_URL = '$SITE'|" frontend/js/supabase-config.js
sed -i "s|const SUPABASE_ANON_KEY = '.*'|const SUPABASE_ANON_KEY = '$ANON'|" frontend/js/supabase-config.js

# Update nginx config
cp deployment/nginx/nginx.conf nginx/nginx.conf

# Full restart to clear all caches
docker-compose down
docker-compose up -d
echo "Deploy complete"
