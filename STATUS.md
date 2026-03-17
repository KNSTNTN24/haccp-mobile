# HACCP Mobile App — Status Tracker

## Legend: ✅ Done | 🟡 Partial | ❌ Not Started

---

## 1. Auth & User Management
- ✅ Login screen (email/password)
- ✅ Register screen (with invite token support)
- ✅ Setup screen (create business or join by invite)
- ✅ Auth state management (Riverpod)
- ✅ Role-based access (Owner, Manager, Chef, Kitchen Staff, Front-of-House)
- ✅ Auto-redirect (logged in → dashboard, not logged → login)

## 2. Dashboard
- ✅ Stats cards (checklists, recipes, incidents, team, notifications)
- ✅ Today's status chips (opening/closing/diary)
- ✅ Quick action buttons
- ❌ Recent activity feed

## 3. Checklists
- ✅ List checklists filtered by role
- ✅ Fill/complete checklist (tick, yes/no, temperature, text inputs)
- ✅ Submit creates completion + responses in Supabase
- ✅ Temperature validation (out-of-range flagging)
- ✅ Create new checklist template (manager/owner only)
- ❌ Edit existing checklist template
- ❌ Delete/deactivate checklist template
- ❌ Checklist completion history (view past submissions)
- ❌ Default SFBB checklists (pre-built opening/closing/cleaning)
- ❌ Cleaning schedule builder

## 4. Recipes
- ✅ List recipes grouped by category
- ✅ Recipe detail view (allergens, ingredients, instructions, cooking info)
- ✅ Create new recipe with ingredients and allergens
- ✅ Edit existing recipe
- ✅ Delete/deactivate recipe
- ✅ Dietary badges (Vegetarian, Vegan, GF, DF) on cards and detail view
- ❌ Recipe photos upload
- ❌ Recipe versioning

## 5. Menu & Allergens
- ✅ Allergen matrix (recipes × 14 allergens)
- ✅ Allergen badges with emojis and colors
- ✅ Auto-calculation of allergens from ingredients
- ✅ Menu export PDF/CSV with dietary labels and optional allergens
- ❌ Menu builder (organize recipes into menu, activate/deactivate)
- ❌ Quick allergen lookup for front-of-house staff
- ❌ Allergen change alerts when recipe is modified

## 6. Daily Diary
- ✅ Date selector (navigate days)
- ✅ Aggregates checklist completions + incidents per day
- ✅ PDF/CSV export for date range
- ❌ Link to completed checklists as evidence
- ❌ Notes/problems log per day

## 7. Incidents & Complaints
- ✅ List incidents with filter tabs (All/Open/Resolved)
- ✅ Create incident via FAB (type, description, action taken)
- ✅ Edit incident
- ✅ Follow-up field ("How to stop this happening again")
- ✅ Incident status tracking (open/resolved) + resolve/reopen

## 8. Suppliers
- ✅ Supplier list with contact info, goods, delivery days
- ✅ Add new supplier via bottom sheet
- ✅ Edit existing supplier
- ✅ Delete supplier
- ❌ Supplier approval tracking

## 9. Team
- ✅ Team members list with role badges
- ✅ Invite team member (email + role → generate token)
- ❌ Edit team member role
- ❌ Remove team member
- ❌ Staff training records (per SFBB)
- ❌ First-day training checklist

## 10. Notifications
- ✅ Notification list (read/unread)
- ✅ Mark as read on tap
- ❌ Notification rules configuration
- ❌ Push notifications
- ❌ Email notifications
- ❌ Auto-reminders (overdue tasks, temperature alerts)

## 11. AI Recipe Import
- ✅ Text input mode (paste recipe text)
- ✅ PDF upload mode (upload recipe PDF, max 10 MB)
- ✅ Optional video URL field (saved with recipe for reference)
- ✅ Supabase Edge Function (import-recipe) with Claude API integration
- ✅ Recipe preview card before saving
- 🟡 401 JWT error on web — needs debugging (auth token not passed to Edge Function?)
- ❌ Auto-allergen tagging refinement

## 12. Reports & Export
- ✅ PDF/CSV export diary (date range, section selection)
- ✅ PDF/CSV export menu (dietary labels, optional allergens)
- ❌ PDF export checklists
- ❌ 4-weekly review summary
- ❌ Recurring issue detection

## 13. Settings & Profile
- ❌ User profile editing
- ❌ Business settings
- ❌ Notification preferences

---

## Priority TODO (Next Steps)

### High Priority
1. **Fix AI Import 401** — debug JWT auth for Edge Function calls from web
2. **Edit checklist template** — edit existing (button exists, shows "Coming soon")
3. **Menu Builder** — activate/deactivate recipes in menu, categories
4. **Logout button** — currently no way to sign out

### Medium Priority
5. **Staff training records** — track SFBB training per staff member
6. **Quick allergen lookup** — search by allergen for front-of-house
7. **Recipe photo upload** — camera/gallery integration
8. **4-weekly review** — auto-generated summary with action items
9. **Profile editing** — change name, avatar
10. **Business settings** — edit address, name

### Low Priority (Phase 2)
11. **Push notifications** — Firebase Cloud Messaging
12. **PDF export checklists** — separate checklist export
13. **Notification rules** — configurable auto-reminders
14. **Default SFBB checklists** — pre-built templates
15. **Cleaning schedule** — dedicated builder

---

## Tech Notes
- Flutter + Dart, Material Design
- Supabase backend (shared with web app)
- Riverpod 3.x state management
- GoRouter navigation
- GitHub Pages web deploy: https://knstntn24.github.io/haccp-mobile/
- Web app (Vercel): https://haccp-app-nine.vercel.app
- Supabase project: rszrggreuarvodcqeqrj
