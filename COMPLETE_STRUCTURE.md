# Alif School - Complete Project Structure & Technology Guide

**Last Updated:** June 18, 2026  
**Project Type:** Full-Stack Monorepo Application  
**Node Version Required:** ≥18.0.0  
**NPM Version Required:** ≥9.0.0

---

## 📊 Visual Project Tree

```
alifschool/                          ← Root (Monorepo)
│
├─ 🔧 BACKEND (Node.js + Express)
│  └─ backend/                       [TypeScript + Express.js]
│     ├─ src/
│     │  ├─ app.ts                   Main Express application & middleware
│     │  ├─ config/                  Configuration files
│     │  │  ├─ config.ts             App configuration (ports, environment)
│     │  │  ├─ firebase.ts           Firebase Admin SDK setup
│     │  │  └─ supabase.ts           Supabase client configuration
│     │  │
│     │  ├─ routes/                  API endpoint routes (14 modules)
│     │  │  ├─ auth.ts               Authentication (OTP, login, JWT)
│     │  │  ├─ students.ts           Student CRUD operations
│     │  │  ├─ teachers.ts           Teacher management
│     │  │  ├─ activities.ts         Activity configuration
│     │  │  ├─ activity-logs.ts      Daily activity logging
│     │  │  ├─ academics.ts          Academic records
│     │  │  ├─ achievements.ts       Badge/achievement system
│     │  │  ├─ admin.ts              Admin operations
│     │  │  ├─ daily-records.ts      Daily record management
│     │  │  ├─ health.ts             Health check endpoint
│     │  │  ├─ master-data.ts        Reference data
│     │  │  ├─ notifications.ts      Push notifications
│     │  │  ├─ progress.ts           Progress calculations
│     │  │  └─ reports.ts            Report generation
│     │  │
│     │  ├─ controllers/             (Currently empty - routes inline)
│     │  ├─ services/                Business logic & external APIs
│     │  ├─ database/                Database queries & operations
│     │  ├─ middleware/              Express middleware (auth, errors, etc)
│     │  ├─ types/                   TypeScript interfaces & types
│     │  ├─ errors/                  Custom error classes
│     │  └─ utils/                   Helper functions
│     │
│     ├─ supabase/
│     │  ├─ migrations/              Database schema migrations (SQL)
│     │  │  ├─ 20260617170622_init_schema.sql
│     │  │  └─ 20260618091500_add_activity_scoring_rules.sql
│     │  └─ config.toml              Supabase local config
│     │
│     ├─ dist/                       Compiled JavaScript (generated)
│     ├─ jest.config.cjs             Test configuration
│     ├─ tsconfig.json               TypeScript compiler config
│     ├─ package.json                Backend dependencies
│     └─ .env                        Backend environment variables (local)
│
│
├─ 🎨 DESIGN SYSTEM (Shared Tokens & Components)
│  └─ design-system/                 [TypeScript (config) + Flutter (components)]
│     ├─ lib/                        Flutter package
│     │  ├─ alif_design_system.dart  Main export file
│     │  └─ src/
│     │     ├─ theme/                Theming & tokens
│     │     │  ├─ app_theme.dart     Material 3 theme
│     │     │  ├─ colors.dart        Color palette (semantic)
│     │     │  ├─ typography.dart    Font sizes, weights, Malayalam support
│     │     │  └─ spacing.dart       Spacing scale (4px base unit)
│     │     │
│     │     ├─ components/           40+ Flutter widgets
│     │     │  ├─ buttons/           Primary, Secondary, Danger buttons
│     │     │  ├─ inputs/            TextInput, TextArea, Select, DatePicker
│     │     │  ├─ containers/        Card, Modal, BottomSheet
│     │     │  ├─ data_display/      Table, Badge, Chip, Avatar, Progress
│     │     │  ├─ navigation/        Tabs, Breadcrumbs, AppNavigation
│     │     │  ├─ domain_specific/   ActivityRating, BehaviorRating, etc.
│     │     │  ├─ charts/            ProgressChart, HeatmapCalendar
│     │     │  └─ utilities/         Alert, Toast, Skeleton, EmptyState
│     │     │
│     │     └─ layout/               Responsive layouts
│     │        ├─ responsive_builder.dart
│     │        ├─ responsive_grid.dart
│     │        ├─ admin_layout.dart
│     │        └─ app_layout.dart
│     │
│     ├─ colors.ts                   Color system definition (TypeScript)
│     ├─ typography.ts               Typography definitions
│     ├─ spacing.ts                  Spacing scale
│     ├─ theme.ts                    Master theme tokens
│     ├─ components.ts               Component specifications (30+ types)
│     ├─ layout.ts                   Layout patterns & specs
│     ├─ index.ts                    TypeScript exports
│     ├─ COMPONENTS.md               Component documentation
│     ├─ COMPONENT_TOKENS.md         Token documentation
│     ├─ README.md                   Design system guide
│     ├─ pubspec.yaml                Flutter dependencies
│     └─ package.json                NPM dependencies (for TS config)
│
│
├─ 👨‍💼 ADMIN PANEL (Flutter Web)
│  └─ admin-panel/                   [Flutter + Dart]
│     ├─ lib/
│     │  ├─ main.dart                Application entry point with MultiProvider
│     │  ├─ app.dart                 AdminApp widget & routing setup
│     │  │
│     │  ├─ core/                    Core utilities & models
│     │  │  ├─ admin_api_client.dart HTTP client for API calls
│     │  │  ├─ admin_repository.dart Data access layer
│     │  │  ├─ app_models.dart       Shared data models
│     │  │  ├─ app_theme.dart        Theme application
│     │  │  ├─ demo_data.dart        Mock data for development
│     │  │
│     │  ├─ screens/                 Admin dashboards & management screens
│     │  │  ├─ admin_login_screen.dart         Login screen
│     │  │  ├─ admin_dashboard_screen.dart     Main dashboard
│     │  │  ├─ student_management_screen.dart  CRUD students
│     │  │  ├─ teacher_management_screen.dart  CRUD teachers
│     │  │  ├─ batch_management_screen.dart    CRUD batches/classes
│     │  │  ├─ activity_configuration_screen.dart  Setup activities
│     │  │  ├─ rating_configuration_screen.dart    Configure rating scale
│     │  │  ├─ badge_management_screen.dart   Manage achievements/badges
│     │  │  ├─ notification_management_screen.dart Send notifications
│     │  │  └─ reports_dashboard_screen.dart  Analytics & reports
│     │  │
│     │  ├─ widgets/                 Reusable UI components
│     │  ├─ utils/                   Helper functions
│     │  ├─ src/                     Source (legacy migration area)
│     │  │
│     │  └─ legacy/                  Screens from deprecated admin_panel/
│     │     └─ navigation/           Old navigation structures
│     │
│     ├─ web/                        Flutter Web assets
│     │  ├─ index.html              Web entry point
│     │  ├─ manifest.json           Web app manifest
│     │  └─ icons/                  Favicon & web icons
│     │
│     ├─ test/
│     │  └─ widget_test.dart        Widget tests
│     │
│     ├─ pubspec.yaml               Flutter dependencies
│     ├─ analysis_options.yaml      Dart linter config
│     └─ README.md                  Admin panel guide
│
│
├─ 📱 MOBILE APP (Flutter)
│  └─ mobile_app/                    [Flutter + Dart]
│     ├─ lib/
│     │  ├─ main.dart                Application entry point
│     │  │
│     │  ├─ screens/                 Student & parent screens
│     │  │  ├─ auth/                 Authentication screens
│     │  │  │  └─ login_screen.dart  OTP-based login
│     │  │  │
│     │  │  ├─ daily_marking_screen.dart        Student activity marking
│     │  │  ├─ progress_view_screen.dart        Progress visualization
│     │  │  ├─ leaderboard_screen.dart          Leaderboard view
│     │  │  └─ student_selector_screen.dart     Select child (parents)
│     │  │
│     │  ├─ design_system/           Shared design tokens
│     │  ├─ services/                API & local services
│     │  │
│     │  └─ (to be expanded)
│     │
│     ├─ test/
│     │  └─ integration_test.dart    Integration tests
│     │
│     ├─ pubspec.yaml               Flutter dependencies
│     └─ README.md                  Mobile app guide
│
│
├─ 📚 DOCUMENTATION
│  ├─ docs/                          Setup & operational guides
│  │  ├─ QUICK_SETUP_REFERENCE.md       30-min setup checklist
│  │  ├─ SUPABASE_SETUP.md              Database schema & setup
│  │  ├─ SUPABASE_SETUP_STEP_BY_STEP.md Detailed Supabase guide
│  │  ├─ FIREBASE_SETUP.md              Firebase configuration
│  │  ├─ FIREBASE_SETUP_STEP_BY_STEP.md Detailed Firebase guide
│  │  ├─ ENV_CONFIGURATION_GUIDE.md     All .env variables explained
│  │  ├─ PHASE_1_FOUNDATION.md          Frozen spec & requirements
│  │  ├─ PHASE_1_IMPLEMENTATION_CHECKLIST.md  Implementation guide
│  │  ├─ PHASE_3_4_IMPLEMENTATION.md    UI system implementation
│  │  ├─ PHASE_3_4_SUMMARY.md           UI system summary
│  │  └─ SETUP_DOCUMENTATION_SUMMARY.md Documentation index
│  │
│  └─ documentation/                Architecture & engineering docs
│     ├─ ALIF_PROJECT_REDESIGN.md        Project structure & decisions
│     ├─ ARCHITECTURE_DIAGRAMS.md        System architecture visuals
│     ├─ ARCHITECTURE_QUICK_REFERENCE.md Quick arch overview
│     ├─ FLUTTER_PROJECT_ARCHITECTURE.md Flutter app structure
│     ├─ CHEAT_SHEET.md                  Quick reference
│     ├─ DOCUMENTATION_INDEX.md          Doc navigation
│     └─ README.md                       Doc guide
│
│
├─ 🌐 WEB & CONFIG
│  ├─ .github/                        GitHub config
│  │  └─ copilot-instructions.md      AI assistant instructions
│  │
│  ├─ lib/                           (Placeholder for shared libs)
│  │  └─ design_system/
│  │     └─ theme_provider.dart      Shared theme provider
│  │
│  ├─ .gitignore                      Git ignore patterns
│  ├─ README.md                       Project overview
│  ├─ PROJECT_SETUP.md                Setup quick guide
│  ├─ API_DOCUMENTATION.md            API endpoint reference
│  ├─ CONTRIBUTING.md                 Contribution guidelines
│  ├─ LICENSE                         MIT License
│  ├─ package.json                    Monorepo root config
│  ├─ package-lock.json               NPM lock file
│  └─ node_modules/                   NPM dependencies (generated)

```

