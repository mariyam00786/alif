# Alif School Project Redesign Blueprint

## Purpose

This blueprint translates the current documentation into a realistic redesign plan for the existing monorepo.

Primary goals:
- Align documentation with the actual repository
- Standardize app boundaries and naming
- Stabilize auth + environment setup
- Move from parallel/duplicate app folders to a single source of truth per platform

## Current Findings (Analysis Summary)

Based on repository scan and docs review:

3. ~~Duplicate app roots~~ (resolved):
- `admin_panel/` → removed; unique screens preserved in `admin-panel/lib/legacy/`
- `mobile-app/` → removed (was empty)

2. Documentation split is inconsistent:
- `docs/` is Alif School setup and phase documentation
- `documentation/` includes generic Flutter architecture docs (from another project template) and does not fully match this repo

3. Runtime status (local):
- Admin web app can run on localhost
- Backend can run with Firebase skipped when service account credentials are missing
- Firebase keys are partially configured; admin credentials are still missing

4. Implementation drift exists between documented and actual paths:
- Some guides reference `admin_panel/` while active runnable app is `admin-panel/`

## Redesign Decision (Canonical Targets)

Canonical app roots for this repository:
- Admin web: `admin-panel/`
- Mobile app: `mobile_app/`
- Backend API: `backend/`
- Shared design tokens/package: `design-system/`
- Product and setup docs: `docs/`
- Architecture and migration docs: `documentation/`

Deprecation targets (completed):
- ~~`admin_panel/`~~ removed; unique screens preserved in `admin-panel/lib/legacy/`
- ~~`mobile-app/`~~ removed (was empty)

## Target Architecture

```text
alifschool/
  backend/
    src/
      config/
      middleware/
      routes/
      services/
      database/
      types/
  admin-panel/
    lib/
      core/
      screens/
      widgets/
      main.dart
  mobile_app/
    lib/
      screens/
      services/
      main.dart
  design-system/
    lib/
      src/
  docs/
    setup + product + phase docs
  documentation/
    architecture + migration + engineering standards
```

## Redesign Workstreams

### Workstream A: Repo Structure Normalization

1. Freeze new feature work in deprecated folders:
- `admin_panel/`
- `mobile-app/`

2. Migrate remaining useful code from legacy folders into canonical folders:
- `admin_panel/lib/screens/auth/login_screen.dart` -> evaluate and merge into `admin-panel/lib/screens/`
- `mobile-app/` is empty: no migration needed

3. Remove deprecated folders after migration and verification.

Definition of done:
- Exactly one active admin app folder and one active mobile app folder
- README and docs reference only canonical paths

### Workstream B: Auth and Config Hardening

1. OTP auth completed in UI flows should be the single auth gateway.
2. Backend Firebase admin config must be finalized with one valid method:
- Preferred: `FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json`
- Alternative: env-based service account keys (`FIREBASE_PRIVATE_KEY`, etc.)
3. Add environment profile matrix in docs:
- local
- staging
- production

Definition of done:
- Backend starts without warnings in local mode
- OTP verify returns token and protected API calls use that token end-to-end

### Workstream C: Documentation Consolidation

1. Keep setup and operational docs in `docs/`
2. Keep architecture/migration engineering docs in `documentation/`
3. Mark generic template docs as reference-only where they conflict with Alif architecture.

Definition of done:
- New contributors can follow one path without ambiguity

## Phased Execution Plan

### Phase R1 (1 day)
- Finalize canonical path policy
- Update indexes and README links
- Add migration checklist and folder ownership

### Phase R2 (2-3 days)
- Migrate any remaining auth/UI logic from `admin_panel/` to `admin-panel/`
- Remove deprecated folder references from scripts/docs
- Stabilize backend startup + Firebase env completeness

### Phase R3 (3-5 days)
- Remove deprecated folders
- Add CI checks for path policy and docs link validation
- Add smoke tests for:
  - backend `/health`
  - admin login render
  - OTP request/verify contract

## Immediate Action Checklist

- [ ] Place `firebase-service-account.json` in `backend/` (or fill service account env vars)
- [x] Confirmed `admin-panel/` is the only admin app to develop further
- [x] Confirmed `mobile_app/` is the only mobile app to develop further
- [x] Migrated unique `admin_panel/` screens to `admin-panel/lib/legacy/`; `admin_panel/` removed
- [x] Removed empty `mobile-app/` folder
- [x] Fixed all `mobile-app/` path mentions in `docs/` and root README

## Risk Register

1. Duplicate-folder drift risk
- Impact: bug fixes applied to wrong app
- Mitigation: canonical path policy + cleanup

2. Auth mismatch risk
- Impact: login appears successful but backend data is unauthorized
- Mitigation: token propagation tests + repository auth assertions

3. Setup complexity risk
- Impact: onboarding delays
- Mitigation: one setup path + verified local run script set

## Verification Commands

Backend:
```bash
cd backend
npm run dev
# verify:
curl http://localhost:3000/health
```

Admin:
```bash
cd admin-panel
flutter analyze
flutter run -d chrome --web-port 5062
```

Mobile:
```bash
cd mobile_app
flutter analyze
flutter run
```

## Ownership

- Architecture and migration owner: Engineering lead
- Backend config owner: Backend/API owner
- Flutter app normalization owner: Frontend/mobile owner
- Documentation owner: Repo maintainer

---

This redesign plan is intentionally practical: preserve running apps, remove ambiguity, and move to a clean single-path architecture without large risky rewrites.
