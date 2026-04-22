# Statement of Work
## Glass Aero Production Tracker — On-Premises Migration

---

**Document Version:** 1.0  
**Date:** April 2026  
**Prepared By:** JCD Enterprises  
**Prepared For:** Glass Aero

---

## 1. Project Overview

### 1.1 Purpose

This Statement of Work (SOW) defines the scope, deliverables, timeline, and responsibilities for migrating the Glass Aero Production Tracker from its current hosted environment to Glass Aero's internal on-premises infrastructure.

### 1.2 Background

Glass Aero currently uses the Production Tracker application hosted on external infrastructure (GitHub Pages frontend, developer-hosted Supabase backend). Glass Aero has requested migration to a fully self-contained deployment on their internal servers, enabling offline operation with no external dependencies.

### 1.3 Objectives

- Deploy all application components on Glass Aero infrastructure
- Eliminate external dependencies (CDN, cloud services)
- Migrate existing data from current system
- Ensure system operates fully within internal network
- Transfer operational knowledge to Glass Aero IT staff

---

## 2. Scope of Work

### 2.1 In Scope

| Item | Description |
|------|-------------|
| **Infrastructure Setup** | Deploy Docker environment with all required services (PostgreSQL, PostgREST, GoTrue, Realtime, Storage, Kong, nginx) |
| **Frontend Deployment** | Deploy static frontend files with bundled offline dependencies |
| **Database Migration** | Export existing data and import into new on-premises database |
| **Configuration** | Configure all services for internal network operation |
| **User Migration** | Recreate user accounts and role assignments |
| **SSL Setup** | Configure HTTPS using client-provided or self-signed certificates |
| **Backup Configuration** | Set up automated daily database backups |
| **Testing** | Verify all functionality works correctly post-migration |
| **Documentation** | Provide system administration guide |
| **Training** | Remote training session for IT staff (up to 2 hours) |
| **Support** | 30 days post-migration support |

### 2.2 Out of Scope

| Item | Notes |
|------|-------|
| Server hardware procurement | Client responsibility |
| Operating system installation | Client responsibility |
| Docker installation | Can be included if needed (see optional items) |
| Network/firewall configuration | Client IT responsibility |
| Active Directory/LDAP integration | Not currently supported; can be quoted separately |
| Custom feature development | Separate engagement |
| On-site work | Remote deployment; on-site available at additional cost |

### 2.3 Optional Add-Ons

| Item | Description | Cost |
|------|-------------|------|
| Docker installation assistance | Remote assistance installing Docker on client server | $200 |
| On-site deployment | Travel to client site for deployment | $1,500 + travel |
| Extended support (per month) | Additional months of support beyond 30 days | $500/month |
| Custom SSL certificate setup | Obtain and configure publicly-trusted certificate | $300 |

---

## 3. Deliverables

| # | Deliverable | Format |
|---|-------------|--------|
| 1 | Docker Compose configuration files | YAML files |
| 2 | Frontend application files (offline-ready) | HTML, JS, CSS |
| 3 | Database schema and seed data | SQL files |
| 4 | Environment configuration template | .env file |
| 5 | Kong API gateway configuration | YAML file |
| 6 | Nginx reverse proxy configuration | conf file |
| 7 | Backup script | Shell/PowerShell script |
| 8 | System Administration Guide | PDF/Word document |
| 9 | Deployed and tested system | Running on client infrastructure |
| 10 | User accounts configured | Admin and standard users created |

---

## 4. Client Responsibilities

Glass Aero agrees to provide:

| Responsibility | Details |
|----------------|---------|
| **Server** | Virtual or physical server meeting minimum requirements (4 cores, 8GB RAM, 100GB SSD) |
| **Operating System** | Ubuntu 22.04 LTS or Windows Server 2019+ installed and accessible |
| **Remote Access** | SSH/RDP access to server for deployment |
| **Docker** | Docker and Docker Compose installed (or request installation assistance) |
| **Network** | Internal DNS entry or hosts file configuration for application URL |
| **Firewall** | Ports 80/443 accessible from internal network |
| **SSL Certificate** | (Optional) Internal CA certificate or approval for self-signed |
| **User List** | List of users to create with email addresses and role assignments |
| **IT Contact** | Designated IT staff member available during deployment |
| **Testing** | End-user testing and sign-off within acceptance period |

---

## 5. Timeline

### 5.1 Project Schedule

