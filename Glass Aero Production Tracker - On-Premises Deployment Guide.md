# Glass Aero Production Tracker
## On-Premises Deployment Guide

This guide covers deploying the Production Tracker on internal infrastructure with no external dependencies. Once deployed, the system runs entirely within your network with no internet connectivity required.

**This guide is based on a tested deployment and includes the exact configuration files that work.**

---

## Deployment Overview

### What You're Deploying

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | Static HTML/JS/CSS via nginx | User interface (web pages) |
| **Database** | Supabase PostgreSQL 15 | All application data + auth schema |
| **API Layer** | PostgREST | REST API for database access |
| **Authentication** | GoTrue | User login and session management |
| **Realtime** | Supabase Realtime | Live updates across browser sessions |
| **Storage** | Supabase Storage | Document/file uploads |
| **API Gateway** | Kong | Routes requests to correct services |

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Browsers                          │
│                    (Desktop, Tablet, Mobile)                     │
└─────────────────────────────┬───────────────────────────────────┘
                              │ Port 8080 (default; see Host ports)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      nginx (Frontend)                            │
│              Serves HTML/JS/CSS + Proxies API calls              │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Kong (API Gateway)                          │
│                Routes: /rest, /auth, /realtime, /storage         │
└───────┬─────────────┬─────────────┬─────────────┬───────────────┘
        │             │             │             │
        ▼             ▼             ▼             ▼
┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐
│ PostgREST │  │  GoTrue   │  │ Realtime  │  │  Storage  │
│  (REST)   │  │  (Auth)   │  │(WebSocket)│  │  (Files)  │
└─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
      │              │              │              │
      └──────────────┴──────────────┴──────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                           │
│               (Supabase Postgres with Auth Schema)               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 50 GB SSD | 100 GB SSD |
| OS | Windows Server 2019+, Windows 10/11 Pro, or Ubuntu 22.04 LTS |

### Software Requirements

- **Docker Desktop** (Windows) or Docker Engine (Linux)
- Docker Compose (included with Docker Desktop)

### Network Requirements

These are the **default** TCP ports **published on the host** by `deployment/docker-compose-full.yml`. Anything not listed here stays **inside Docker** only (containers talk to each other by service name; you do not open those ports on the firewall for normal use).

| Host port | Container service | Container port | Who uses it |
|-----------|-------------------|----------------|-------------|
| **8080** | `frontend` (nginx) | 80 | **Everyone** — this is the URL users open in the browser (`http://SERVER:8080`). All API and auth traffic is proxied through nginx to Kong internally. |
| **8300** | `kong` | 8000 | **Optional** — direct access to the API gateway from the host (debugging, tools, or future integrations). Normal users **do not** need this port; the app works with only **8080** open. |
| **5435** | `db` (PostgreSQL) | 5432 | **Admins / backups** — only if you connect to Postgres from outside Docker (e.g. `psql`, GUI, backup agent). The app containers use `db:5432` on the Docker network and do not use this host mapping. |

**Inside Docker only (do not remap on the host for conflicts):** PostgREST `rest` (3000), GoTrue `auth` (9999), Realtime (4000), Storage (5000), and nginx → Kong `kong:8000` are **internal** service-to-service ports. You change those only if you customize images; the default stack does not require it.

---

## Deploying on an existing VM (client already runs the server)

Use this when the **virtual machine (or physical server) already exists**, the client’s IT operates it, and you are **adding** this stack beside their other workloads (fully remote once you have access).

### Before you start (coordinate with IT — usually remote)

