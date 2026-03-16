# Glass Aero Production Tracking System
## Development Report

**Project:** Aviation Windshield Repair/Overhaul Production Tracking System
**Client:** Glass Aero (formerly Avemar Group)
**Development Period:** February 23, 2026 – March 12, 2026 (18 days)
**Total Commits:** 28
**Status:** Active Development

---

## 1. Executive Summary

The Glass Aero Production Tracking System is a web-based application built to manage the end-to-end workflow of aviation windshield repair and overhaul operations. The system tracks repair orders through an 18-stage production process, manages parts inventory and bills of materials, provides real-time dashboards, and generates operational reports. The application is hosted on GitHub Pages with a self-hosted Supabase (PostgreSQL) backend.

---

## 2. Technology Stack

| Component       | Technology                                    |
|-----------------|-----------------------------------------------|
| Frontend        | HTML, vanilla JavaScript, Tailwind CSS (CDN)  |
| Backend/DB      | Supabase (PostgreSQL) — self-hosted            |
| Authentication  | Supabase Auth with role-based access control  |
| Hosting         | GitHub Pages                                   |
| Version Control | Git / GitHub                                   |

---

## 3. Application Pages

| Page                     | Purpose                                         |
|--------------------------|--------------------------------------------------|
| Dashboard                | Production pipeline overview with stage cards    |
| Login                    | Secure authentication                            |
| Repair Orders            | Searchable/filterable list of all repair orders  |
| New Repair Order         | Create new windshield repair work orders         |
| Repair Order Detail      | Single order view with stage progress and actions|
| Inventory                | Subcomponent parts inventory management          |
| Bill of Materials (BOM)  | BOM configuration per windshield part number     |
| Reports                  | Operational and production reports               |
| Import                   | Bulk import of repair orders via Excel upload    |
| Settings                 | Admin configuration (parts, stages, hours)       |

---

## 4. Database Schema

The system uses 10 database tables:

1. **production_parts** — Windshield part numbers (King Air and CRJ variants)
2. **production_stages** — 18-step production workflow definition
3. **repair_orders** — Core repair order records with status tracking
4. **stage_history** — Audit trail of stage transitions with timestamps
5. **subcomponents** — Repair materials inventory (parts, quantities, reorder points)
6. **bom_items** — Bill of materials linking windshield parts to subcomponents per stage
7. **parts_issuance** — Tracks parts issued to specific repair orders
8. **repair_order_documents** — File uploads linked to repair orders
9. **hold_history** — Records of work stoppages with reasons and durations
10. **app_settings** — Configurable application settings (business hours, etc.)

---

## 5. Development Timeline

### Phase 1: Foundation (February 23, 2026)

- **Initial project setup** — Created repository, established project structure
- **Core pages built** — Dashboard, login, repair orders list, new repair order form, repair order detail, inventory, BOM, and settings pages
- **Database schema** — Designed and deployed 8 core tables with Row Level Security
- **Authentication** — Implemented Supabase Auth with session management
- **Dashboard** — Production pipeline visualization with stage cards showing unit counts
- **Stage progression** — Ability to advance repair orders through production stages
- **BOM auto-issuance** — Automatic parts issuance based on bill of materials when advancing stages
- **Document uploads** — File attachment capability at any production stage
- **Stage reversion** — Ability to move repair orders back to previous stages with inventory reversal
- **UI refinements** — Fixed dropdown styling, dashboard scrolling, background colors

### Phase 2: BOM and Reporting (February 23–27, 2026)

- **BOM bug fix** — Corrected issue where parts were duplicated when advancing through stages without BOM items
- **Reports page** — Built comprehensive reporting with production throughput, inventory projections, and delivery tracking
- **Inventory improvements** — Changed low stock calculations to show projected shortages based on in-work units
- **Invoice tracking** — Added invoice number field to repair orders
- **Historical data import** — SQL scripts to import existing Vertex repair order data

### Phase 3: Production Controls (March 3–4, 2026)

