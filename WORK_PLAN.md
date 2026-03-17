# HACCP Mobile — Work Plan

> Updated: 2026-03-17
> Current version: 1.1

---

## Legend

| Status | Meaning |
|--------|---------|
| ✅ | Done |
| 🔲 | Not started |

---

## Phase 1 — Core (v1.0) ✅ COMPLETE

| # | Feature | Status |
|---|---------|--------|
| 1.1 | Auth (Login / Register / Setup / Logout) | ✅ |
| 1.2 | Dashboard (stats + quick actions) | ✅ |
| 1.3 | Checklists (templates, completion, sign-off) | ✅ |
| 1.4 | Checklist History | ✅ |
| 1.5 | Recipes (CRUD, active/inactive, dietary badges) | ✅ |
| 1.6 | Allergen Matrix (14 EU allergens + lookup) | ✅ |
| 1.7 | Menu Export (PDF/CSV) | ✅ |
| 1.8 | Daily Diary (aggregator + export) | ✅ |
| 1.9 | Incidents (CRUD, resolve/reopen) | ✅ |
| 1.10 | Suppliers (CRUD, manager-only) | ✅ |
| 1.11 | Team (members + invites) | ✅ |
| 1.12 | Notifications (list, read/unread) | ✅ |
| 1.13 | Documents (upload, categories, access control) | ✅ |
| 1.14 | AI Recipe Import (text/PDF/photo → Claude) | ✅ |
| 1.15 | GoRouter navigation + RBAC | ✅ |
| 1.16 | GitHub Pages deploy pipeline | ✅ |

---

## Phase 2 — SFBB Compliance (v1.1) ✅ COMPLETE

| # | Feature | Status |
|---|---------|--------|
| 2.1 | SFBB Category filter chips on Checklists | ✅ |
| 2.2 | Photo item type for checklists | ✅ |
| 2.3 | Deliveries (record + photos) | ✅ |

---

## Phase 3 — Essential Gaps (v1.2) 🔲 NEXT

| # | Feature | Priority | Effort | Description |
|---|---------|----------|--------|-------------|
| 3.1 | **Edit checklist template** | 🔴 Critical | M | Button exists, shows "Coming soon". Full edit flow needed |
| 3.2 | **Profile editing** | 🟡 High | S | Edit name, avatar for current user |
| 3.3 | **Business settings** | 🟡 High | S | Edit business name, address |
| 3.4 | **Checklist journal export (PDF)** | 🟡 High | M | Full checklist log with detailed per-item breakdown |
| 3.5 | **Delivery detail / edit** | 🟡 High | S | View/edit existing delivery record |

**Deliverable:** No dead-end screens, complete CRUD on all entities.

---

## Phase 4 — Notifications & Automation (v1.3) 🔲

| # | Feature | Priority | Effort | Description |
|---|---------|----------|--------|-------------|
| 4.1 | **Auto-notification generation** | 🟡 High | L | Overdue checklists, temp alerts, expiring documents |
| 4.2 | **Notification rules (manager config)** | 🟠 Medium | L | DB table exists. What triggers, who receives, when |
| 4.3 | **Push notifications (FCM)** | 🟠 Medium | L | Firebase Cloud Messaging for mobile |
| 4.4 | **Email notifications** | 🟠 Medium | M | Critical alerts via email |
| 4.5 | **Escalation logic** | 🟠 Medium | M | Overdue → remind → escalate to manager |

**Deliverable:** Proactive safety alerts instead of passive lists.

---

## Phase 5 — Polish & Advanced (v1.4) 🔲

| # | Feature | Priority | Effort | Description |
|---|---------|----------|--------|-------------|
| 5.1 | **Recipe photos** | 🟡 High | S | Upload photos to Supabase Storage (camera/gallery, like deliveries) |
| 5.2 | **Recipe versioning** | 🟠 Medium | M | Track changes over time, view previous versions |

**Deliverable:** Recipes fully featured with visual content and audit trail.

---

## Phase 6 — Production Launch 🔲

| # | Task | Priority | Effort | Description |
|---|------|----------|--------|-------------|
| 6.1 | **Apple Developer registration** | 🔴 Critical | — | Needed for TestFlight / App Store |
| 6.2 | **TestFlight build** | 🔴 Critical | M | First iOS beta for real testing |
| 6.3 | **Android build (Play Store)** | 🟡 High | M | APK / AAB for Android |
| 6.4 | **Security audit** | 🔴 Critical | M | Remove hardcoded keys, env vars, review RLS |
| 6.5 | **Error tracking (Sentry)** | 🟡 High | S | Crash reporting in production |
| 6.6 | **Performance testing** | 🟠 Medium | S | Large dataset stress test |
| 6.7 | **E2E tests** | 🟠 Medium | L | Integration tests for critical flows |

**Deliverable:** Production-ready application in App Store and Play Store.

---

## Effort Key

| Size | Meaning |
|------|---------|
| S | Small — < 1 hour |
| M | Medium — 1-3 hours |
| L | Large — 3-8 hours |
| XL | Extra Large — 1+ days |

---

## Recommended Next Actions

1. **Commit & tag v1.1** — Current session changes haven't been committed yet
2. **Deploy to GitHub Pages** — Push latest web build
3. **Start v1.2** — Edit checklist template (3.1) is the most visible gap
