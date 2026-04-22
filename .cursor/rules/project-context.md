# Glass Aero Production Tracking System - Project Context

This file provides comprehensive context for AI assistants working on this codebase. Read this entirely before making changes.

## Project Overview

This is a **production tracking system for windshield repair** built for Glass Aero. It tracks repair orders through a 15-stage workflow, manages inventory, handles bill of materials (BOM), and provides real-time updates across all users.

**Client:** Glass Aero (windshield repair company)
**Developer:** JCD Enterprises
**Deployment:** On-premises Docker stack on client's VM

---

## Architecture (CRITICAL - Read First)

### There Is No Backend Server

This is a **static frontend + Supabase stack**. There is NO Express, Node, Django, or custom backend server. The JavaScript in the browser talks directly to:

- **PostgREST** - Auto-generated REST API from PostgreSQL (`/rest/v1/...`)
- **GoTrue** - Supabase Auth for login/sessions (`/auth/v1/...`)
- **Realtime** - WebSocket for live updates (`/realtime/v1/...`)
- **Storage API** - File uploads (`/storage/v1/...`)

All "backend" logic lives in `js/supabase-config.js` which wraps Supabase client calls.

### Docker Containers (7 total)

| Container | Purpose | Internal Port |
|-----------|---------|---------------|
| glass-aero-db | PostgreSQL database | 5432 |
| glass-aero-rest | PostgREST API | 3000 |
| glass-aero-auth | GoTrue authentication | 9999 |
| glass-aero-realtime | WebSocket updates | 4000 |
| glass-aero-storage | File storage | 5000 |
| glass-aero-kong | API gateway | 8000 |
| glass-aero-frontend | nginx web server | 80 |

Users access the app at `http://SERVER:8080` (nginx), which proxies API calls to Kong.

### Key Files

| File | Purpose |
|------|---------|
| `js/supabase-config.js` | ALL database operations, the "backend" logic |
| `js/auth.js` | Authentication helpers, role checks |
| `js/repair-order-detail.js` | Complex stage advancement, BOM, holds |
| `deployment/docker-compose-full.yml` | Docker stack definition |
| `deployment/.env` | Environment variables (passwords, JWT, site URL) |
| `sql/` | Database migrations (run in Supabase SQL Editor) |

---

## Database Tables

| Table | Purpose |
|-------|---------|
| `repair_orders` | All work orders - customer, part, serial, stage, status, hold info, skipped_stages |
| `production_stages` | The 15 workflow stages with time limits |
| `production_parts` | Windshield part numbers (assemblies) |
| `stage_history` | Audit trail of every stage transition |
| `subcomponents` | Inventory items (parts/materials) |
| `bom_items` | Bill of Materials - which parts needed at which stage |
| `parts_issuance` | Record of parts issued to each repair order |
| `repair_order_documents` | Uploaded file metadata |
| `hold_history` | Hold/resume events with duration |
| `app_settings` | Configuration (business hours, timezone) |

---

## The 15 Production Stages

1. Check-In
2. Pre-Inspection  
3. **Inspection** (SPECIAL - see below)
4. Remove Hardware
5. Remove Glass
6. Prep Outer Frame
7. Prep Inner Frame
8. Heater Installation (can be skipped)
9. Outer Glass Installation (can be skipped)
10. Inner Glass Installation
11. Install Hardware
12. Seal and Cure
13. Final Inspection
14. Shipping
15. Delivered

### Stage 3 (Inspection) Is Special

At Stage 3, the inspector sees a **checklist** of stages 4-13 and unchecks any the windshield doesn't need. Skipped stages are stored in `repair_orders.skipped_stages` as a JSONB array. The system automatically jumps over skipped stages when advancing.

---

## Common Operations and How They Work

### Advancing a Stage

1. `loadBomPartsForStage()` checks if BOM items exist for this stage + part number
2. If yes, checkboxes shown in modal (pre-checked)
3. User confirms → `advanceStage()` runs
4. For each BOM part: `issuePart()` decrements `subcomponents.quantity_on_hand` and creates `parts_issuance` record
5. `stage_history` entry created with `exited_at` for old stage, new entry for new stage
6. If next stage is skipped, recursively advances to next non-skipped stage

### Going Back a Stage

1. `revertToPreviousStage()` called
2. `reversePartsForStage()` restores inventory for parts issued at current stage
3. Deletes `parts_issuance` records for that stage
4. Updates `stage_history` - removes current stage entry
5. If previous stage was skipped, recursively goes back further

### Changing Part Number (Edit Modal)

1. `reverseAllPartsForOrder()` - restores ALL issued parts to inventory
2. Deletes ALL `parts_issuance` records for the order
3. Looks up new BOM for new part number
4. Re-issues correct BOM parts for all completed stages (respecting skipped_stages)
5. Updates repair order with new part number

### Hold/Resume