- **Hold/Resume feature** — Added ability to place repair orders on hold with reason tracking, visual indicators (red pulsing), hold history, and dashboard hold counts
- **Edit repair orders** — Post-creation editing of all repair order fields including part number changes with automatic BOM reversal and re-issuance
- **Part number change logic** — Comprehensive flow: reverse all issued parts, restore inventory, fetch new BOM, re-issue for completed stages
- **Edit windshield part numbers** — Settings page capability to modify existing part configurations
- **Business hours tracking** — Stage duration calculations based on configurable business hours (9 AM–6 PM Mon–Fri EST) instead of wall-clock time, with settings page for adjustment
- **Inspection checklist** — Inspector selects which subsequent stages are needed based on inspection results; system automatically skips unselected stages and adjusts inventory projections
- **Delete repair orders** — Admin function with full cascade cleanup (reverse parts, delete history, remove documents)
- **Sequential RO numbers** — Changed from random to sequential format (RO-YYYYMMDD-0001)
- **Bulk import** — Excel template download, file upload, validation, and batch import of repair orders
- **Cache management** — Added version query parameters to all script tags to prevent browser caching issues on GitHub Pages

### Phase 4: Access Control and Rebranding (March 11–12, 2026)

- **Company rebranding** — Changed all references from "Avemar Group" to "Glass Aero" across all pages, scripts, and documentation
- **Role-based access control** — Implemented admin/standard user roles using Supabase Auth `app_metadata`
  - Standard users: Dashboard, Repair Orders, Inventory, Reports
  - Admin users: All pages plus BOM, Settings, Import, and Delete functions
- **Admin-restricted features** — BOM tab, Settings tab, Import button, and Delete button hidden from standard users with server-side guard on page access
- **New windshield part numbers** — Added King Air (101-384025) and CRJ (NP139321, 601R33033) part number families
- **Production workflow update** — Replaced 15-stage process with new 18-stage workflow per customer requirements:
  - Combined old Receiving, Document Verification, and Inspection into single Receiving stage
  - Combined old Heater Installation and Outer Glass Installation into Interlayer/Heater/Sensor Install
  - Added new stages: Removal of Conductive Coating, P1 Autoclave, Fiber Glass Installation, Retainer Installation, Peripheral Edge Sealant, Weather Sealant, Final Pics
  - Inspection checklist moved from Stage 3 to Stage 1
  - BOM remapping for existing King Air parts

---

## 6. Current Production Stages (18-Step Workflow)

| Stage | Name                                | Role       | Time Limit |
|-------|-------------------------------------|------------|------------|
| 1     | Receiving Inspection                | Receiving  | 2 hrs      |
| 2     | Disassembly                         | Shop Floor | 24 hrs     |
| 3     | Removal of Conductive Coating       | Shop Floor | 24 hrs     |
| 4     | P1 Autoclave *(skippable)*          | Shop Floor | 48 hrs     |
| 5     | Cleaning PRE-CAT3/4                | Shop Floor | 16 hrs     |
| 6     | Interlayer, Heater, Sensor Install  | Shop Floor | 24 hrs     |
| 7     | Autoclave                           | Shop Floor | 48 hrs     |
| 8     | Testing                             | Quality    | 24 hrs     |
| 9     | Cleaning PRE-Fiber Glass            | Shop Floor | 16 hrs     |
| 10    | Fiber Glass Installation            | Shop Floor | 24 hrs     |
| 11    | Retainer Installation               | Shop Floor | 24 hrs     |
| 12    | Polishing                           | Shop Floor | 24 hrs     |
| 13    | Peripheral Edge Sealant PRC         | Shop Floor | 24 hrs     |
| 14    | Weather Sealant PRC                 | Shop Floor | 24 hrs     |
| 15    | Cleaning                            | Shop Floor | 16 hrs     |
| 16    | Final Pics                          | Quality    | 8 hrs      |
| 17    | Final Inspection                    | Quality    | 16 hrs     |
| 18    | Shipping                            | Receiving  | 8 hrs      |

---

## 7. Supported Windshield Part Numbers

### King Air Series (101-384025)
- 101-384025-21 through -24 — King Air Windshield Assemblies

### CRJ Main Windshield (NP139321)
- NP139321-1, -2, -5, -6, -9 through -18
- Odd dash numbers = Left Hand (LH), Even = Right Hand (RH)

