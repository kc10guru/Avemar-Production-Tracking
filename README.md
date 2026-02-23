# Avemar Production Tracking

Aviation windshield repair/overhaul production tracking system for Avemar Group.

## Setup

### 1. Database Setup
Run the SQL schema in your Supabase SQL Editor:
- Open your Supabase dashboard
- Go to **SQL Editor**
- Paste and run the contents of `sql/schema.sql`
- This creates all 7 tables and seeds initial data (4 part numbers + 15 production stages)

### 2. GitHub Pages Deployment
1. Create a new GitHub repository: `Avemar-Production-Tracking`
2. Push this code to the repository
3. Enable GitHub Pages (Settings > Pages > Source: main branch)
4. Access at `https://kc10guru.github.io/Avemar-Production-Tracking`

## Architecture
- **Frontend:** HTML + vanilla JavaScript + Tailwind CSS (CDN)
- **Backend:** Supabase (PostgreSQL) at `https://avemar-db.duckdns.org`
- **Auth:** Supabase Auth (shared with Avemar CRM)
- **Hosting:** GitHub Pages

## Pages
| Page | Description |
|------|-------------|
| `index.html` | Production dashboard with stage pipeline cards |
| `login.html` | Authentication |
| `repair-orders.html` | Repair order list with filters |
| `new-repair-order.html` | Create new repair order |
| `repair-order-detail.html` | Single order view with stage progress |
| `inventory.html` | Subcomponent parts inventory |
| `bom.html` | Bill of materials manager |
| `settings.html` | Admin configuration |

## Production Stages
1. Receiving
2. Document Verification
3. Inspection
4. Disassembly
5. Cleaning
6. Polishing
7. Inspection (Post-Polish)
8. Heater Installation
9. Outer Glass Installation
10. Cleaning (Pre-Autoclave)
11. Autoclave
12. Testing
13. Final Inspection
14. Shipping
15. Delivery
