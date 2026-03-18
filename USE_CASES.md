# HACCP Mobile — Use Cases

> Updated: 2026-03-18

---

## Actors

| Actor | Role | Description |
|-------|------|-------------|
| **Owner** | Business owner | Full access, manages business settings, team, templates |
| **Manager** | Kitchen/Restaurant manager | Same as owner except business creation |
| **Chef** | Head Chef / Sous Chef | Recipes, checklists, incidents |
| **Kitchen Staff** | Line cook, prep cook | Checklists, incidents (limited) |
| **Front of House** | Waiter, host | Checklists, allergen lookup, incidents |

---

## 1. Authentication & Onboarding

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-1.1 | **Register new account** — Enter email + password, create account | Any | ✅ |
| UC-1.2 | **Login** — Email + password authentication | Any | ✅ |
| UC-1.3 | **Create new business** — After registration, set up business name + address | New user | ✅ |
| UC-1.4 | **Join team via invite** — Use invite token to join existing business | New user | ✅ |
| UC-1.5 | **Logout** — Sign out from profile screen | Any | ✅ |
| UC-1.6 | **Edit profile** — Change name, upload avatar | Any | 🔲 v1.2 |
| UC-1.7 | **Edit business settings** — Change business name, address | Owner | 🔲 v1.2 |

---

## 2. Dashboard

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-2.1 | **View daily overview** — See stats: checklists done, open incidents, team size, recipes count | Any | ✅ |
| UC-2.2 | **Quick actions** — Navigate to key sections from dashboard | Any | ✅ |
| UC-2.3 | **View daily diary on home** — See today's completed checklists and incidents | Any | ✅ |

---

## 3. Checklists

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-3.1 | **View assigned checklists** — See list filtered by user's role with status badges (Pending / Completed / Awaiting Sign-off / Signed Off) | Any | ✅ |
| UC-3.2 | **Filter checklists by SFBB category** — Use category chips (Cleaning, Cooking, Chilling, Cross-Contamination, Management, Training, General) | Any | ✅ |
| UC-3.3 | **Complete checklist** — Fill in tick, yes/no, temperature, text, and photo items; submit responses | Any | ✅ |
| UC-3.4 | **Upload photo evidence** — Take photo or select from gallery as checklist response (e.g., fridge temperature display, cleaning evidence) | Any | ✅ |
| UC-3.5 | **Temperature validation** — System flags out-of-range temperatures automatically | System | ✅ |
| UC-3.6 | **Sign off checklist** — Supervisor reviews and signs completed checklist | Manager/Owner | ✅ |
| UC-3.7 | **Create checklist template** — Define items, types, frequency, assigned roles, supervisor role, SFBB category | Manager/Owner | ✅ |
| UC-3.8 | **Edit checklist template** — Modify existing template items, roles, frequency | Manager/Owner | 🔲 v1.2 |
| UC-3.9 | **Activate/Deactivate checklist** — Toggle template visibility | Manager/Owner | ✅ |
| UC-3.10 | **View checklist history** — See past completions with all responses, flagged items, photo thumbnails, sign-off status | Manager/Owner | ✅ |
| UC-3.11 | **Export checklist journal (PDF)** — Full log with per-item breakdown across all checklists | Manager/Owner | 🔲 v1.2 |

---

## 4. Recipes

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-4.1 | **Browse recipes** — View list grouped by category with dietary badges (Vegetarian, Vegan, GF, DF) | Any | ✅ |
| UC-4.2 | **View recipe detail** — See ingredients, allergens, cooking instructions, method, temperature, time | Any | ✅ |
| UC-4.3 | **Create recipe** — Add recipe with ingredients (linked to allergen database), cooking info, instructions | Chef+ | ✅ |
| UC-4.4 | **Edit recipe** — Modify existing recipe | Chef+ | ✅ |
| UC-4.5 | **Deactivate/Delete recipe** — Remove from active menu | Chef+ | ✅ |
| UC-4.6 | **AI import recipe** — Paste text, upload PDF, or take photo → Claude API extracts structured recipe | Chef+ | ✅ |
| UC-4.7 | **Upload recipe photo** — Add photo from camera/gallery | Chef+ | 🔲 v1.4 |
| UC-4.8 | **View recipe version history** — See how recipe changed over time | Chef+ | 🔲 v1.4 |

---

## 5. Menu & Allergens

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-5.1 | **View allergen matrix** — See grid of recipes × 14 EU allergens with emoji badges | Any | ✅ |
| UC-5.2 | **Check allergens for customer** — Look up which allergens a specific recipe contains (front-of-house scenario: customer asks "does this dish contain nuts?") | Front of House | ✅ |
| UC-5.3 | **Export menu (PDF/CSV)** — Generate menu document with categories, dietary labels, and optional allergen columns | Manager/Owner | ✅ |

---

## 6. Daily Diary

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-6.1 | **Review day's activity** — See all completed checklists and reported incidents for a specific date | Any | ✅ |
| UC-6.2 | **Navigate between days** — Browse forward/backward through dates | Any | ✅ |
| UC-6.3 | **Export diary report (PDF/CSV)** — Generate report for date range with selectable sections | Manager/Owner | ✅ |