1. **OS** — Windows Server / Windows 10–11 Pro, or **Ubuntu 22.04 LTS** (or similar). Determine which playbook you follow for Docker (Docker Desktop vs Docker Engine).
2. **Resources** — Confirm CPU, RAM, and disk meet [Server Requirements](#server-requirements) in addition to what is already running.
3. **Port check** — On the VM, verify **8080**, **8300**, and **5435** are free, or plan replacements using [Changing host ports (conflicts)](#changing-host-ports-when-the-defaults-are-already-in-use) below.
4. **Access** — VPN or jump host, plus **RDP or SSH** and rights to install/run **Docker** and edit files (**Administrator** / `sudo`).
5. **Firewall** — IT opens the chosen **user-facing** port (default **8080**) from the shop network or VPN. **5435** only if you need external DB access.
6. **Backup ownership** — Agree who backs up `deployment/data/postgres` (and storage) and how often.

### What you deploy

You copy the `deployment/` bundle, create `.env`, place SQL + `frontend/` files, run `docker compose`, run migrations if needed, and smoke-test in a browser. **You are not** replacing their hypervisor or base OS.

### What stays with the client

Patching the VM, corporate antivirus, network rules you cannot change yourself, and any **existing** apps on the same host — this stack is isolated in **Docker** as long as **host ports** do not collide.

---

## Changing host ports when the defaults are already in use

If IT says **8080**, **8300**, or **5435** is taken, change **only** the **left** side of the port mapping in Docker (`HOST:CONTAINER`). The **right** side (container port) must stay the same unless you change the image configuration (not recommended).

### Example: use **9080** for the website instead of **8080**

1. **`deployment/docker-compose-full.yml`** — `frontend` service:
   - Change:
     ```yaml
     ports:
       - "8080:80"
     ```
   - To (pick any free host port):
     ```yaml
     ports:
       - "9080:80"
     ```

2. **`deployment/.env`** (and copy from `.env.example` if needed) — **`SITE_URL`** must match what users type in the browser (same host/IP and **new** port):
   ```bash
   SITE_URL=http://192.168.1.100:9080
   ```
   GoTrue uses this for redirects and auth; it must stay in sync with the public URL.

3. **`deployment/frontend/js/supabase-config.js`** — set the client to the **same** base URL (scheme + host + port):
   ```javascript
   const SUPABASE_URL = 'http://192.168.1.100:9080';
   ```
   The anon key does not change when you change ports.

4. **Rebuild/restart containers** so GoTrue picks up the new `SITE_URL`:
   ```powershell
   cd C:\glass-aero-tracker   # or your Linux path
   docker compose -f docker-compose-full.yml down
   docker compose -f docker-compose-full.yml up -d
   ```

5. **Firewall** — Allow the **new** host port (e.g. **9080**), not 8080.

6. **Documentation** — Give users `http://SERVER:9080` (or your hostname).

**You do not need to edit** `deployment/nginx/nginx.conf` or `deployment/kong/kong.yml` for a host port change on **frontend** — they still use `kong:8000` inside the Docker network.

---

### Example: **Kong** host port **8300** is taken

Only required if something on the host must talk to Kong **directly** (bypassing nginx). Browsers using the normal app URL only need **frontend** port.

In **`docker-compose-full.yml`**, `kong` service:
```yaml
ports:
  - "9300:8000"
```
Use any free host port in place of `9300`. **No** changes to nginx, `.env`, or `supabase-config.js` are required for this alone.

**Optional:** If you will **never** call Kong from the host, you can remove the entire `ports:` block under `kong`. Nginx will still reach Kong at `http://kong:8000` on the Docker network. (Useful if you want the fewest exposed ports.)

---

### Example: **PostgreSQL** host port **5435** is taken

In **`docker-compose-full.yml`**, `db` service:
```yaml
ports:
  - "5436:5432"
```
Use any free host port (e.g. **5436**). **No** change to `.env`, `SITE_URL`, or `supabase-config.js` — app containers still use `db:5432` internally. Update firewall rules and any connection strings your **backup or DBA tools** use on the host.

---

### Quick reference: files to touch when changing ports

| If you change… | Edit these files |
|----------------|------------------|
| User-facing URL port (8080 → something else) | `docker-compose-full.yml` (`frontend` ports), `.env` (`SITE_URL`), `frontend/js/supabase-config.js` (`SUPABASE_URL`), host firewall |
| Kong host port only (8300) | `docker-compose-full.yml` (`kong` ports) only |
| Postgres host port only (5435) | `docker-compose-full.yml` (`db` ports) only; update DB tools/backups |

---

## Deployment Files

All configuration files are in the `deployment/` folder:

```
deployment/
├── docker-compose-full.yml    # Docker services configuration
├── .env.example               # Environment variables template
├── kong/
│   └── kong.yml               # API Gateway routing
├── nginx/
│   └── nginx.conf             # Web server configuration
├── sql/                       # Database export files (you'll add these)
├── frontend/                  # Application files (you'll copy these)
└── README.md                  # Quick reference guide
```

---

## Step-by-Step Deployment

### Step 1: Install Docker

#### Windows (Docker Desktop)

1. Download Docker Desktop from https://www.docker.com/products/docker-desktop
2. Run installer and restart when prompted
3. Open Docker Desktop and wait for it to start
4. Verify installation: Open PowerShell and run `docker --version`

#### Ubuntu/Linux (Docker Engine)

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add your user to docker group (so you don't need sudo)
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Step 2: Create Project Directory

#### Windows (PowerShell)

```powershell
mkdir C:\glass-aero-tracker
mkdir C:\glass-aero-tracker\data\postgres -Force
mkdir C:\glass-aero-tracker\data\storage -Force
mkdir C:\glass-aero-tracker\frontend\vendor -Force
mkdir C:\glass-aero-tracker\frontend\js -Force
mkdir C:\glass-aero-tracker\sql -Force
mkdir C:\glass-aero-tracker\kong -Force
mkdir C:\glass-aero-tracker\nginx -Force
```

#### Ubuntu/Linux (Bash)

```bash
sudo mkdir -p /opt/glass-aero-tracker
sudo chown $USER:$USER /opt/glass-aero-tracker
cd /opt/glass-aero-tracker

mkdir -p data/postgres
mkdir -p data/storage
mkdir -p frontend/vendor
mkdir -p frontend/js
mkdir -p sql
mkdir -p kong
mkdir -p nginx
```

### Step 3: Create Environment File

Create the `.env` file:
- **Windows:** `C:\glass-aero-tracker\.env`
- **Ubuntu:** `/opt/glass-aero-tracker/.env`

```bash
# Glass Aero Production Tracker - Environment Configuration
# CHANGE THESE VALUES FOR YOUR DEPLOYMENT

# Database password (use a strong password!)
POSTGRES_PASSWORD=YourSecurePassword2026!

# Server URL (replace with actual server IP or hostname)
SITE_URL=http://192.168.1.100:8080

# JWT Secret - used to sign/verify all tokens
JWT_SECRET=M6bg4COXecRqALB8wJzWrEo7uV03liITm9dy2NtsGDFk1KfhPvSjQYaZpUxnH5

# Anon Key - allows anonymous/public access (role: anon)
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE3OTk1MzU2MDB9.Z7TQV4VxWaN_eGuMgccr_8q55wyu2rjBQhlwU_w3xJE

# Service Key - full admin access (role: service_role) - keep secret!
SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE2NDE3NjkyMDAsImV4cCI6MTc5OTUzNTYwMH0.placeholder-generate-new

# Secret key for realtime service
SECRET_KEY_BASE=UpNVntn3cDxHJpq8l5/+0bFFhU2F0t0Z3G8p5EjE+3eZ8h7YdHk7jXPLzKbG8+0JHc8U0qF3nV6b9f3d2e1c0b9a
```

**Important:** 
- Change `POSTGRES_PASSWORD` to a strong password
- Change `SITE_URL` to the server's actual IP address

### Step 4: Create Docker Compose File

Create the `docker-compose.yml` file:
- **Windows:** `C:\glass-aero-tracker\docker-compose.yml`
- **Ubuntu:** `/opt/glass-aero-tracker/docker-compose.yml`

```yaml
version: "3.8"

name: glass-aero-tracker

services:
  # PostgreSQL Database (Supabase image includes auth schema)
  db:
    image: supabase/postgres:15.8.1.085
    container_name: glass-aero-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: postgres
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./sql:/docker-entrypoint-initdb.d
    ports:
      - "5435:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # PostgREST API
  rest:
    image: postgrest/postgrest:v12.0.2
    container_name: glass-aero-rest
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PGRST_DB_URI: postgres://postgres:${POSTGRES_PASSWORD}@db:5432/postgres
      PGRST_DB_SCHEMAS: public,storage
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: ${JWT_SECRET}
      PGRST_DB_USE_LEGACY_GUCS: "false"

  # GoTrue Authentication
  auth:
    image: supabase/gotrue:v2.143.0
    container_name: glass-aero-auth
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://supabase_auth_admin:${POSTGRES_PASSWORD}@db:5432/postgres
      GOTRUE_SITE_URL: ${SITE_URL}
      GOTRUE_URI_ALLOW_LIST: "*"
      GOTRUE_JWT_SECRET: ${JWT_SECRET}
      GOTRUE_JWT_EXP: 3600
      GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated
      GOTRUE_JWT_ADMIN_ROLES: service_role
      GOTRUE_DISABLE_SIGNUP: "false"
      GOTRUE_EXTERNAL_EMAIL_ENABLED: "true"
      GOTRUE_MAILER_AUTOCONFIRM: "true"
      API_EXTERNAL_URL: ${SITE_URL}

  # Realtime - Live updates via WebSocket
  realtime:
    image: supabase/realtime:v2.25.35
    container_name: glass-aero-realtime
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PORT: 4000
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: supabase_admin
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      DB_NAME: postgres
      DB_AFTER_CONNECT_QUERY: 'SET search_path TO _realtime'
      DB_ENC_KEY: supabaserealtime
      API_JWT_SECRET: ${JWT_SECRET}
      FLY_ALLOC_ID: fly123
      FLY_APP_NAME: realtime
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      ERL_AFLAGS: -proto_dist inet_tcp
      ENABLE_TAILSCALE: "false"
      DNS_NODES: "''"

  # Storage - File uploads
  storage:
    image: supabase/storage-api:v0.43.11
    container_name: glass-aero-storage
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      ANON_KEY: ${ANON_KEY}
      SERVICE_KEY: ${SERVICE_KEY}
      POSTGREST_URL: http://rest:3000
      PGRST_JWT_SECRET: ${JWT_SECRET}
      DATABASE_URL: postgres://supabase_storage_admin:${POSTGRES_PASSWORD}@db:5432/postgres
      FILE_SIZE_LIMIT: 52428800
      STORAGE_BACKEND: file
      FILE_STORAGE_BACKEND_PATH: /var/lib/storage
      TENANT_ID: stub
      REGION: stub
      GLOBAL_S3_BUCKET: stub
      ENABLE_IMAGE_TRANSFORMATION: "true"
      IMGPROXY_URL: http://imgproxy:8080
    volumes:
      - ./data/storage:/var/lib/storage

  # Kong API Gateway
  kong:
    image: kong:2.8.1
    container_name: glass-aero-kong
    restart: unless-stopped
    depends_on:
      - rest
      - auth
      - realtime
      - storage
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /kong/kong.yml
      KONG_DNS_ORDER: LAST,A,CNAME
      KONG_PLUGINS: request-transformer,cors,key-auth,acl
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
    volumes:
      - ./kong/kong.yml:/kong/kong.yml:ro
    ports:
      - "8300:8000"

  # Frontend (nginx)
  frontend:
    image: nginx:alpine
    container_name: glass-aero-frontend
    restart: unless-stopped
    depends_on:
      - kong
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "8080:80"
```

### Step 5: Create Kong Configuration

Create `C:\glass-aero-tracker\kong\kong.yml`:

```yaml
_format_version: "2.1"

services:
  - name: rest-v1
    url: http://rest:3000/
    routes:
      - name: rest-v1-route
        paths:
          - /rest/v1/
        strip_path: true

  - name: auth-v1
    url: http://auth:9999/
    routes:
      - name: auth-v1-route
        paths:
          - /auth/v1/
        strip_path: true

  - name: realtime-v1
    url: http://realtime:4000/socket/
    routes:
      - name: realtime-v1-route
        paths:
          - /realtime/v1/
        strip_path: true

  - name: storage-v1
    url: http://storage:5000/
    routes:
      - name: storage-v1-route
        paths:
          - /storage/v1/
        strip_path: true

plugins:
  - name: cors
    config:
      origins:
        - "*"
      methods:
        - GET
        - POST
        - PUT
        - PATCH
        - DELETE
        - OPTIONS
        - HEAD
      headers:
        - Authorization
        - Content-Type
        - Accept
        - apikey
        - x-client-info
        - Prefer
        - x-upsert
      exposed_headers:
        - Content-Range
        - X-Total-Count
      credentials: true
      max_age: 3600
```

### Step 6: Create Nginx Configuration

Create `C:\glass-aero-tracker\nginx\nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    client_max_body_size 50M;

    server {
        listen 80;
        server_name localhost;

        root /usr/share/nginx/html;
        index index.html;

        # Frontend static files
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Proxy REST API calls to Kong
        location /rest/v1/ {
            proxy_pass http://kong:8000/rest/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Proxy Auth calls to Kong
        location /auth/v1/ {
            proxy_pass http://kong:8000/auth/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Proxy Realtime WebSocket calls to Kong
        location /realtime/v1/ {
            proxy_pass http://kong:8000/realtime/v1/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400;
        }

        # Proxy Storage calls to Kong
        location /storage/v1/ {
            proxy_pass http://kong:8000/storage/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            client_max_body_size 50M;
        }
    }
}
```

### Step 7: Export Data from Source System

On the source server (your current production system), run:

#### Windows (PowerShell)

```powershell
# Export auth schema (includes users)
docker exec supabase-db pg_dump -U postgres -d postgres --schema=auth --no-owner --no-acl | Set-Content -Path "C:\glass-aero-tracker\sql\01-auth-schema.sql" -Encoding UTF8

# Export application data
docker exec supabase-db pg_dump -U postgres -d postgres --no-owner --no-acl `
  --table=public.app_settings `
  --table=public.bom_items `
  --table=public.hold_history `
  --table=public.parts_issuance `
  --table=public.production_parts `
  --table=public.production_stages `
  --table=public.repair_order_documents `
  --table=public.repair_orders `
  --table=public.stage_history `
  --table=public.subcomponents | Set-Content -Path "C:\glass-aero-tracker\sql\02-app-data.sql" -Encoding UTF8
```

#### Ubuntu/Linux (Bash)

```bash
# Export auth schema (includes users)
docker exec supabase-db pg_dump -U postgres -d postgres --schema=auth --no-owner --no-acl > /opt/glass-aero-tracker/sql/01-auth-schema.sql

# Export application data
docker exec supabase-db pg_dump -U postgres -d postgres --no-owner --no-acl \
  --table=public.app_settings \
  --table=public.bom_items \
  --table=public.hold_history \
  --table=public.parts_issuance \
  --table=public.production_parts \
  --table=public.production_stages \
  --table=public.repair_order_documents \
  --table=public.repair_orders \
  --table=public.stage_history \
  --table=public.subcomponents > /opt/glass-aero-tracker/sql/02-app-data.sql
```

**Important:** Edit `01-auth-schema.sql` and change:
```sql
CREATE SCHEMA auth;
```
to:
```sql
CREATE SCHEMA IF NOT EXISTS auth;
```

### Step 8: Create Initial Roles SQL

Create the roles initialization file:
- **Windows:** `C:\glass-aero-tracker\sql\00-init-roles.sql`
- **Ubuntu:** `/opt/glass-aero-tracker/sql/00-init-roles.sql`

```sql
-- Initialize roles for Supabase/GoTrue

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        CREATE ROLE supabase_auth_admin WITH LOGIN PASSWORD 'YourSecurePassword2026!' SUPERUSER;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin WITH LOGIN PASSWORD 'YourSecurePassword2026!' SUPERUSER;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin WITH LOGIN PASSWORD 'YourSecurePassword2026!' SUPERUSER;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN;
    END IF;
END
$$;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- Create storage schema
CREATE SCHEMA IF NOT EXISTS storage;
GRANT USAGE ON SCHEMA storage TO supabase_storage_admin, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin, service_role;
```

**Note:** Replace `YourSecurePassword2026!` with the same password from your `.env` file.

### Step 9: Copy Frontend Files

Copy all frontend files to the frontend directory:
- **Windows:** `C:\glass-aero-tracker\frontend\`
- **Ubuntu:** `/opt/glass-aero-tracker/frontend/`

**Files to copy:**
- All `.html` files (index.html, login.html, repair-orders.html, etc.)
- `js/` folder (all JavaScript files)

**Download vendor files for offline use:**

#### Windows (PowerShell)

```powershell
cd C:\glass-aero-tracker\frontend\vendor

# Download Supabase JS
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js" -OutFile "supabase.min.js"

# Download JsBarcode
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js" -OutFile "JsBarcode.all.min.js"

# Download Font Awesome CSS
Invoke-WebRequest -Uri "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" -OutFile "fontawesome.min.css"

# Create webfonts folder and download fonts
mkdir webfonts -Force
Invoke-WebRequest -Uri "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/webfonts/fa-solid-900.woff2" -OutFile "webfonts\fa-solid-900.woff2"
Invoke-WebRequest -Uri "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/webfonts/fa-regular-400.woff2" -OutFile "webfonts\fa-regular-400.woff2"

# Fix Font Awesome paths
$css = Get-Content fontawesome.min.css -Raw
$css = $css -replace '../webfonts/', 'webfonts/'
Set-Content fontawesome.min.css $css
```

#### Ubuntu/Linux (Bash)

```bash
cd /opt/glass-aero-tracker/frontend/vendor

# Download Supabase JS
curl -L "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js" -o supabase.min.js

# Download JsBarcode
curl -L "https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js" -o JsBarcode.all.min.js

# Download Font Awesome CSS
curl -L "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" -o fontawesome.min.css

# Create webfonts folder and download fonts
mkdir -p webfonts
curl -L "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/webfonts/fa-solid-900.woff2" -o webfonts/fa-solid-900.woff2
curl -L "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/webfonts/fa-regular-400.woff2" -o webfonts/fa-regular-400.woff2

# Fix Font Awesome paths
sed -i 's|\.\./webfonts/|webfonts/|g' fontawesome.min.css
```

### Step 10: Compile Tailwind CSS

Download the Tailwind CLI and compile a static CSS file.

#### Windows (PowerShell)

```powershell
cd C:\glass-aero-tracker

# Download Tailwind CLI
Invoke-WebRequest -Uri "https://github.com/tailwindlabs/tailwindcss/releases/download/v3.4.1/tailwindcss-windows-x64.exe" -OutFile "tailwindcss.exe"

# Create Tailwind config
@"
module.exports = {
  content: ["./frontend/**/*.html", "./frontend/**/*.js"],
  theme: {
    extend: {
      fontFamily: { 'outfit': ['Outfit', 'sans-serif'] },
      colors: {
        'glassAero': {
          'navy': '#0a1628', 'slate': '#1e293b', 'steel': '#334155',
          'sky': '#0ea5e9', 'gold': '#f59e0b', 'emerald': '#10b981',
        }
      }
    }
  },
  plugins: [],
}
"@ | Set-Content tailwind.config.js

# Create input CSS
@"
@tailwind base;
@tailwind components;
@tailwind utilities;
"@ | Set-Content input.css

# Compile
.\tailwindcss.exe -i input.css -o frontend\vendor\tailwind.min.css --minify
```

#### Ubuntu/Linux (Bash)

```bash
cd /opt/glass-aero-tracker

# Download Tailwind CLI (Linux version)
curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/download/v3.4.1/tailwindcss-linux-x64
chmod +x tailwindcss-linux-x64

# Create Tailwind config
cat > tailwind.config.js << 'EOF'
module.exports = {
  content: ["./frontend/**/*.html", "./frontend/**/*.js"],
  theme: {
    extend: {
      fontFamily: { 'outfit': ['Outfit', 'sans-serif'] },
      colors: {
        'glassAero': {
          'navy': '#0a1628', 'slate': '#1e293b', 'steel': '#334155',
          'sky': '#0ea5e9', 'gold': '#f59e0b', 'emerald': '#10b981',
        }
      }
    }
  },
  plugins: [],
}
EOF

# Create input CSS
cat > input.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# Compile
./tailwindcss-linux-x64 -i input.css -o frontend/vendor/tailwind.min.css --minify
```

### Step 11: Update HTML Files for Offline Use

In all HTML files, make these replacements:

**Change:**
```html
<script src="https://cdn.tailwindcss.com"></script>
```
**To:**
```html
<link rel="stylesheet" href="vendor/tailwind.min.css">
```

**Change:**
```html
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
```
**To:**
```html
<link rel="stylesheet" href="vendor/fontawesome.min.css">
```

**Change:**
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```
**To:**
```html
<script src="vendor/supabase.min.js"></script>
```

**Remove** any `<script>tailwind.config = { ... }</script>` blocks (no longer needed with pre-compiled CSS).

### Step 12: Update Supabase Configuration

Edit the Supabase configuration file:
- **Windows:** `C:\glass-aero-tracker\frontend\js\supabase-config.js`
- **Ubuntu:** `/opt/glass-aero-tracker/frontend/js/supabase-config.js`

Change the URL and key at the top:
```javascript
const SUPABASE_URL = 'http://192.168.1.100:8080';  // Server IP address
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE3OTk1MzU2MDB9.Z7TQV4VxWaN_eGuMgccr_8q55wyu2rjBQhlwU_w3xJE';
```

Replace the IP address with the actual server IP.

### Step 13: Start the Application

#### Windows (PowerShell)

```powershell
cd C:\glass-aero-tracker
docker compose up -d
```

#### Ubuntu/Linux (Bash)

```bash
cd /opt/glass-aero-tracker
docker compose up -d
```

Wait 60-90 seconds for all services to start, then verify:

```bash
docker compose ps
```

All 7 containers should show "Up" status.

### Step 14: Configure Firewall

#### Windows (PowerShell as Administrator)

```powershell
New-NetFirewallRule -DisplayName "Glass Aero Tracker (Port 8080)" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

#### Ubuntu/Linux (Bash)

```bash
# If using ufw (Ubuntu's default firewall)
sudo ufw allow 8080/tcp
sudo ufw reload

# Or if using firewalld
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### Step 15: Access the Application

Open a browser and go to:
```
http://SERVER-IP:8080
```

---

## Post-Deployment Tasks

### Create Admin User

If users can sign up through the login page, make a user an admin with:

```bash
docker exec -i glass-aero-db psql -U postgres -d postgres -c "UPDATE auth.users SET raw_app_meta_data = raw_app_meta_data || '{\"role\": \"admin\"}'::jsonb WHERE email = 'user@example.com';"
```

*(This command works the same on both Windows and Linux)*

### Verify Data Import

Check that data was imported correctly:

```bash
docker exec glass-aero-db psql -U postgres -d postgres -c "SELECT COUNT(*) as repair_orders FROM repair_orders;"
docker exec glass-aero-db psql -U postgres -d postgres -c "SELECT COUNT(*) as stages FROM production_stages;"
docker exec glass-aero-db psql -U postgres -d postgres -c "SELECT COUNT(*) as parts FROM production_parts;"
```

*(These commands work the same on both Windows and Linux)*

### Test Document Upload

1. Open a repair order
2. Try uploading a document
3. Verify it appears in the documents section

### Test Realtime Updates

1. Open the app in two browser windows
2. Make a change in one window
3. Verify it appears in the other window automatically

---

## Troubleshooting

### Check Container Status

```bash
docker compose ps
```

All containers should show "Up". If any show "Restarting", check logs.

*(This command works the same on both Windows and Linux)*

### Check Container Logs

```bash
# All logs
docker compose logs -f

# Specific service
docker compose logs -f rest
docker compose logs -f auth
docker compose logs -f realtime
docker compose logs -f storage
docker compose logs -f db
```

*(These commands work the same on both Windows and Linux)*

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized on API calls | JWT_SECRET mismatch | Ensure JWT_SECRET in .env matches the key used to sign ANON_KEY |
| Auth container keeps restarting | Auth schema not imported | Check 01-auth-schema.sql was created and has `IF NOT EXISTS` |
| Storage uploads fail | Storage admin role missing | Check 00-init-roles.sql includes supabase_storage_admin |
| Realtime not connecting | WebSocket proxy issue | Check nginx.conf has the realtime location block |
| Database connection refused | Wrong password | Ensure POSTGRES_PASSWORD matches in .env and 00-init-roles.sql |
| Page loads but no data | Browser cache | Hard refresh (Ctrl+Shift+R) or try incognito window |

### Restart Services

```bash
docker compose restart
```

*(This command works the same on both Windows and Linux)*

### Complete Reset (Start Fresh)

#### Windows (PowerShell)

```powershell
docker compose down
Remove-Item C:\glass-aero-tracker\data\postgres\* -Recurse -Force
Remove-Item C:\glass-aero-tracker\data\storage\* -Recurse -Force
docker compose up -d
```

#### Ubuntu/Linux (Bash)

```bash
docker compose down
sudo rm -rf /opt/glass-aero-tracker/data/postgres/*
sudo rm -rf /opt/glass-aero-tracker/data/storage/*
docker compose up -d
```

---

## Backup and Recovery

### Daily Backup Script

#### Windows

Create `C:\glass-aero-tracker\backup.ps1`:

```powershell
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "C:\glass-aero-tracker\backups"

if (!(Test-Path $backupDir)) { mkdir $backupDir }

# Backup database
docker exec glass-aero-db pg_dump -U postgres postgres | Set-Content "$backupDir\glass_aero_$date.sql" -Encoding UTF8

# Backup storage files
Copy-Item -Path "C:\glass-aero-tracker\data\storage" -Destination "$backupDir\storage_$date" -Recurse

# Keep last 30 days of database backups
Get-ChildItem $backupDir -Filter "*.sql" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item

# Keep last 7 days of storage backups
Get-ChildItem $backupDir -Directory -Filter "storage_*" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Recurse

Write-Host "Backup completed: $date"
```

#### Ubuntu/Linux

Create `/opt/glass-aero-tracker/backup.sh`:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/glass-aero-tracker/backups"

mkdir -p "$BACKUP_DIR"

# Backup database
docker exec glass-aero-db pg_dump -U postgres postgres > "$BACKUP_DIR/glass_aero_$DATE.sql"

# Backup storage files
cp -r /opt/glass-aero-tracker/data/storage "$BACKUP_DIR/storage_$DATE"

# Keep last 30 days of database backups
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete

# Keep last 7 days of storage backups
find "$BACKUP_DIR" -type d -name "storage_*" -mtime +7 -exec rm -rf {} +

echo "Backup completed: $DATE"
```

Make it executable:
```bash
chmod +x /opt/glass-aero-tracker/backup.sh
```

### Schedule Automatic Backup

#### Windows (Task Scheduler)

1. Open Task Scheduler
2. Create Basic Task → "Glass Aero Daily Backup"
3. Trigger: Daily at 2:00 AM
4. Action: Start a Program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File C:\glass-aero-tracker\backup.ps1`

#### Ubuntu/Linux (cron)

```bash
# Open crontab editor
crontab -e

# Add this line to run backup daily at 2:00 AM
0 2 * * * /opt/glass-aero-tracker/backup.sh >> /opt/glass-aero-tracker/backup.log 2>&1
```

### Restore from Backup

#### Windows (PowerShell)

```powershell
# Stop services
docker compose down

# Clear existing data
Remove-Item C:\glass-aero-tracker\data\postgres\* -Recurse -Force

# Start just the database
docker compose up -d db
Start-Sleep -Seconds 30

# Restore database
Get-Content C:\glass-aero-tracker\backups\glass_aero_YYYYMMDD_HHMMSS.sql | docker exec -i glass-aero-db psql -U postgres postgres

# Restore storage files
Copy-Item -Path "C:\glass-aero-tracker\backups\storage_YYYYMMDD_HHMMSS\*" -Destination "C:\glass-aero-tracker\data\storage\" -Recurse

# Start all services
docker compose up -d
```

#### Ubuntu/Linux (Bash)

```bash
# Stop services
docker compose down

# Clear existing data
sudo rm -rf /opt/glass-aero-tracker/data/postgres/*

# Start just the database
docker compose up -d db
sleep 30

# Restore database
cat /opt/glass-aero-tracker/backups/glass_aero_YYYYMMDD_HHMMSS.sql | docker exec -i glass-aero-db psql -U postgres postgres

# Restore storage files
cp -r /opt/glass-aero-tracker/backups/storage_YYYYMMDD_HHMMSS/* /opt/glass-aero-tracker/data/storage/

# Start all services
docker compose up -d
```

---

## Useful Commands Reference

These Docker commands work the same on both Windows and Linux:

```bash
# Start application
docker compose up -d

# Stop application
docker compose down

# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f rest

# Restart all services
docker compose restart

# Restart specific service
docker compose restart auth

# Check status
docker compose ps

# Connect to database
docker exec -it glass-aero-db psql -U postgres postgres

# Run SQL command
docker exec glass-aero-db psql -U postgres -d postgres -c "SELECT COUNT(*) FROM repair_orders;"
```

### Path Reference

| Item | Windows | Ubuntu/Linux |
|------|---------|--------------|
| Project Root | `C:\glass-aero-tracker` | `/opt/glass-aero-tracker` |
| Docker Compose | `C:\glass-aero-tracker\docker-compose.yml` | `/opt/glass-aero-tracker/docker-compose.yml` |
| Environment File | `C:\glass-aero-tracker\.env` | `/opt/glass-aero-tracker/.env` |
| Frontend Files | `C:\glass-aero-tracker\frontend\` | `/opt/glass-aero-tracker/frontend/` |
| SQL Init Scripts | `C:\glass-aero-tracker\sql\` | `/opt/glass-aero-tracker/sql/` |
| Database Data | `C:\glass-aero-tracker\data\postgres\` | `/opt/glass-aero-tracker/data/postgres/` |
| Storage Data | `C:\glass-aero-tracker\data\storage\` | `/opt/glass-aero-tracker/data/storage/` |
| Backups | `C:\glass-aero-tracker\backups\` | `/opt/glass-aero-tracker/backups/` |

---

## Services Reference

| Service | Container Name | Internal Port | External Port | Purpose |
|---------|---------------|---------------|---------------|---------|
| db | glass-aero-db | 5432 | 5435 | PostgreSQL database |
| rest | glass-aero-rest | 3000 | - | REST API |
| auth | glass-aero-auth | 9999 | - | Authentication |
| realtime | glass-aero-realtime | 4000 | - | WebSocket updates |
| storage | glass-aero-storage | 5000 | - | File uploads |
| kong | glass-aero-kong | 8000 | 8300 | API Gateway |
| frontend | glass-aero-frontend | 80 | 8080 | Web server |

---

## Support

For deployment assistance or issues during the 30-day support period:
- **Developer:** JCD Enterprises

---

*Document Version: 2.0 (Full deployment with Realtime and Storage)*  
*April 2026*