---

## 🛠️ Technology Stack by Layer

### **Layer 1: Frontend - Web Admin Panel**
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | ≥3.12.2 | UI framework (cross-platform web, iOS, Android) |
| **Dart** | ≥3.12.2 | Programming language |
| **Provider** | ^6.0.0 | State management |
| **GoRouter** | Latest | Navigation & routing |
| **Material 3** | Built-in | Design system |
| **FL Chart** | ^0.64.0 | Data visualization charts |
| **Table Calendar** | Latest | Calendar widget |

**Run Commands:**
```bash
cd admin-panel
flutter pub get           # Install dependencies
flutter analyze           # Static analysis
flutter run -d chrome     # Run on web
flutter run -d chrome --web-port 5062  # Custom port
flutter test              # Run widget tests
```

---

### **Layer 2: Frontend - Mobile App**
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | ≥3.12.2 | Mobile framework |
| **Dart** | ≥3.12.2 | Programming language |
| **HTTP** | ^1.2.2 | HTTP requests |
| **Firebase Core** | Latest | Firebase integration |
| **Firebase Messaging** | Latest | Push notifications |
| **Supabase Flutter** | Latest | Database & auth |

**Run Commands:**
```bash
cd mobile_app
flutter pub get                    # Install dependencies
flutter run                        # Run on connected device
flutter run -d android             # Android emulator
flutter run -d ios                 # iOS simulator
flutter build apk                  # Build APK
flutter build ipa                  # Build for iOS
```

