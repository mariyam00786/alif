# Alif School Architecture Documentation

This folder contains architecture and redesign guidance for the Alif School monorepo.

## 📚 Documentation

This folder includes architecture references and an actionable redesign blueprint.

### For Developers
- **[ALIF_PROJECT_REDESIGN.md](ALIF_PROJECT_REDESIGN.md)** - Canonical repo redesign blueprint and migration plan
- **[FLUTTER_PROJECT_ARCHITECTURE.md](FLUTTER_PROJECT_ARCHITECTURE.md)** - Generic Flutter architecture reference
- **[ARCHITECTURE_QUICK_REFERENCE.md](ARCHITECTURE_QUICK_REFERENCE.md)** - Quick reference patterns

### For AI Agents
- Use project-specific instructions in root and `docs/` first.
- Use generic architecture docs in this folder only as secondary reference.

---

## Getting Started

### Prerequisites
```bash
Flutter SDK: >=3.0.0
Dart SDK: >=3.0.0
```

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd alifschool
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the active apps
```bash
cd backend && npm run dev
cd ../admin-panel && flutter run -d chrome
```

---

## Project Architecture

Primary architecture references for this repository:
- Product and setup docs: `docs/`
- Redesign and migration plan: `documentation/ALIF_PROJECT_REDESIGN.md`

### Folder Structure (Canonical)
```
alifschool/
├── backend/
├── admin-panel/
├── mobile_app/
├── design-system/
├── docs/
└── documentation/
```

Read [ALIF_PROJECT_REDESIGN.md](ALIF_PROJECT_REDESIGN.md) for the full redesign path.

---

## Development Guidelines

### Creating a New Feature

1. Confirm target app (`admin-panel` or `mobile_app`)
2. Add API contract in backend first when needed
3. Implement screen and service in canonical app folder only
4. Update docs if behavior or setup changes

### Code Standards

Always:
- Use Provider for state management
- Handle loading, error, and empty states
- Use theme constants (never hardcode colors/styles)
- Follow null safety guidelines
- Break complex widgets into smaller methods
- Add meaningful comments

Never:
- Hardcode colors or text styles
- Use `StatefulWidget` when Provider can handle it
- Forget error handling
- Skip null checks

Daily reference: [ARCHITECTURE_QUICK_REFERENCE.md](ARCHITECTURE_QUICK_REFERENCE.md)

---

## Build and Run

### Backend
```bash
cd backend
npm run dev
```

### Admin Web
```bash
cd admin-panel
flutter run -d chrome
```

### Mobile
```bash
cd mobile_app
flutter run
```

---

## Notes

Some files in this folder are generic templates and may not exactly match current Alif code structure. Use them as references, not source of truth.

---

## AI-Assisted Development

Use project-specific docs in `docs/` and `ALIF_PROJECT_REDESIGN.md` first.

## Quick Links

- [Alif Redesign Blueprint](ALIF_PROJECT_REDESIGN.md)
- [Full Architecture Guide (Generic)](FLUTTER_PROJECT_ARCHITECTURE.md)
- [Quick Reference](ARCHITECTURE_QUICK_REFERENCE.md)
