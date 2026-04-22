# Glass Aero Production Tracker - Deployment Package

This folder contains everything needed to deploy the Glass Aero Production Tracker on a client's server.

## What's Included

```
deployment/
├── docker-compose-full.yml    # Full stack with realtime + storage
├── .env.example               # Environment variables template
├── kong/
│   └── kong.yml               # API Gateway configuration
├── nginx/
│   └── nginx.conf             # Web server configuration
├── sql/                       # (You'll add exported SQL here)
└── frontend/                  # (You'll copy app files here)
```

## Quick Start

### 1. Copy this folder to the server

```powershell
# On the server, create the directory
mkdir C:\glass-aero-tracker
# Copy all contents here
```

### 2. Create required folders

```powershell
mkdir C:\glass-aero-tracker\data\postgres -Force
mkdir C:\glass-aero-tracker\data\storage -Force
mkdir C:\glass-aero-tracker\sql -Force
mkdir C:\glass-aero-tracker\frontend -Force
```

### 3. Configure environment

```powershell
Copy-Item .env.example .env
# Edit .env with actual values:
# - POSTGRES_PASSWORD
# - SITE_URL (server IP)
```

### 4. Export and copy data from source

On the source server:
```powershell
# Export auth schema
docker exec supabase-db pg_dump -U postgres -d postgres --schema=auth --no-owner --no-acl | Set-Content sql\01-auth-schema.sql -Encoding UTF8

# Export app data  
docker exec supabase-db pg_dump -U postgres -d postgres --no-owner --no-acl --table=public.app_settings --table=public.bom_items --table=public.hold_history --table=public.parts_issuance --table=public.production_parts --table=public.production_stages --table=public.repair_order_documents --table=public.repair_orders --table=public.stage_history --table=public.subcomponents | Set-Content sql\02-app-data.sql -Encoding UTF8
```

### 5. Copy frontend files

Copy all HTML files and the `js/` folder from the production system to `frontend/`.

Download vendor dependencies:
```powershell
mkdir frontend\vendor -Force
cd frontend\vendor
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js" -OutFile "supabase.min.js"
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js" -OutFile "JsBarcode.all.min.js"
```

### 6. Start the application

```powershell
docker compose -f docker-compose-full.yml up -d
```

### 7. Open firewall

```powershell
New-NetFirewallRule -DisplayName "Glass Aero Tracker" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

### 8. Access the app

Open browser to: `http://SERVER-IP:8080`

## Services Included

**Host ports** (defaults in `docker-compose-full.yml` — change the *left* value if a port is already in use; see `Glass Aero Production Tracker - On-Premises Deployment Guide.md` → *Changing host ports*.)

| Service | Purpose | Host → container port |
|---------|---------|------------------------|
| frontend | Web server (nginx) — **main URL for users** | 8080 → 80 |
| kong | API Gateway (optional direct access) | 8300 → 8000 |
| db | PostgreSQL (optional external tools/backups) | 5435 → 5432 |
| rest | REST API (PostgREST) | internal only |
| auth | Authentication (GoTrue) | internal only |
| realtime | Live updates (WebSocket) | internal only |
| storage | File uploads | internal only |

If you change **8080**, also update `.env` `SITE_URL` and `frontend/js/supabase-config.js` `SUPABASE_URL` to the same base URL (host + new port).

## Useful Commands

```powershell
# Start
docker compose -f docker-compose-full.yml up -d

# Stop
docker compose -f docker-compose-full.yml down

# View logs
docker compose -f docker-compose-full.yml logs -f

# Restart
docker compose -f docker-compose-full.yml restart

# Check status
docker compose -f docker-compose-full.yml ps
```

## Support

30-day post-deployment support included.
