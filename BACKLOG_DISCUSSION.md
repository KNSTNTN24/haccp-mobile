# HACCP Mobile — Backlog Discussion

> Status: Waiting for Maria's feedback
> Date: 2026-03-18
> Participants: Konstantin, Claude

---

## Agreed Priorities

| Version | Features | Status |
|---------|----------|--------|
| **v1.2** | Reports screen (date range, checklist filter, email, PDF), Dashboard redesign (tasks/team tasks/incidents/notifications), Edit profile (avatar/nickname), Edit checklist template, Cocktail categories, Delivery detail view/edit | Planned |
| **v1.3** | Check-in/out ("who's on site"), Prep lists (checklist type linked to recipes), Push notifications, Recipe scaling (portions/ingredient weight), Clean menu PDF/HTML export with allergens | Planned |
| **v1.4** | AI Training sheets from active recipes, Shopping lists (generated from recipes + portions), Recipe photos & versioning, KBJU estimation via AI (with disclaimer) | Planned |
| **v1.5+** | Wine card from label photos (AI Vision), Embeddable menu for website (HTML/iframe) | Nice-to-have |
| **Skip** | Auto-publish to Instagram/Google/Uber Eats, Fancy design templates for social media | Not feasible / out of scope |

---

## Discussion Notes

### 1. Reports Screen — v1.2 ✅ Agreed
- Separate screen, not inside Daily Diary
- Date range picker + multi-select checklists
- Full per-item breakdown PDF
- Email from app (share_plus or direct SMTP)
- Keep filters simple: date range + checklist selection, don't overcomplicate

### 2. Menu Export — v1.3 ⚠️ Limited scope
- Clean PDF with allergens (A4, print-ready) — YES
- HTML page (one template, embeddable) — YES
- Instagram/Google Business formatting — NO (different product)
- CSV for POS import — already exists

### 3. Recipe Auto-Scaling — v1.3 ✅ Agreed
- Proportional recalculation by portions or ingredient weight
- Simple math, easy implementation
- Caveat: doesn't work perfectly for baking/spices (90% use cases fine)
- UI: slider for portions + manual weight input on recipe detail

### 4. KBJU / Calories — v1.4 ⚠️ Via AI only
- No custom nutrient database (too expensive to maintain)
- Use Claude API to estimate from ingredient list
- Show as "estimated values" with disclaimer
- Legal risk if displayed on public menu — internal use only

### 5. Cocktail Menu — v1.2-1.3 ✅ Easy win
- Recipes are recipes, cocktails are just a category
- Add categories: Beverages / Cocktails
- Optional fields: base spirit, glass type, garnish
- Allergens still apply (dairy, eggs, gluten in beer)

### 6. Wine Card from Photos — v1.5+ 🔥 Cool but niche
- Claude Vision can extract: name, grape, region, vintage, ABV
- Same pattern as AI Recipe Import
- Low priority — small restaurants have 10-20 wines, easier to type manually

### 7. Auto-Publish Menu Everywhere — ❌ Skip
- Each platform has different CMS/API (WordPress, Squarespace, Wix)
- Instagram requires Meta Business API approval — too much hassle
- Google Business menu API is restricted
- Deliveroo/Uber Eats have no open API for small integrators
- Realistic alternative: HTML embed code for website only

### 8. Staff Avatars, Nicknames, Mood Emoji — v1.2 (profile) + v1.3 (mood)
- Avatar + nickname as part of Edit Profile — v1.2
- Mood emoji at check-in — v1.3 (tied to check-in/out feature)
- Gamification increases adoption — people open app to "see who's here"
- Don't overdo it — not a social network

### 9. AI Training Lists — v1.4 🔥 Killer feature
- Unique selling point — no competitor does this
- Data already exists: recipes with methods, temps, allergens
- Possible outputs: cooking methods summary, allergen training sheet, temp control sheet
- Quality depends on recipe data quality
- UI: "Generate Training Sheet" → pick topic → AI generates PDF

### 10. Check-in / Check-out — v1.3 ✅ Simple & useful
- Not time tracking, just "who's on site"
- Button on dashboard: "I'm here" / "I'm leaving"
- Team list shows who's checked in
- Manager dashboard shows avatars + emoji of on-site staff

