# Glass Aero Production Tracker
## Local Staging Setup (Windows 11 + Docker Desktop)

This guide walks through setting up a self-contained "offline" test deployment on your Windows 11 micro computer alongside your existing Supabase instance.

---

## Current Setup

- **Machine:** Windows 11 Pro micro computer
- **Docker:** Docker Desktop with existing Supabase containers
- **Goal:** Create a separate staging environment to test the offline deployment

---

## Overview

We'll create:
1. A **new Supabase stack** on different ports (so it doesn't conflict with your existing one)
2. A **copy of the frontend** configured to use the staging database
3. **Bundled offline dependencies** (Tailwind, Supabase JS, JsBarcode)

---

## Step 1: Create Staging Directory

Open PowerShell and run:

```powershell
# Create staging directory
mkdir C:\glass-aero-staging
cd C:\glass-aero-staging

# Create subdirectories
mkdir data\postgres
mkdir data\storage
mkdir frontend
mkdir frontend\vendor
mkdir frontend\js
mkdir sql
mkdir kong
mkdir nginx
```

---

## Step 2: Create Environment File

Create `C:\glass-aero-staging\.env`:

```env
# Database
POSTGRES_PASSWORD=staging-password-change-me

# JWT Secret (use this command to generate: openssl rand -base64 32)
# Or use this pre-generated one for testing:
JWT_SECRET=your-super-secret-jwt-token-for-staging-only

# Site URL (localhost for testing)
SITE_URL=http://localhost:3080

# Supabase API Keys
# These are for local testing only - generate new ones for production
# Anon key (public, limited access)
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1sb2NhbCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE5NTczNDUyMDB9.local-staging-anon-key

# Service key (admin access - keep secret)
SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1sb2NhbCIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE2NDE3NjkyMDAsImV4cCI6MTk1NzM0NTIwMH0.local-staging-service-key

# Secret key for realtime
SECRET_KEY_BASE=your-secret-key-base-for-realtime-staging
```

---

## Step 3: Create Docker Compose File

Create `C:\glass-aero-staging\docker-compose.yml`:

```yaml
version: "3.8"

name: glass-aero-staging

services:
  # PostgreSQL Database (port 5433 to avoid conflict)
  db:
    image: postgres:15-alpine
    container_name: glass-aero-staging-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: glass_aero
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./sql:/docker-entrypoint-initdb.d
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # PostgREST API (port 3001)
  rest:
    image: postgrest/postgrest:v12.0.2
    container_name: glass-aero-staging-rest
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PGRST_DB_URI: postgres://postgres:${POSTGRES_PASSWORD}@db:5432/glass_aero
      PGRST_DB_SCHEMAS: public,storage
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: ${JWT_SECRET}
      PGRST_DB_USE_LEGACY_GUCS: "false"
    ports:
      - "3001:3000"

  # GoTrue Authentication (port 9998)
  auth:
    image: supabase/gotrue:v2.143.0
    container_name: glass-aero-staging-auth
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD}@db:5432/glass_aero?sslmode=disable
      GOTRUE_SITE_URL: ${SITE_URL}
      GOTRUE_URI_ALLOW_LIST: "*"
      GOTRUE_JWT_SECRET: ${JWT_SECRET}
      GOTRUE_JWT_EXP: 3600
      GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated
      GOTRUE_DISABLE_SIGNUP: "false"
      GOTRUE_EXTERNAL_EMAIL_ENABLED: "true"
      GOTRUE_MAILER_AUTOCONFIRM: "true"
      API_EXTERNAL_URL: ${SITE_URL}
    ports:
      - "9998:9999"

  # Supabase Studio (optional - for DB management, port 3002)
  studio:
    image: supabase/studio:20240101-8c54ed8
    container_name: glass-aero-staging-studio
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      STUDIO_PG_META_URL: http://meta:8080
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      DEFAULT_ORGANIZATION_NAME: Glass Aero Staging
      DEFAULT_PROJECT_NAME: Production Tracker
      SUPABASE_URL: http://localhost:3080
      SUPABASE_PUBLIC_URL: http://localhost:3080
      SUPABASE_ANON_KEY: ${ANON_KEY}
      SUPABASE_SERVICE_KEY: ${SERVICE_KEY}
    ports:
      - "3002:3000"

  # Postgres Meta (required for Studio)
  meta:
    image: supabase/postgres-meta:v0.75.0
    container_name: glass-aero-staging-meta
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PG_META_PORT: 8080
      PG_META_DB_HOST: db
      PG_META_DB_PORT: 5432
      PG_META_DB_NAME: glass_aero
      PG_META_DB_USER: postgres
      PG_META_DB_PASSWORD: ${POSTGRES_PASSWORD}

  # Kong API Gateway (port 3080 - main entry point)
  kong:
    image: kong:3.4
    container_name: glass-aero-staging-kong
    restart: unless-stopped
    depends_on:
      - rest
      - auth
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
      - "3080:8000"

  # Frontend (nginx - port 8080)
  frontend:
    image: nginx:alpine
    container_name: glass-aero-staging-frontend
    restart: unless-stopped
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "8080:80"
```

---

## Step 4: Create Kong Configuration

Create `C:\glass-aero-staging\kong\kong.yml`:

```yaml
_format_version: "3.0"

services:
  - name: rest
    url: http://rest:3000
    routes:
      - name: rest-route
        paths:
          - /rest/v1
        strip_path: true

  - name: auth
    url: http://auth:9999
    routes:
      - name: auth-route
        paths:
          - /auth/v1
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
      headers:
        - Authorization
        - Content-Type
        - apikey
        - x-client-info
        - Prefer
      exposed_headers:
        - Content-Range
      credentials: true
      max_age: 3600
```

---

## Step 5: Create Nginx Configuration

Create `C:\glass-aero-staging\nginx\nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name localhost;

        root /usr/share/nginx/html;
        index index.html;

        # Frontend routes
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Proxy API calls to Kong
        location /rest/v1/ {
            proxy_pass http://kong:8000/rest/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /auth/v1/ {
            proxy_pass http://kong:8000/auth/v1/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

---

## Step 6: Export Data from Current Database

Connect to your existing Supabase and export the schema + data.

**Option A: Using Supabase Studio**
1. Open your existing Supabase dashboard
2. Go to SQL Editor
3. Run: `pg_dump` equivalent queries to export data

**Option B: Using pg_dump (recommended)**

In PowerShell, run against your existing Supabase container:

```powershell
# Find your existing Supabase DB container name
docker ps | findstr postgres

# Export schema and data (adjust container name as needed)
docker exec supabase-db pg_dump -U postgres -d postgres --schema=public --no-owner > C:\glass-aero-staging\sql\01-schema-and-data.sql
```

Or if your existing DB is accessible via network:

```powershell
# Using psql/pg_dump if installed locally
pg_dump -h localhost -p 5432 -U postgres -d postgres --schema=public --no-owner > C:\glass-aero-staging\sql\01-schema-and-data.sql
```

---

## Step 7: Prepare Auth Schema

Create `C:\glass-aero-staging\sql\00-auth-setup.sql`:

```sql
-- Create roles required by Supabase/PostgREST
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- Create auth schema for GoTrue
CREATE SCHEMA IF NOT EXISTS auth;

-- Basic auth tables (GoTrue will create the rest)
CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    encrypted_password TEXT,
    email_confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    raw_app_meta_data JSONB DEFAULT '{}'::jsonb,
    raw_user_meta_data JSONB DEFAULT '{}'::jsonb,
    is_super_admin BOOLEAN DEFAULT FALSE,
    role TEXT DEFAULT 'authenticated',
    aud TEXT DEFAULT 'authenticated'
);

