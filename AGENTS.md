# Glass Aero Production Tracking - AI Assistant Context

> **IMPORTANT:** Read `.cursor/rules/project-context.md` for full technical details.

## Quick Reference for AI Assistants

### What This Project Is

A windshield repair tracking system with:
- 15-stage production workflow
- Real-time dashboard
- Inventory/BOM management
- Document uploads
- Barcode scanning

### Architecture (No Custom Backend!)

**Static HTML/JS frontend → Supabase stack (PostgREST, GoTrue, Realtime, Storage) → PostgreSQL**

All "backend" logic is in `js/supabase-config.js`. There is NO Express, Node, Django, etc.

### Key Files to Know

| File | What It Does |
|------|-------------|
| `js/supabase-config.js` | ALL database operations - read this first |
| `js/repair-order-detail.js` | Stage advancement, BOM issuance, holds |
| `deployment/docker-compose-full.yml` | Docker container definitions |
| `sql/*.sql` | Database migrations |

### Stage 3 (Inspection) Is Special

Inspector selects which stages to skip. Skipped stages stored in `repair_orders.skipped_stages` JSONB array. System auto-jumps over them.

### When Making Changes

1. Edit HTML/JS files directly
2. If database changes needed → create SQL migration in `sql/`
3. Increment cache buster version (`?v=X`) on script tags
4. Test with hard refresh (Ctrl+Shift+R)
5. Push to GitHub → auto-deploys via GitHub Pages
6. Run SQL migrations in Supabase SQL Editor if needed

### Common Issues

| Problem | Solution |
|---------|----------|
| Function undefined | Hard refresh (Ctrl+Shift+R), check cache buster version |
| New feature not working | Run the SQL migration from `sql/` folder |
| Parts issued multiple times | Bug was fixed - ensure `list.innerHTML = '';` exists in loadBomPartsForStage |
| Wrong time calculations | System uses business hours from app_settings table |

### Database Tables

`repair_orders`, `production_stages`, `production_parts`, `stage_history`, `subcomponents`, `bom_items`, `parts_issuance`, `hold_history`, `app_settings`, `repair_order_documents`

### Docker Commands

```bash
docker compose ps              # Check status
docker compose logs -f rest    # View API logs
docker compose restart         # Restart all
docker exec -it glass-aero-db psql -U postgres postgres  # Connect to DB
```

---

For complete documentation, see:
- `.cursor/rules/project-context.md` - Full technical context
- `Glass Aero Production Tracker - System Overview.docx` - Comprehensive overview
- `Glass Aero Production Tracker - On-Premises Deployment Guide.md` - Deployment steps
- `Glass Aero Production Tracker - User Guide.md` - End user documentation
