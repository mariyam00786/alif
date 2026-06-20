# Ilmify Feature-Parity Implementation Plan

> Goal: Bring the same **content, modules, and UI experience** as [ilmify.app](https://ilmify.app/)
> into the existing **alifschool** monorepo (`backend/`, `admin-panel/`, `mobile_app/`, `design-system/`).
> This is a planning document — no code is changed by this file.

---

## 1. What Ilmify Is

Ilmify is a **Smart Islamic Learning Management Platform** for Maktabs, Madrasas, Niswans,
Darul Ulooms and Islamic Schools. It ships as four connected surfaces:

| Surface | Audience | Purpose |
|---|---|---|
| **Admin Panel** | Institution admins | Manage students, teachers, classes, records, setup, fees |
| **Staff Panel** | Teachers / staff | Attendance, exams, schedules, assessments, curriculum |
| **Parent Panel** (mobile) | Parents / students | Attendance, results, progress, updates on phone |
| **Marketing site** | Public | Features, pricing, tutorials, FAQ |

### Ilmify's core pillars
- **Hifz & Nazra** – assign lessons, track Hifz/Nazira progress, manage revisions (Qaida, Nazrah, Hifz).
- **Tarbiyah** – character, manners, daily routines, participation, personal goals.
- **Salah** – daily Fard/Sunnah/Nawafil tracking; on-time, Qada, masjid vs home.

### Ilmify's management feature set
Student Management · Teacher Portal · Fee Management · Attendance System ·
Curriculum Management · Exam & Grading · Inventory Management · Transport Management ·
Multi-branch / network · Multi-language (EN, தமிழ், മലയാളം, اردو, العربية, हिन्दी).

---

## 2. What alifschool Already Has (Baseline)

| Area | Status | Location |
|---|---|---|
| Daily activity / Ihthisab tracking | ✅ Built | `mobile_app/lib/screens/daily_marking_screen.dart` |
| Progress views & charts | ✅ Built | `mobile_app/lib/screens/progress_view_screen.dart` |
| Leaderboard / gamification | ✅ Built | `mobile_app/lib/screens/leaderboard_screen.dart` |
| Student / Parent portals (mobile) | ✅ Built | `mobile_app/lib/screens/parent/`, `dashboard/` |
| Admin panel (web) | ✅ Built | `admin-panel/lib/screens/` |
| Auth (OTP + Google + Supabase) | ✅ Built | `backend/src/routes/auth.ts` |
| Backend modules | ✅ Partial | `students, teachers, academics, activities, activity-logs, achievements, reports, notifications, parents` |
| Bilingual EN/ML | ✅ Built | throughout |
| Design system (Material 3) | ✅ Built | `design-system/` |

**Conclusion:** alifschool already covers Ilmify's *Salah/activity tracking + parent/admin*
foundation. The gap to "Ilmify parity" is mainly **new domain modules** (Hifz, Tarbiyah,
Fees, Attendance, Exams, Curriculum, Inventory, Transport, Staff panel) plus **more languages**.

---

## 3. Gap Analysis (Ilmify ➜ alifschool)

| Ilmify module | alifschool today | Gap | Priority |
|---|---|---|---|
| Salah tracking | ✅ Activity logging exists | Add structured Fard/Sunnah/Nawafil + on-time/Qada/Masjid fields | P1 |
| Tarbiyah / character | ⚠️ Partial (behavior rating) | Formalize character/manners/goals module | P1 |
| Hifz & Nazra | ❌ Missing | New lesson-assignment + revision tracking module | P1 |
| Student Management | ✅ Exists | Add admission tracking, full profile records | P2 |
| Attendance System | ⚠️ Partial | Dedicated attendance + parent notifications | P1 |
| Exam & Grading | ❌ Missing | Grading scales, report cards, exam schedules | P2 |
| Fee Management | ❌ Missing | Fee collection, payments, reports, scholarships | P2 |
| Curriculum Management | ❌ Missing | Lesson scheduling, milestones | P3 |
| Staff Panel | ⚠️ Admin only | Teacher-facing app/portal surface | P2 |
| Inventory Management | ❌ Missing | Books, uniforms, stock | P3 |
| Transport Management | ❌ Missing | Routes, vehicles, drivers | P3 |
| Multi-branch / network | ❌ Missing | Institution → branch hierarchy | P3 |
| Multi-language (6) | ⚠️ EN/ML only | Add Tamil, Urdu, Arabic, Hindi | P3 |
| Marketing site | ❌ N/A | Optional landing page | P4 |

---

## 4. Phased Roadmap

### Phase A — Core Pillars Parity (P1)
Make the three Ilmify pillars first-class.

1. **Salah module**
   - Backend: extend `activities` / new `prayer_logs` table — fields: prayer (Fajr…Isha),
     type (Fard/Sunnah/Nawafil), status (on-time/Qada/missed), place (Masjid/Home).
   - Mobile: dedicated Salah daily card on student/parent dashboards.
2. **Tarbiyah module**
   - Backend: `tarbiyah_assessments` (character, manners, routine, participation, goals).
   - Mobile + Admin: rating UI reusing existing `BehaviorRating` component.
3. **Hifz & Nazra module**
   - Backend: `hifz_lessons` (assigned surah/ayah range, type Qaida/Nazrah/Hifz),
     `hifz_progress` (status, revisions, grade).
   - Teacher assigns; student/parent view progress; admin reports.

**Deliverable:** Student/parent dashboard shows Salah + Tarbiyah + Hifz tabs matching Ilmify content.

### Phase B — School Operations (P2)
4. **Attendance System** — daily attendance + push notification to parents (reuse `notifications`).
5. **Student Management** — admission record, full profile, academic history.
6. **Exam & Grading** — exam schedule, grade scales, auto report card (PDF — `pdf` pkg already in admin).
7. **Staff Panel** — teacher-facing surface (extend `mobile_app` with role==teacher, or admin sub-area).

### Phase C — Finance & Logistics (P3)
8. **Fee Management** — fee plans, collection, receipts, scholarship, reports.
9. **Curriculum Management** — lesson scheduling, milestones.
10. **Inventory** + **Transport** — stock, routes, vehicles, drivers.
11. **Multi-branch hierarchy** — institution → branches with scoped data.
12. **Languages** — add Tamil/Urdu/Arabic/Hindi to the i18n layer (RTL for Arabic/Urdu).

### Phase D — Marketing (P4, optional)
13. Public landing page mirroring Ilmify sections: hero, pillars, features grid,
    pricing tiers, tutorials, FAQ, testimonials, app-store links.

---

## 5. Suggested Data Model Additions (Supabase)

New migrations under `backend/supabase/migrations/`:

```text
prayer_logs            (student_id, date, prayer, type, status, place)
tarbiyah_assessments   (student_id, date, criterion, rating, note, assessed_by)
hifz_lessons           (id, student_id, type, surah, ayah_from, ayah_to, assigned_by, due_date)
hifz_progress          (lesson_id, status, revisions, grade, evaluated_by, evaluated_at)
attendance             (student_id, date, status, marked_by, batch_id)
exams / exam_results   (exam meta + per-student grades)
fee_plans / fee_payments
inventory_items / transport_routes        (Phase C)
branches               (institution_id, name, settings)   (Phase C)
```

> Follow existing RLS + JWT patterns (see repo memory: service-role on backend only,
> anon key + RLS on clients). Each module = its own route file under `backend/src/routes/`
> mounted in `src/app.ts`, mirroring current `activities.ts` / `parents.ts` structure.

---

## 6. UI/UX Approach (match Ilmify look & feel)

- Reuse the **portal_ui kit** (`mobile_app/lib/components/portal_ui.dart`:
  `PortalHeader`, `SoftCard`, `StatTile`, `SectionLabel`, `PortalSegmented`) so new
  modules feel native to the app, while adopting Ilmify's card-heavy, stat-forward layout.
- Dashboard pattern per pillar: top stat tiles → segmented tabs (Salah / Tarbiyah / Hifz)
  → daily list cards. This mirrors Ilmify's pillar presentation.
- Keep `design-system/` tokens (green primary, gold secondary) — visually distinct from
  Ilmify but structurally equivalent.
- Bilingual EN/ML now; extend to 6 languages in Phase C.

---

## 7. Recommended Next Step

Start with **Phase A, item 1 (Salah module)** end-to-end as a vertical slice:
1. Add `prayer_logs` migration.
2. Add `backend/src/routes/prayer-logs.ts` + service, mount in `app.ts`.
3. Add Salah daily card to student dashboard, then surface it in the parent child-detail view.

This proves the full stack pattern that every other Ilmify module will reuse.

---

*Document created as a planning artifact. No application code is modified by this file.*
