# Admin Panel Fix Plan — Phased (2026-06-25)

> Derived from corrected live audit. The earlier "navigation mismatch" finding
> was a measurement artifact (mobile-layout confusion + parallel snapshot
> calls). Verified 2026-06-25 at 1440px: all 9 sections render the correct
> content. Real issues are listed below, ordered by impact.

## Verified Status (2026-06-25)
- Site: http://localhost:8080 (bypass mode), 1440×900 desktop layout.
- All 9 nav sections map to correct screen title:
  - Dashboard → "Admin Dashboard" ✓
  - Students → "Student Management" ✓
  - Teachers → "Teacher Management" ✓
  - Batches & Classes → "Batch Management" ✓
  - Activities → "Activity Configuration" ✓
  - Rating & Scoring → "Rating & Scoring" ✓ (title, not "Rating Configuration")
  - Badges → "Badge Management" ✓
  - Notifications → "Notification Management" ✓
  - Reports → "Reports Dashboard" ✓

## Confirmed Issues (to fix)

### Phase 1 — Structural consistency (foundation, low-risk)
**Issue F1.1: Dashboard does not use `AdminPageFrame`**
- `admin-panel/lib/screens/admin_dashboard_screen.dart` builds its own header
  via `_HeroCard`, while every management screen uses `AdminPageFrame`.
- Result: title style, subtitle style, and top padding diverge on Dashboard.
- Fix: Refactor Dashboard to wrap content in `AdminPageFrame(title:'Admin Dashboard', subtitle:'Daily overview of students, activities and performance.', children:[...])`, moving the existing stats into the children list. Keep `_HeroCard` visuals inside.

**Issue F1.2: Bottom padding mismatch**
- Dashboard uses bottom padding `100`; AdminPageFrame uses `16` (compact `96`).
- Fix: Unify to the AdminPageFrame value once Dashboard uses the frame.

### Phase 2 — Typographic & spacing rhythm (UI quality)
**Issue F2.1: Inconsistent title typography across entry points**
- AdminPageFrame title = `headlineMedium` w800 primary color.
- Dashboard hero uses its own larger gradient title.
- Fix: After F1.1, the dashboard title inherits AdminPageFrame styling.

**Issue F2.2: Card spacing/scaling tokens not centralized**
- Spacing values like `12`, `14`, `16`, `20`, `24`, `100` are hardcoded per
  screen.
- Fix: Introduce a small `admin_spacing.dart` token constants file
  (`space4/8/12/16/20/24/32`) and replace magic numbers in the primary screens
  (Dashboard, Student, Teacher, Batch, Activity, Rating, Badge, Notification,
  Reports). Keep behavior identical; only source-unify the numbers.

**Issue F2.3: Secondary text contrast**
- `bodySmall`/`labelMedium` use `#64748B` / `#6B7280` on light cards.
- Fix: Bump to `#475569` for `bodySmall` and `#4B5563` for `labelMedium` for
  comfortable reading without losing hierarchy.

### Phase 3 — Naming & content fixes
**Issue F3.1: Rating screen title inconsistency**
- Screen renders "Rating & Scoring" but the enum label says "Rating/Scoring"
  and the nav says "Rating & Scoring".
- Fix: Set the Rating `AdminPageFrame` title to "Rating & Scoring" (matches nav)
  and the enum description to "Define score bands and defaults".

### Phase 4 — Login UX robustness
**Issue F4.1: Phone validation too strict + unclear guidance**
- `admin-panel/lib/screens/admin_otp_login_screen.dart` rejects formats with
  spaces/`+91`/dashes; helper text doesn't show accepted formats.
- Fix: Normalize the phone (strip non-digits, trim leading country code) before
  validation, and update helper text to "Enter 10-digit mobile (e.g. 9876543210). +91 optional."

### Phase 5 — Verification
**V5.1: Re-run live navigation matrix test** at 1440px and 390px to confirm all
9 sections still map to correct screens after edits.
**V5.2: `flutter analyze`** on every edited file (must be clean).
**V5.3: Hot-reload and screenshot** Dashboard, Rating, Login for visual diff.

## Out of Scope (but noted)
- SNCP/player-id integration: no repository references found. Needs a concrete
  player-id sample + endpoint to validate (user to provide).

## Execution Order
Phase 1 → 2 → 3 → 4 → 5. Each phase ends with `flutter analyze` clean.
