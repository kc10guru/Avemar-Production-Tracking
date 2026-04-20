#!/bin/bash
cd /opt/glass-aero-tracker
cp *.html frontend/
cp js/import.js frontend/js/
cp js/new-repair-order.js frontend/js/
cp js/repair-order-detail.js frontend/js/
cp js/repair-orders.js frontend/js/
cp js/reports.js frontend/js/
cp js/scan.js frontend/js/
docker-compose restart frontend
echo "Deploy complete"