---

### **Layer 3: Design System Package**
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | ≥3.0.0 | Component library |
| **Dart** | ≥3.0.0 | Components code |
| **TypeScript** | ^5.0.0 | Token definitions (config) |
| **Provider** | ^6.0.0 | State management in components |
| **FL Chart** | ^0.64.0 | Built-in charting |
| **Flutter SVG** | ^2.0.0 | SVG icon support |
| **Intl** | ^0.19.0 | Internationalization |

**Structure:**
- **Dart Components** (`lib/src/`) - 40+ reusable widgets
- **TypeScript Specs** (`*.ts` files) - Token definitions & specifications
- **Responsive System** - Mobile-first grid with breakpoints (xs/sm/md/lg/xl/xxl)
- **Bilingual** - English & Malayalam support

---

### **Layer 4: Backend - API Server**
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Node.js** | ≥18.0.0 | Runtime |
| **Express.js** | ^4.18.2 | Web framework |
| **TypeScript** | ^5.0.0 | Type safety |
| **Supabase JS** | ^2.38.0 | PostgreSQL client |
| **Firebase Admin** | ^12.0.0 | Authentication & messaging |
| **Helmet** | ^7.1.0 | Security headers |
| **CORS** | ^2.8.5 | Cross-origin requests |
| **Compression** | ^1.7.4 | Response compression |
| **Morgan** | ^1.10.0 | HTTP logging |
| **Zod** | ^4.4.3 | Data validation |