- `holdRepairOrder()` sets `is_on_hold=true`, records reason, creates `hold_history` entry
- `resumeRepairOrder()` clears hold, calculates duration, closes history entry
- Held orders cannot advance or go back

### Business Hours

Time limits use business hours only (not wall clock). `calculateBusinessHours(start, end)` in `supabase-config.js` only counts hours within configured work hours. Settings stored in `app_settings` table.

---

## Known Issues and Solutions

### BOM Parts Issuing Multiple Times (FIXED)

**Symptom:** Same parts issued repeatedly when advancing through stages.
**Cause:** `loadBomPartsForStage()` wasn't clearing checkbox HTML when a stage had no BOM items.
**Fix:** Added `list.innerHTML = '';` when no BOM items exist (line ~449 in repair-order-detail.js).

### Browser Cache Issues

**Symptom:** Changes not appearing, functions undefined.
**Solution:** Hard refresh (Ctrl+Shift+R). All script tags have `?v=X` cache busters - increment the version number when making JS changes.

### Stage Time Showing Wrong Hours

**Symptom:** Units flagged as late over weekends.
**Cause:** Was using wall-clock hours instead of business hours.
**Fix:** `calculateBusinessHours()` function added, business hours configurable in Settings.

### Database Changes Not Taking Effect

**Symptom:** New columns or features not working.
**Cause:** SQL migration not run.
**Solution:** Check `sql/` folder for migration files. Run them in Supabase SQL Editor in order (filenames are prefixed for ordering).

---

## SQL Migrations (Run in Order)

These migrations must be run in Supabase SQL Editor for features to work:

1. `schema.sql` - Base schema (usually already done)
2. `add-hold-feature.sql` - Hold/resume functionality
3. `add-business-hours.sql` - Business hours settings, app_settings table
4. `add-inspection-checklist.sql` - skipped_stages column for inspection feature
5. `add-invoice-number.sql` - Invoice number field
6. `add-documents.sql` - Document upload support

---

## Deployment Notes

### Changing the Site URL/Port

If the server IP or port changes, update THREE places:
1. `deployment/.env` → `SITE_URL`
2. `deployment/docker-compose-full.yml` → `frontend` ports
3. `deployment/frontend/js/supabase-config.js` → `SUPABASE_URL`

Then restart: `docker compose down && docker compose up -d`

### Database Location on VM

- Windows: `C:\glass-aero-tracker\data\postgres\`
- Linux: `/opt/glass-aero-tracker/data/postgres/`

THIS IS THE CRITICAL DATA - back it up regularly.

### Backup Command

```bash
docker exec glass-aero-db pg_dump -U postgres postgres > backup.sql
```

---

## User Roles

- **Standard User:** View dashboard, create/edit orders, advance stages, manage inventory
- **Admin:** All above PLUS BOM config, Settings, Import, Delete, business hours

Admin role set via: `UPDATE auth.users SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}' WHERE email = 'user@example.com';`

---

## Testing Changes

1. Make changes to HTML/JS files
2. If database changes needed, create SQL migration in `sql/` folder
3. Test locally by opening HTML files or running a local server
4. Push to GitHub - GitHub Pages deploys automatically
5. Hard refresh browser (Ctrl+Shift+R) to bypass cache
6. If production, run any new SQL migrations in Supabase SQL Editor

---

## Troubleshooting Commands

```bash
# Check all containers running
docker compose ps

# View logs for specific service
docker compose logs -f rest
docker compose logs -f auth
docker compose logs -f db

# Restart everything
docker compose restart

# Connect to database directly
docker exec -it glass-aero-db psql -U postgres postgres

# Check repair order count
docker exec glass-aero-db psql -U postgres -c "SELECT COUNT(*) FROM repair_orders;"
```

---

## File Structure

```
├── index.html              # Dashboard
├── login.html              # Login page
├── repair-orders.html      # List all orders
├── new-repair-order.html   # Create order form
├── repair-order-detail.html # Order detail/advance/edit
├── scan.html               # Barcode scan page
├── inventory.html          # Inventory management
├── bom.html                # Bill of Materials (admin)
├── reports.html            # Production reports
├── import.html             # Excel import
├── settings.html           # System settings (admin)
├── js/
│   ├── supabase-config.js  # ALL database operations
│   ├── auth.js             # Authentication
│   ├── repair-order-detail.js # Stage advancement logic
│   ├── settings.js         # Settings page logic
│   ├── import.js           # Excel import logic
│   └── [page-specific].js  # Other page scripts
├── sql/                    # Database migrations
├── deployment/             # Docker deployment files
│   ├── docker-compose-full.yml
│   ├── .env.example
│   ├── kong/kong.yml
│   └── nginx/nginx.conf
└── .cursor/rules/          # This context file
```

---

## Contact

Developer: JCD Enterprises
Project: Glass Aero Production Tracking System