### 11. Prep Lists — v1.3-1.4 ✅ Core kitchen tool
- Implement as checklist type "Prep List"
- Fields: recipe link, quantity, unit, done checkbox
- Without covers/bookings data = manual list (still useful)
- Could auto-generate from selected recipes in future

### 12. Shopping Lists — v1.4 ✅ Logical extension
- Select recipes + portions → generate consolidated ingredient list
- Group by supplier (if ingredients linked to suppliers)
- Real chefs order by experience/par levels, but useful as starting point

### 13. Dashboard Redesign — v1.2 ✅ Agreed
- One dashboard for all roles (manager sees extra "Team Tasks" block)
- Blocks: My Tasks (progress), Team Tasks (manager+, by role, with avatars), Open Incidents, Notifications
- Everything else → bottom nav / "More" menu
- Don't build two separate dashboards

---

## Monetization Strategy

### Revenue Models (ranked by priority)

#### 1. Freemium (Primary) ✅ Agreed
- **Free tier:** 1 business, 3 users, 5 checklists, basic recipes, no export, no photos
- **Pro tier (£25-39/мес):** Unlimited users/checklists, AI Import, photo evidence, PDF/CSV export, email reports, deliveries
- **Enterprise/Franchise (£99-199/мес per location):** Multi-location dashboard, template push, cross-location reports — v2.0+
- **Price positioning:** Cheaper than Trail (£38/site), Navitas (£129), FoodDocs ($84) — but with more integrated functionality
- **Reality check:** UK has ~100K restaurants, realistic 2-5% freemium conversion. Need 500+ paying users for sustainability

#### 2. Grants & Partnerships ✅ Do now, in parallel
- **Innovate UK Smart Grants** — up to £500K, HACCP + AI = good fit
- **UK Shared Prosperity Fund (UKSPF)** — local council digital business support
- **FSA Partnership** — endorsement from Food Standards Agency = best possible marketing (free). Top priority even without money
- **Local Enterprise Partnerships (LEPs)** — "helping SMEs digitalize"
- **Prince's Trust / Start Up Loans** — if founders qualify
- **Minority business grants (MSDUK, Black Business Fund)** — "lowering barriers for new restaurateurs"
- Grants = runway for development, not a business model. But FSA endorsement alone is worth more than money

#### 3. AI Training Modules with CPD Accreditation 🔥 Unique
- AI generates personalized training materials from restaurant's own recipes/checklists
- Quiz at the end → CPD certificate stored in Documents
- CPD accreditation costs £277/year (up to 30 courses) — low barrier
- Charge £5-10 per completion, or include in Pro tier
- **No competitor does this** — Navitas sells training separately at £129/мес
- Does NOT replace mandatory Level 2/3 qualifications — complementary
- Combine with affiliate links to Highfield/Virtual College for regulated qualifications

#### 4. Training Provider Collaboration ✅ Distribution channel
- **Affiliate/Referral (immediate):** In-app "Book Level 2 Course" links to partners (Virtual College, High Speed Training). Revenue: 10-20% commission (~£1.50-5/sale). Tiny revenue but adds user value
- **White-label embedded training (6-12 мес):** Partner provides course content via API, we provide distribution. Revenue share 30-50%. Pitch: "we bring X restaurants, each hiring 3-5/year, all need Level 2"
- **Sell THROUGH training providers (3-6 мес):** Trainers already sell to restaurants. Bundle: "Buy Level 2 for 5 staff → get HACCP app 6 months free." Growth hack, not revenue
- **Key insight:** Navitas is the only competitor bundling training + software at £129/мес. We can do the same at £25/мес with AI = killer positioning

#### 5. Supplier Lead Generation ⚠️ Later, with scale
- Opt-in marketplace: "Find suppliers near you"
- Only viable at 1000+ restaurants — suppliers won't pay for 50 users
- Must be opt-in to preserve trust (compliance tool = trust is everything)
- GDPR considerations for business data sharing
- Not before Phase 2 (6-12 months, 200+ users)