### CRJ Side Windows (601R33033)
- 601R33033-3, -4, -11, -12, -19, -20, -23, -24, -29, -30
- Odd dash numbers = Left Hand (LH), Even = Right Hand (RH)

---

## 8. Key Features Summary

- **Real-time dashboard** with production pipeline visualization
- **18-stage production workflow** with configurable time limits
- **Inspection checklist** allowing inspectors to customize the repair path per unit
- **Automatic stage skipping** based on inspection results
- **Bill of Materials** with automatic parts issuance and inventory deduction
- **Projected inventory** calculations accounting for all in-work units
- **Hold/Resume** with reason tracking and visual indicators
- **Business hours** time tracking (configurable work schedule and timezone)
- **Document attachments** at any production stage
- **Bulk import** via Excel template
- **Role-based access control** (Admin vs Standard users)
- **Sequential RO numbering** (RO-YYYYMMDD-XXXX)
- **Edit and delete** repair orders with full inventory reversal
- **Reports** with production throughput, inventory projections, and delivery metrics

---

## 9. File Structure

```
Glass Aero Production Tracking/
├── index.html                  # Dashboard
├── login.html                  # Authentication
├── repair-orders.html          # Repair order list
├── new-repair-order.html       # Create repair order
├── repair-order-detail.html    # Single order detail
├── inventory.html              # Parts inventory
├── bom.html                    # Bill of materials
├── reports.html                # Reports
├── import.html                 # Bulk import
├── settings.html               # Admin settings
├── js/
│   ├── supabase-config.js      # Database layer (all API calls)
│   ├── auth.js                 # Authentication and RBAC
│   ├── repair-order-detail.js  # Order detail logic
│   ├── repair-orders.js        # Order list logic
│   ├── new-repair-order.js     # New order form logic
│   ├── inventory.js            # Inventory page logic
│   ├── bom.js                  # BOM page logic
│   ├── reports.js              # Reports logic
│   ├── import.js               # Import logic
│   └── settings.js             # Settings logic
├── sql/
│   ├── schema.sql              # Core database schema
│   ├── add-hold-feature.sql    # Hold/resume migration
│   ├── add-business-hours.sql  # Business hours settings
│   ├── add-inspection-checklist.sql  # Skipped stages column
│   ├── add-documents.sql       # Document storage
│   ├── add-invoice-number.sql  # Invoice field
│   ├── update-stages-v2.sql    # 18-stage workflow migration
│   ├── add-np139321-parts.sql  # CRJ main windshield parts
│   ├── add-np139321-side-windows.sql  # CRJ side window parts
│   ├── add-601r33033-parts.sql # CRJ side window parts
│   ├── add-admin-role.md       # Admin role setup guide
│   └── import-vertex-orders.sql # Historical data import
└── README.md
```

---

## 10. Development Effort

### Working Sessions (from git commit timestamps)

| Date   | Time Range          | Session Duration |
|--------|---------------------|-----------------|
| Feb 23 | 4:56 PM – 9:25 PM  | ~4.5 hours      |
| Feb 27 | 1:20 PM – 7:04 PM  | ~5.75 hours     |
| Mar 3  | 8:19 PM – 8:48 PM  | ~0.5 hours      |
| Mar 4  | 6:16 PM – 8:20 PM  | ~2 hours        |
| Mar 11 | 7:44 AM – 8:12 AM  | ~0.5 hours      |
| Mar 12 | 9:27 PM – 9:39 PM  | ~0.25 hours     |

**Tracked commit time: ~13.5 hours**

Commits capture only when code was pushed. Additional time was spent on planning, requirements discussion, testing, troubleshooting, Supabase SQL migrations, and UI verification between commits.

**Estimated total development effort: 20–25 hours**

---

## 11. Deployment

- **Repository:** GitHub (`kc10guru/Avemar-Production-Tracking`)
- **Live URL:** `https://kc10guru.github.io/Avemar-Production-Tracking`
- **Database:** Self-hosted Supabase at `https://avemar-db.duckdns.org`
- **Updates:** Push to `main` branch triggers automatic GitHub Pages deployment

---

*Report generated March 12, 2026*
