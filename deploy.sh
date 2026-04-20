#!/bin/bash
cd /opt/glass-aero-tracker
cp *.html frontend/
cp js/*.js frontend/js/
docker-compose restart frontend
echo "Deploy complete"