---

## 7. Incidents & Complaints

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-7.1 | **Report incident** — Log complaint or incident with description and action taken | Any | ✅ |
| UC-7.2 | **Filter incidents** — View All / Open / Resolved incidents | Any | ✅ |
| UC-7.3 | **Edit incident** — Update description, action taken, follow-up | Manager/Owner | ✅ |
| UC-7.4 | **Resolve incident** — Mark as resolved with resolution notes | Manager/Owner | ✅ |
| UC-7.5 | **Reopen incident** — Change resolved incident back to open | Manager/Owner | ✅ |
| UC-7.6 | **Record follow-up** — Document "How to stop this happening again" | Manager/Owner | ✅ |

---

## 8. Deliveries

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-8.1 | **Record delivery** — Log received delivery with supplier, temperature, notes | Any | ✅ |
| UC-8.2 | **Attach delivery photos** — Take photos of invoices, product labels, or condition (multi-photo) | Any | ✅ |
| UC-8.3 | **View delivery list** — Browse past deliveries with supplier name, date, temperature, photo count | Any | ✅ |
| UC-8.4 | **View/Edit delivery detail** — See full delivery record with photos, edit notes | Any | 🔲 v1.2 |

---

## 9. Suppliers

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-9.1 | **View suppliers** — See list with contact info, goods supplied, delivery days | Any | ✅ |
| UC-9.2 | **Add supplier** — Create new supplier record | Manager/Owner | ✅ |
| UC-9.3 | **Edit supplier** — Update contact details, goods, delivery days | Manager/Owner | ✅ |
| UC-9.4 | **Delete supplier** — Remove supplier record | Manager/Owner | ✅ |

---

## 10. Team Management

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-10.1 | **View team members** — See list with role badges | Any | ✅ |
| UC-10.2 | **Invite team member** — Send invite via email + assigned role → generates join token | Manager/Owner | ✅ |

---

## 11. Documents

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-11.1 | **Upload document** — Upload PDF, JPG, DOCX, XLSX with category (certificate, license, policy, etc.) | Manager/Owner | ✅ |
| UC-11.2 | **Browse documents** — View list with search and category filter | Any (by access level) | ✅ |
| UC-11.3 | **View document details** — See metadata, download, manage access | Any (by access level) | ✅ |
| UC-11.4 | **Set access level** — Configure who can see document (all, managers only, owner only, custom) | Manager/Owner | ✅ |
| UC-11.5 | **Set expiry date** — Mark document with expiration date (e.g., food hygiene certificate) | Manager/Owner | ✅ |

---

## 12. Notifications

| # | Use Case | Actor | Status |
|---|----------|-------|--------|
| UC-12.1 | **View notifications** — See list of read/unread notifications | Any | ✅ |
| UC-12.2 | **Mark as read** — Tap notification to mark as read | Any | ✅ |
| UC-12.3 | **Auto-generate notifications** — System creates alerts for overdue checklists, temp violations, expiring docs | System | 🔲 v1.3 |
| UC-12.4 | **Push notifications** — Receive alerts on device even when app is closed | System | 🔲 v1.3 |
| UC-12.5 | **Email critical alerts** — Send email for high-priority safety issues | System | 🔲 v1.3 |
| UC-12.6 | **Configure notification rules** — Manager sets up what triggers alerts and who receives them | Manager/Owner | 🔲 v1.3 |

---

## Key Scenarios (Real-World Usage)

### Morning Opening (Kitchen Staff)
1. Open app → Dashboard shows today's pending checklists
2. Complete "Opening Checks" checklist: tick fridge temps, take photo of thermometer
3. If temperature is out of range → system flags it, staff logs incident
4. Record morning delivery: select supplier, enter product temp, photo invoice

### Lunch Service (Front of House)
1. Customer asks about allergens → open Allergen Matrix
2. Search for specific dish → see all 14 allergen categories at a glance
3. Confirm dish is safe for customer's allergy

### End of Day (Manager)
1. Review Dashboard → check all checklists completed
2. Sign off completed checklists (supervisor sign-off)
3. Check open incidents → resolve any from today
4. View Daily Diary → confirm everything is logged
5. Export diary as PDF for records

### Weekly Review (Owner)
1. Browse checklist history → verify compliance
2. Review resolved incidents → check follow-up actions
3. Export checklist journal PDF → file for EHO inspection
4. Check expiring documents → renew certificates

### New Recipe (Chef)
1. Take photo of recipe card → AI Import extracts ingredients and instructions
2. Review parsed recipe → adjust allergens and cooking details
3. Save → automatically appears in menu with dietary labels
4. Front of House immediately sees updated allergen info

### New Staff Onboarding (Manager)
1. Invite new team member (email + role)
2. Staff receives token → registers → joins business
3. Appears on team list with correct role
4. Can immediately see assigned checklists
