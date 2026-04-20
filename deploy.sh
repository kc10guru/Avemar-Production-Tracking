#!/bin/bash
cd /opt/glass-aero-tracker
cp *.html deployment/frontend/
cp js/import.js deployment/frontend/js/
cp js/new-repair-order.js deployment/frontend/js/
cp js/repair-order-detail.js deployment/frontend/js/
cp js/repair-orders.js deployment/frontend/js/
cp js/reports.js deployment/frontend/js/
cp js/scan.js deployment/frontend/js/
docker-compose restart frontend
echo "Deploy complete"