-- Grant auth schema access
GRANT USAGE ON SCHEMA auth TO postgres, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO postgres, service_role;
```

---

## Step 8: Download Offline Dependencies

Open PowerShell and run:

```powershell
cd C:\glass-aero-staging\frontend\vendor

# Download Tailwind CSS (standalone build)
Invoke-WebRequest -Uri "https://cdn.tailwindcss.com/3.4.1" -OutFile "tailwind.js"

# Download Supabase JS
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js" -OutFile "supabase.min.js"

# Download JsBarcode
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js" -OutFile "JsBarcode.all.min.js"
```

---

## Step 9: Copy and Modify Frontend Files

Copy all frontend files from your project to the staging frontend folder:

```powershell
# Copy HTML files
Copy-Item "C:\Users\Jeff\OneDrive\Documents\JCD Enterprises\Avemar-Production-Tracking\*.html" -Destination "C:\glass-aero-staging\frontend\"

# Copy JS folder
Copy-Item "C:\Users\Jeff\OneDrive\Documents\JCD Enterprises\Avemar-Production-Tracking\js\*" -Destination "C:\glass-aero-staging\frontend\js\" -Recurse
```

---

## Step 10: Update Frontend for Offline + Staging

### 10.1 Update supabase-config.js

Edit `C:\glass-aero-staging\frontend\js\supabase-config.js`:

Change the first few lines:

```javascript
// Supabase Configuration for Glass Aero Production Tracking - STAGING
(function() {
  const SUPABASE_URL = 'http://localhost:8080';  // Nginx frontend with proxy
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1sb2NhbCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE5NTczNDUyMDB9.local-staging-anon-key';
```

### 10.2 Update HTML Files for Local Dependencies

For each HTML file, replace the CDN script tags. Example for `index.html`:

**Find these lines:**
```html
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

**Replace with:**
```html
<script src="vendor/tailwind.js"></script>
<script src="vendor/supabase.min.js"></script>
```

**For pages with JsBarcode, also replace:**
```html
<script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"></script>
```
**With:**
```html
<script src="vendor/JsBarcode.all.min.js"></script>
```

---

## Step 11: Start the Stack

```powershell
cd C:\glass-aero-staging
docker compose up -d
```

Watch the logs:
```powershell
docker compose logs -f
```

---

## Step 12: Verify Services

Check all containers are running:
```powershell
docker compose ps
```

You should see:
- glass-aero-staging-db (healthy)
- glass-aero-staging-rest
- glass-aero-staging-auth
- glass-aero-staging-kong
- glass-aero-staging-frontend
- glass-aero-staging-studio (optional)
- glass-aero-staging-meta

---

## Step 13: Access the Application

| Service | URL |
|---------|-----|
| **Frontend (main app)** | http://localhost:8080 |
| **Supabase Studio** | http://localhost:3002 |
| **API (direct)** | http://localhost:3080/rest/v1/ |
| **Auth (direct)** | http://localhost:3080/auth/v1/ |

---

## Step 14: Create Test User

Open Supabase Studio at http://localhost:3002 and:

1. Go to **Authentication** > **Users**
2. Click **Add User**
3. Enter email and password
4. To make admin, go to **SQL Editor** and run:

```sql
UPDATE auth.users 
SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb 
WHERE email = 'admin@glassaero.com';
```

---

## Step 15: Test Offline Mode

1. Disconnect from the internet (disable Wi-Fi/Ethernet)
2. Open http://localhost:8080
3. Log in and verify all features work:
   - Dashboard loads
   - Create repair order
   - Advance stages
   - View reports

---

## Ports Summary (Staging vs Existing)

| Service | Your Existing | Staging |
|---------|---------------|---------|
| PostgreSQL | 5432 | 5433 |
| PostgREST | 3000 | 3001 |
| GoTrue | 9999 | 9998 |
| Kong | 8000 | 3080 |
| Frontend | (GitHub Pages) | 8080 |
| Studio | 3000 | 3002 |

---

## Troubleshooting

### Container won't start
```powershell
docker compose logs [service-name]
```

### Database connection issues
```powershell
# Test direct connection
docker exec -it glass-aero-staging-db psql -U postgres -d glass_aero
```

### Auth not working
- Check GoTrue logs: `docker compose logs auth`
- Verify JWT_SECRET matches in .env and supabase-config.js

### CORS errors
- Check Kong logs: `docker compose logs kong`
- Verify kong.yml CORS settings

---

## Cleanup (When Done Testing)

```powershell
cd C:\glass-aero-staging
docker compose down

# To also remove data volumes:
docker compose down -v
```

---

## Next Steps

Once staging works:
1. Export the final configuration files
2. Document any changes needed
3. Package everything for client deployment
4. Schedule migration with client IT

---

*Last Updated: April 2026*