**Run Commands:**
```bash
cd backend
npm install                        # Install dependencies
npm run dev                        # Development (ts-node)
npm run build                      # Compile TypeScript
npm run start                      # Run compiled code
npm run test                       # Run Jest tests
npm run lint                       # Run ESLint
```

**API Routes (14 modules):**
```
GET  /health                       Health check
POST /api/auth/request-otp         Request OTP
POST /api/auth/verify-otp          Verify OTP & get token
GET  /api/students                 List students
POST /api/students                 Create student
PUT  /api/students/:id             Update student
DELETE /api/students/:id           Delete student
(+ Teachers, Batches, Activities, Logs, Reports, etc.)
```

---

### **Layer 5: Database - Supabase (PostgreSQL)**
| Component | Language | Purpose |
|-----------|----------|---------|
| **Supabase** | PostgreSQL | Database & Auth |
| **Migrations** | SQL | Schema management |
| **RLS Policies** | PostgreSQL | Row-level security |

**Migrations:**
- `20260617170622_init_schema.sql` - Initial tables (profiles, users, activities, etc.)
- `20260618091500_add_activity_scoring_rules.sql` - Activity scoring configuration

**Database Tables:**
- `profiles` - User profiles
- `students`, `teachers`, `parents` - User roles
- `batches` - Classes/groups
- `activities` - Activity definitions
- `activity_logs` - Daily logs
- `activity_scoring_rules` - Rating configuration
- `badges` - Achievement definitions
- `notifications` - Push notification records

---

### **Layer 6: External Services**
| Service | Purpose | Integration |
|---------|---------|-------------|
| **Firebase Admin SDK** | Auth, Messaging, Notifications | Backend config |
| **Supabase Auth** | OTP login, JWT tokens | Backend & frontend |
| **Firebase Cloud Messaging** | Push notifications | Backend service |
| **Supabase Storage** | File uploads | Frontend & backend |

---

## 📦 Dependency Installation

### **Root (Monorepo)**
```bash
npm install                        # Install root + workspaces
npm run install-all                # Explicit install all packages
```

### **Backend**
```bash
cd backend
npm install
npm run build                      # Compile TypeScript
```

### **Admin Panel**
```bash
cd admin-panel
flutter pub get                    # Get Flutter dependencies
flutter pub upgrade                # Upgrade packages
```

### **Mobile App**
```bash
cd mobile_app
flutter pub get
```

### **Design System**
```bash
cd design-system
flutter pub get
npm install                        # For TypeScript tooling
```

---

## 🚀 Running the Application

### **Backend Server (Port 3000)**
```bash
cd backend
npm run dev
# Verify: curl http://localhost:3000/health
```

### **Admin Panel (Port 5062)**
```bash
cd admin-panel
flutter run -d chrome --web-port 5062
```

### **Mobile App (Emulator)**
```bash
cd mobile_app
flutter run
```

---

## 🔑 Environment Variables

**Backend `.env` (backend/.env):**
```
# Server
PORT=3000
NODE_ENV=development

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
# OR
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# App
APP_NAME=Alif School
JWT_SECRET=your-jwt-secret
```

See [ENV_CONFIGURATION_GUIDE.md](docs/ENV_CONFIGURATION_GUIDE.md) for complete details.

---

## 📋 File Summary by Purpose