#### 6. POS Company Partnership / Exit ⚠️ Keep in mind
- Square, Toast, Lightspeed, Zettle — all expanding ecosystems, need compliance module
- Options: acquisition, white-label license, API integration
- Need 500-1000 active restaurants to start conversation
- Trail already integrated with some POS; FoodDocs too
- Don't build business around this — build user base first, POS companies will come
- CSV export for POS compatibility = already a correct step

#### 7. Franchise Tier 🔥 Best long-term revenue
- Franchise owners pay most, churn least (compliance is mandatory)
- Need: multi-location dashboard, template push, cross-location reporting
- This is v2.0+ — serious architectural work (multi-tenancy hierarchy)
- Enterprise sales cycle: demos, pilots, security reviews
- Competitors in this space: Trail, Navitas, Safefood360
- Prove PMF with single-location first, then pitch franchisors with real data

### Models explicitly rejected ❌
- **Auto-publish to Instagram/Google/Uber Eats** — each platform has different API, not feasible
- **Selling user data to suppliers** — kills trust, compliance tool credibility depends on trust
- **Building a full LMS (Learning Management System)** — different product, stay in your lane

---

## Distribution & Growth Channels

### Phase 1: Free channels (now → 6 months)

| Channel | How | Expected impact |
|---------|-----|-----------------|
| **FSA outreach** | Contact FSA for endorsement/listing as recommended digital tool | High — if FSA recommends, restaurants download organically |
| **EHO referrals** | Environmental Health Officers see app during inspections → recommend to restaurants | Medium — slow but high-trust |
| **Google/App Store SEO** | Keywords: "SFBB app", "food safety checklist UK", "restaurant HACCP" | Medium — SFBB+ already ranks but has limited features |
| **Word of mouth** | Existing users recommend to other restaurant owners | Slow but highest quality leads |

### Phase 2: Student viral channel (with v1.4 training module)

| Aspect | Details |
|--------|---------|
| **Pitch to student** | "Free Food Safety training + CPD certificate. Show employers you're ready to work in hospitality" |
| **Value for student** | CPD certificate, allergen lookup (useful on shift), personal task view |
| **How student drives adoption** | Bottom-up: student uses app at work → manager sees digital checklists are faster than paper → manager subscribes to Pro |
| **Distribution channels** | University job boards (Handshake), Student Union partnerships, NUS (7M+ students), TikTok/Insta content ("How to get hired at a restaurant"), Indeed/Reed targeting "part-time kitchen" |
| **Realistic conversion** | Out of 1000 students, ~20-50 introduce app to their restaurant, ~5-10 restaurants convert to Pro |
| **Critical assessment** | Students don't pay. Students have zero influence on software purchasing decisions. Bottom-up adoption works in tech companies (Slack, Figma) but restaurant owners may not listen to barback. However: FREE acquisition channel + great PR story for grants ("helping students get employed") |
| **Decision** | Don't build product for students. But when training module ships (v1.4), promote through student channels as free growth hack |

### Phase 3: Paid/partnership channels (6-12 months, 200+ users)

| Channel | How | Expected impact |
|---------|-----|-----------------|
| **Training provider bundles** | "Buy Level 2 for staff → get HACCP app free for 6 months" | Medium — leverages existing sales relationships |
| **Restaurant association partnerships** | UKHospitality, BII (British Institute of Innkeepers) | Medium — credibility + distribution |
| **Google Ads** | Target "restaurant compliance software UK" | Expensive but measurable |
| **Content marketing** | Blog: "How to prepare for EHO inspection", "SFBB digital guide" | SEO long-game |

### Phase 4: Enterprise channels (12-18 months, 500+ users)

| Channel | How | Expected impact |
|---------|-----|-----------------|
| **POS partnerships** | Integration with Square/Toast → co-marketing | High — access to their merchant base |
| **Franchise direct sales** | Outbound to franchise HQs | High revenue per deal, long sales cycle |
| **Industry events** | Restaurant & Bar Show, Hospitality Innovation Expo | Networking + demos |

---

## Competitive Landscape Summary

### Market size
- Global HACCP software: $781M (2022) → $1.24B (2030), CAGR ~6%
- Restaurant food safety compliance: $1.2B (2024) → $3.4B (2033), CAGR 12%
- UK food safety training: estimated £50-100M/year (online courses)

