#!/bin/bash
cd /opt/glass-aero-tracker

AK=$(grep ANON_KEY .env | head -1 | cut -d= -f2)

echo "=== Updating supabase-config.js ==="
sed -i "s|const SUPABASE_URL = '.*'|const SUPABASE_URL = 'http://10.0.0.106:8080'|" js/supabase-config.js
sed -i "s|const SUPABASE_ANON_KEY = '.*'|const SUPABASE_ANON_KEY = '$AK'|" js/supabase-config.js

echo ""
echo "=== Verify ==="
grep "SUPABASE_URL\|SUPABASE_ANON_KEY" js/supabase-config.js | head -2

echo ""
echo "Done. Refresh the tablet browser."