| Phase | Duration | Activities |
|-------|----------|------------|
| **Phase 1: Preparation** | 1-2 days | Export current data, prepare configuration files, bundle offline dependencies |
| **Phase 2: Deployment** | 1 day | Deploy to client server, configure services, import data |
| **Phase 3: Testing** | 1-2 days | Functional testing, user acceptance testing |
| **Phase 4: Training & Handoff** | 1 day | IT training session, documentation review, go-live |
| **Phase 5: Support** | 30 days | Post-migration support period |

**Total Project Duration:** 5-7 business days (excluding support period)

### 5.2 Key Milestones

| Milestone | Target |
|-----------|--------|
| Server access provided | Day 1 |
| Docker stack deployed | Day 2 |
| Data migration complete | Day 3 |
| User acceptance testing complete | Day 4-5 |
| Go-live | Day 5-6 |
| Support period ends | Day 35-37 |

---

## 6. Acceptance Criteria

The project will be considered complete when:

1. **Application Accessible** — Production Tracker loads from internal URL
2. **Authentication Works** — Users can log in with migrated credentials
3. **Data Migrated** — All existing repair orders, inventory, and BOM data present
4. **Core Functions Verified** — The following work correctly:
   - Create new repair order
   - Advance repair order through stages
   - Parts automatically issued from BOM
   - View dashboard with accurate counts
   - Upload and download documents
   - Generate weekly report
   - Print barcode label
5. **Offline Operation** — System functions with no internet connectivity
6. **Backups Configured** — Automated backup script runs successfully
7. **IT Training Complete** — Client IT staff trained on administration

---

## 7. Pricing

### 7.1 Migration Services

| Item | Amount |
|------|--------|
| On-Premises Migration (as described in Scope) | $2,500 |

*This is the migration/deployment service fee only. Software license fee is separate.*

### 7.2 Software License

| Option | Amount |
|--------|--------|
| **Option A:** One-Time License | $13,000 |
| **Option B:** License + Support Retainer | $13,000 + $500/month |
| **Option C:** License + Hourly Support | $13,000 + $75/hour as needed |

*See Software License Agreement for full terms.*

### 7.3 Total Investment (Option A Example)

| Component | Amount |
|-----------|--------|
| Software License | $13,000 |
| Migration Services | $2,500 |
| **Total** | **$15,500** |

### 7.4 Payment Terms

| Milestone | Amount | Due |
|-----------|--------|-----|
| License Fee | $13,000 | Upon signing |
| Migration Fee | $2,500 | Upon go-live acceptance |

---

## 8. Support

### 8.1 Included Support (30 Days)

During the 30-day post-migration support period:

- Bug fixes for migration-related issues
- Configuration adjustments
- Assistance with user account management
- Email support with 24-hour response time
- Up to 2 hours of remote troubleshooting calls

### 8.2 Ongoing Support Options

After the initial 30-day period, support is available via:

| Option | Terms |
|--------|-------|
| **Monthly Retainer** | $500/month — includes priority support, up to 5 hours of modifications, rollover hours |
| **Hourly** | $75/hour — billed monthly for work performed |

---

## 9. Assumptions

This SOW is based on the following assumptions:

1. Client server meets minimum hardware requirements
2. Remote access to server will be provided within 2 business days of project start
3. Docker and Docker Compose are installed or client requests installation assistance
4. No custom feature development is required
5. Existing data volume is under 10,000 repair orders
6. Single server deployment (not high-availability cluster)
7. Client IT staff available for coordination during deployment
8. Standard business hours (9 AM - 6 PM EST) for deployment work

---

## 10. Change Management

Any changes to the scope defined in this SOW will be handled as follows:

1. Client submits change request in writing
2. JCD Enterprises evaluates impact on timeline and cost
3. Change order provided with revised terms
4. Work proceeds upon written approval of change order

---

## 11. Limitation of Liability

- JCD Enterprises is not responsible for data loss due to client infrastructure failures
- Maximum liability is limited to fees paid under this SOW
- Client is responsible for maintaining backups after handoff
- See Software License Agreement for additional terms

---

## 12. Signatures

**JCD Enterprises**

Name: _______________________________

Signature: _______________________________

Date: _______________________________

---

**Glass Aero**

Name: _______________________________

Title: _______________________________

Signature: _______________________________

Date: _______________________________

---

*This Statement of Work is subject to the terms of the Software License Agreement between the parties.*
