# HACCP Mobile — Work Plan

> Updated: 2026-03-18
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

## Phase 3 — Design Overhaul (Maria) ✅ COMPLETE

| # | Feature | Status |
|---|---------|--------|
| 3.1 | Premium light design: warm cream palette, squircle cards | ✅ |
| 3.2 | New navigation: bottom bar + profile tab with avatar | ✅ |
| 3.3 | Menu screen with tabs (Recipes / Allergens) | ✅ |
| 3.4 | Profile screen with Sign Out, Documents, Diary, Notifications, Team | ✅ |
| 3.5 | Redesigned cards: checklists, recipes, incidents, deliveries | ✅ |
| 3.6 | SF Pro / Inter font system, richer color palette | ✅ |
| 3.7 | Dashboard redesign with daily diary on home | ✅ |

---

## Phase 4 — Essential Gaps (v1.2) 🔲 NEXT

| # | Feature | Priority | Effort | Description |
|---|---------|----------|--------|-------------|
| 4.1 | **Edit checklist template** | 🔴 Critical | M | Button exists, shows "Coming soon". Full edit flow needed |
| 4.2 | **Profile editing** | 🟡 High | S | Edit name, avatar for current user |
| 4.3 | **Business settings** | 🟡 High | S | Edit business name, address |
| 4.4 | **Checklist journal export (PDF)** | 🟡 High | M | Full checklist log with detailed per-item breakdown |
| 4.5 | **Delivery detail / edit** | 🟡 High | S | View/edit existing delivery record |

**Deliverable:** No dead-end screens, complete CRUD on all entities.

---

## Phase 5 — Notifications & Automation (v1.3) 🔲

| # | Feature | Priority | Effort | Description |
|---|---------|----------|--------|-------------|
| 5.1 | **Auto-notification generation** | 🟡 High | L | Overdue checklists, temp alerts, expiring documents |
| 5.2 | **Notification rules (manager config)** | 🟠 Medium | L | DB table exists. What triggers, who receives, when |
| 5.3 | **Push notifications (FCM)** | 🟠 Medium | L | Firebase Cloud Messaging for mobile |
| 5.4 | **Email notifications** | 🟠 Medium | M | Critical alerts via email |
| 5.5 | **Escalation logic** | 🟠 Medium | M | Overdue → remind → escalate to manager |

**Deliverable:** Proactive safety alerts instead of passive lists.

---

## Phase 6 — Polish & Advanced (v1.4) 🔲

| # | Feature | Priority | Effort | Description |
|---|---------|----------|--------|-------------|
| 6.1 | **Recipe photos** | 🟡 High | S | Upload photos to Supabase Storage (camera/gallery, like deliveries) |
| 6.2 | **Recipe versioning** | 🟠 Medium | M | Track changes over time, view previous versions |

**Deliverable:** Recipes fully featured with visual content and audit trail.

---

## Phase 7 — Production Launch 🔲

| # | Task | Priority | Effort | Description |
|---|------|----------|--------|-------------|
| 7.1 | **Apple Developer registration** | 🔴 Critical | — | Needed for TestFlight / App Store |
| 7.2 | **TestFlight build** | 🔴 Critical | M | First iOS beta for real testing |
| 7.3 | **Android build (Play Store)** | 🟡 High | M | APK / AAB for Android |
| 7.4 | **Security audit** | 🔴 Critical | M | Remove hardcoded keys, env vars, review RLS |
| 7.5 | **Error tracking (Sentry)** | 🟡 High | S | Crash reporting in production |
| 7.6 | **Performance testing** | 🟠 Medium | S | Large dataset stress test |
| 7.7 | **E2E tests** | 🟠 Medium | L | Integration tests for critical flows |

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

1. **Start v1.2** — Edit checklist template (4.1) is the most visible gap
2. **Profile editing (4.2)** — Screen exists but read-only, add edit capability
3. **Checklist journal PDF (4.4)** — Detailed export with per-item responses