### Key competitors

| Player | Revenue | Customers | Price | Strength | Weakness |
|--------|---------|-----------|-------|----------|----------|
| **SafetyCulture** | ~$161M | 25K+ paying | $24/seat/mo | Scale, 100K templates, unicorn ($2.5B) | Generic — not restaurant-specific, no recipes/allergens |
| **Trail** | Private | Costa, Wagamama, BrewDog, Gail's | £38/site/mo | UK hospitality leader, AI Copilot, 1500 integrations | No recipes, no menu, no allergens. Targets chains, expensive for independents |
| **FoodDocs** | Private | 1,200+ | $84-250/mo | AI HACCP plan generation, fast setup | Expensive, no recipes/allergens, more manufacturing than restaurant |
| **Navitas** | Private | 13K+ businesses | £129/mo | Training + software bundle, IoT sensors, EHP consultants | Expensive, mixed reviews, rigid checklists |
| **Jolt** | Private | Smoothie King, Jimmy John's, Marriott | ~$100/site/mo | Operations + scheduling + labels, offline mode | US-centric, dated UI, no recipes/allergens/AI |
| **SFBB+** | Private | Thousands | £5/mo | Cheapest, based on FSA framework | Bare minimum — just diary + temps, no checklists/recipes/team/AI |

### Our unique positioning
**Only app combining kitchen management (recipes, allergens, menu) + food safety compliance (checklists, incidents, deliveries) + AI (recipe import, training generation) in one product.**

Target: UK independent restaurants (1-3 locations) where Trail is too expensive and SFBB+ is too basic.

Price sweet spot: £15-25/мес.

### Key risks
1. Trail adds recipes/allergens — they have resources, client base, and AI Copilot
2. SafetyCulture releases restaurant-specific template pack
3. FSA builds their own free digital tool (unlikely but possible)
4. Highfield Qualifications (£49M revenue, 70% market share in food safety quals) — dominant in training, potential competitor if they build software

### Training market players (potential partners)

| Player | Revenue | Scale | Role |
|--------|---------|-------|------|
| **Highfield Qualifications** | ~£49M | 350K learners/yr, 70% UK market share, Ofqual regulated | Awarding body — partner for Level 2/3 certification |
| **Virtual College** | Private | 4.5M+ learners, 300+ courses | E-learning provider — affiliate/white-label partner |
| **High Speed Training** | Private | City & Guilds accredited | Premium online — affiliate partner |
| **Budget providers** | Tiny | Level 2 from £6-12 | Commodity market, race to bottom |

Becoming Highfield approved centre: £450+VAT one-off, need qualified trainers. CPD accreditation: £277/year for up to 30 courses — much easier path.

---

## Phased Go-to-Market Strategy

```
Phase 1 (now → 6 months):
├── Freemium launch (Free + Pro £25-39/мес)
├── Apply for Innovate UK Smart Grant
├── Contact FSA for endorsement/partnership
├── Affiliate links to training providers (Virtual College, High Speed Training)
└── Google/App Store SEO optimization

Phase 2 (6-12 months, target: 200+ users):
├── Freemium revenue growing
├── Training provider bundles (growth hack)
├── Student viral channel (when v1.4 training module ships)
├── CPD accreditation for AI training modules
├── Restaurant association partnerships (UKHospitality, BII)
└── Supplier marketplace (opt-in, if enough scale)

Phase 3 (12-18 months, target: 500+ users):
├── Franchise tier launch (£99-199/мес per location)
├── POS integration partnerships (Square, Toast)
├── White-label training discussions
├── Content marketing / SEO long-game
└── Industry events & demos

Phase 4 (18+ months):
├── Enterprise/franchise sales
├── International expansion (EU — same allergen regulations)
├── Angel round if needed for acceleration
└── Potential POS acquisition discussions
```

---

## Waiting For
- [ ] Maria's feedback on feature priorities
- [ ] Any additional input before starting v1.2 implementation
- [ ] Decision on FSA outreach timing
- [ ] Research Innovate UK grant application deadlines