### **Configuration Files**
- `tsconfig.json` - TypeScript compiler options
- `jest.config.cjs` - Test framework config
- `analysis_options.yaml` - Dart linter config
- `pubspec.yaml` - Flutter dependencies
- `.env.example` - Environment variable template
- `supabase/config.toml` - Local Supabase config

### **Entry Points**
- `backend/src/app.ts` - Express server
- `admin-panel/lib/main.dart` - Admin app
- `mobile_app/lib/main.dart` - Mobile app
- `design-system/lib/alif_design_system.dart` - Design system

### **Database**
- `backend/supabase/migrations/` - SQL schema migrations
- `docs/SUPABASE_SETUP.md` - Complete schema documentation

### **Documentation**
- `docs/` - Setup guides & operational docs
- `documentation/` - Architecture & design docs
- `design-system/COMPONENTS.md` - Component library
- `README.md` - Project overview

---

## 🎯 Key Development Commands

| Task | Command | Location |
|------|---------|----------|
| **Install all** | `npm run install-all` | Root |
| **Backend dev** | `npm run backend:dev` | Root or backend/ |
| **Backend build** | `npm run backend:build` | Root or backend/ |
| **Backend test** | `npm run backend:test` | Root or backend/ |
| **Admin analyze** | `flutter analyze` | admin-panel/ |
| **Admin run** | `flutter run -d chrome` | admin-panel/ |
| **Mobile build APK** | `flutter build apk` | mobile_app/ |
| **Lint backend** | `npm run lint` | Root or backend/ |
| **Supabase start** | `npm run supabase:start` | backend/ |
| **DB push** | `npm run supabase:db:push` | backend/ |

---

## 📍 Canonical Paths (Single Source of Truth)

| Component | Path | Status |
|-----------|------|--------|
| **Admin Web App** | `admin-panel/` | ✅ Active |
| **Mobile App** | `mobile_app/` | ✅ Active |
| **Backend API** | `backend/` | ✅ Active |
| **Design System** | `design-system/` | ✅ Active |
| **Setup Docs** | `docs/` | ✅ Active |
| **Architecture Docs** | `documentation/` | ✅ Active |
| **Deprecated Admin** | ~~admin_panel/~~ | ❌ Removed (migrated to admin-panel/) |
| **Deprecated Mobile** | ~~mobile-app/~~ | ❌ Removed (empty) |

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERFACES                          │
├─────────────────────┬───────────────────┬───────────────────┤
│   Admin Panel       │   Mobile App      │                   │
│   (Flutter Web)     │   (Flutter)       │                   │
│   Port 5062         │   (iOS/Android)   │                   │
│   TypeScript/Dart   │   Dart            │                   │
└─────────────────────┴───────────────────┴───────────────────┘
                            ↓
                ┌─────────────────────────┐
                │   Shared Design System   │
                │   (Dart + TypeScript)    │
                │   Tokens • Components    │
                └─────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              BACKEND API SERVER                              │
│  Express.js + TypeScript (Node.js)                           │
│  Port 3000                                                   │
│  - Authentication (OTP → JWT)                                │
│  - 14 API route modules                                      │
│  - Error handling & middleware                               │
│  - Business logic & validation                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│            EXTERNAL SERVICES & DATABASE                      │
├──────────────────────┬──────────────────┬──────────────────┤
│  Supabase            │  Firebase Admin  │                  │
│  - PostgreSQL DB     │  - Auth          │                  │
│  - Auth & RLS        │  - Cloud Msg     │                  │
│  - Storage           │  - Notifications │                  │
└──────────────────────┴──────────────────┴──────────────────┘
```

---

## ✅ Implementation Checklist

- [x] Design System created with 40+ components
- [x] Backend scaffolding with 14 API modules
- [x] Admin panel with 10 management screens
- [x] Mobile app with auth & core screens
- [x] Database migrations (initial + scoring rules)
- [x] TypeScript configuration & build setup
- [x] Flutter pubspec files configured
- [x] Comprehensive documentation

**Next Steps:**
- [ ] Connect UI screens to backend APIs
- [ ] Implement activity logging workflows
- [ ] Add real-time notifications
- [ ] Create reporting & export features
- [ ] Mobile app completion
- [ ] QA & performance optimization
- [ ] Deployment setup

---

Generated: June 18, 2026 | Version: 1.0.0
