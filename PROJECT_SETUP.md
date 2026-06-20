# Alif Online Moral School - Project Setup Guide

## 📋 Complete System Documentation

> Full-stack educational platform for Islamic moral and character development with daily activity tracking, progress analytics, and bilingual (English/Malayalam) support.

---

## 🎯 Project Overview

**Alif Online Moral School** is an integrated platform that enables:

- **Students** to track daily Islamic activities (prayers, Quran reading, character development)
- **Parents** to monitor children's progress and achievements
- **Teachers** to manage classes and approve daily records
- **Admins** to manage students, batches, activities, and system configuration
- **Analytics** to track long-term progress and identify improvement areas

### Key Statistics

- **Phase 1**: 6 activity categories, 19 core activities, 4 rating levels
- **Tech Stack**: Node.js + Express backend, Flutter (Dart) mobile/admin apps, Supabase PostgreSQL
- **Bilingual**: Full English & Malayalam (RTL) support across all UI
- **Architecture**: JWT auth, RBAC, Row-Level Security, in-memory caching

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Frontend Layer                         │
├─────────────────────────────────────────────────────────┤
│ Flutter Web (Admin)    │    Flutter Mobile (Student)    │
│  - Dashboard           │     - Daily Marking            │
│  - Student CRUD        │     - Progress View            │
│  - Batch Management    │     - Leaderboard              │
│  - Settings            │     - Login & Auth             │
└─────────────────────────────────────────────────────────┘
           │                           │
           └─────────────┬─────────────┘
                         │ HTTP/REST
┌─────────────────────────────────────────────────────────┐
│               Backend (Node.js + Express)                │
├─────────────────────────────────────────────────────────┤
│  Routes (30+ endpoints)                                 │
│  ├─ /api/auth (OTP login)                              │
│  ├─ /api/students (CRUD)                               │
│  ├─ /api/batches (CRUD)                                │
│  ├─ /api/activities (Master data)                      │
│  ├─ /api/daily-records (Daily tracking)                │
│  ├─ /api/progress (Analytics)                          │
│  └─ /api/health (System check)                         │
└─────────────────────────────────────────────────────────┘
           │
           │ PostgreSQL
           │
┌─────────────────────────────────────────────────────────┐
│       Database (Supabase + Row-Level Security)          │
├─────────────────────────────────────────────────────────┤
│  Tables:                                                │
│  - students, batches, teachers                         │
│  - activity_categories, activities                     │
│  - daily_records, activity_ratings                     │
│  - student_progress (analytics)                        │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Installation & Setup

### Prerequisites

- Node.js 18.0+ (`node --version`)
- Flutter 3.10+ with Dart 3.0+ (`flutter --version`)
- Supabase account (https://supabase.com)
- Git (for version control)

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your Supabase credentials:
# SUPABASE_URL=https://[project].supabase.co
# SUPABASE_KEY=[anon-key]
# SUPABASE_ADMIN_KEY=[service-role-key]

# Run migrations
npm run db:migrate

# Seed demo data
npm run db:seed

# Start development server
npm run dev

# Verify health (in another terminal)
npm run test:health
```

**Backend runs on:** `http://localhost:3000/api`

### 2. Admin Panel Setup

```bash
cd admin_panel

# Install dependencies
flutter pub get

# Run on web (Chrome)
flutter run -d chrome

# Or run tests to verify
flutter test test/integration_test.dart

# Build for production
flutter build web --release
```

**Admin runs on:** `http://localhost:5000` (or as configured)

### 3. Mobile App Setup

```bash
cd mobile_app

# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Or run on Android emulator
flutter run -d android

# Run tests
flutter test test/integration_test.dart

# Build release
flutter build apk --release    # Android
flutter build ios --release    # iOS
```

---

## 📂 Project Structure

```
alifschool/
│
├── backend/                          # Node.js + Express API
│   ├── src/
│   │   ├── services/                 # Business logic (7 services)
│   │   │   ├── activity.ts          # Master data caching
│   │   │   ├── scoring.ts           # Mark calculations
│   │   │   ├── logging.ts           # Activity validation
│   │   │   ├── progress.ts          # Analytics & trends
│   │   │   ├── auth.ts              # JWT verification
│   │   │   ├── health.ts            # System monitoring
│   │   │   └── webhook.ts           # Event handling
│   │   ├── routes/                   # API endpoints (30+)
│   │   │   ├── auth.ts
│   │   │   ├── students.ts
│   │   │   ├── batches.ts
│   │   │   ├── activities.ts
│   │   │   ├── daily-records.ts
│   │   │   ├── progress.ts
│   │   │   └── health.ts
│   │   ├── middleware/               # Express middleware
│   │   │   ├── error-handler.ts
│   │   │   └── auth.ts
│   │   ├── types/                    # TypeScript interfaces
│   │   └── database/                 # Supabase schema
│   ├── scripts/
│   │   ├── seed.ts                  # Demo data seeding
│   │   └── health-check.ts          # Health validation
│   ├── package.json
│   └── .env                          # Configuration (DO NOT COMMIT)
│
├── admin_panel/                      # Flutter web dashboard
│   ├── lib/
│   │   ├── design_system/            # Design tokens & components
│   │   │   ├── colors.dart          # ColorPalette (21 colors)
│   │   │   ├── typography.dart      # TypographySystem
│   │   │   ├── spacing.dart         # SpacingScale
│   │   │   ├── components/          # 8 reusable components
│   │   │   │   ├── button.dart
│   │   │   │   ├── input.dart
│   │   │   │   ├── card.dart
│   │   │   │   ├── badge.dart
│   │   │   │   ├── rating_selector.dart
│   │   │   │   ├── quantity_input.dart
│   │   │   │   ├── progress_summary.dart
│   │   │   │   └── theme_provider.dart
│   │   ├── screens/                  # Admin UI screens (9)
│   │   │   ├── auth/
│   │   │   │   └── login_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── students/
│   │   │   │   └── management_screen.dart
│   │   │   ├── batches/
│   │   │   │   └── management_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── services/
│   │   │   └── api_service.dart      # API client (20+ endpoints)
│   │   ├── navigation/
│   │   │   └── routes.dart          # Routing & deep linking
│   │   ├── utils/
│   │   │   └── feedback_handler.dart # Error handling & validation
│   │   └── main.dart
│   ├── test/
│   │   └── integration_test.dart
│   └── pubspec.yaml
│
├── mobile_app/                       # Flutter mobile app
│   ├── lib/
│   │   ├── design_system/            # Shared tokens & components
│   │   ├── screens/                  # Mobile UI screens (7)
│   │   │   ├── auth/
│   │   │   │   └── login_screen.dart
│   │   │   ├── student_selector_screen.dart
│   │   │   ├── daily_marking_screen.dart
│   │   │   ├── progress_view_screen.dart
│   │   │   └── leaderboard_screen.dart
│   │   ├── services/
│   │   │   └── api_service.dart      # Simplified API client
│   │   └── main.dart
│   ├── test/
│   │   └── integration_test.dart
│   └── pubspec.yaml
│
├── PROJECT_SETUP.md (this file)
└── .gitignore
```

---

## 🔑 API Endpoints Overview

### Authentication (2 endpoints)

```
POST   /api/auth/request-otp      # Request OTP for phone
POST   /api/auth/verify-otp       # Verify OTP and get JWT
```

### Students (5 endpoints)

```
GET    /api/students              # List with pagination & filters
POST   /api/students              # Create new student
GET    /api/students/:id          # Get student details
PUT    /api/students/:id          # Update student
DELETE /api/students/:id          # Soft delete student
```

### Batches (4 endpoints)

```
GET    /api/batches               # List all batches
POST   /api/batches               # Create batch
GET    /api/batches/:id/students  # Get batch students
PUT    /api/batches/:id           # Update batch
```

### Activities (3 endpoints)

```
GET    /api/activities            # List all activities
GET    /api/activities/categories # Get categories
GET    /api/activities/structure/daily # Get daily structure
```

### Daily Records (5 endpoints)

```
POST   /api/daily-records         # Create record
GET    /api/daily-records/:id     # Get record
PUT    /api/daily-records/:id     # Update record
POST   /api/daily-records/:id/submit   # Submit & lock
POST   /api/daily-records/:id/approve  # Parent approval
```

### Progress & Analytics (6 endpoints)

```
GET    /api/students/:id/progress/daily    # Daily metrics
GET    /api/students/:id/progress/weekly   # Weekly summary
GET    /api/students/:id/progress/monthly  # Monthly breakdown
GET    /api/batches/:id/leaderboard       # Daily rankings
GET    /api/batches/:id/leaderboard/weekly # Weekly rankings
GET    /api/batches/:id/leaderboard/monthly # Monthly rankings
```

### System (1 endpoint)

```
GET    /api/health                # System health check
```

---

## 🎨 Design System

### Colors (21 semantic colors)

```dart
ColorPalette.primaryDark      // #2E7D32 - Main brand
ColorPalette.secondary        // #FFA000 - Secondary accent
ColorPalette.success          // #4CAF50 - Success/positive
ColorPalette.warning          // #FF9800 - Warning/caution
ColorPalette.error            // #F44336 - Error/negative
ColorPalette.neutral50        // #FAFAFA - Lightest
ColorPalette.neutral800       // #212121 - Darkest
// ... and 14 more
```

### Typography (6 text styles)

```dart
TypographySystem.pageTitle    // 32pt Bold
TypographySystem.sectionTitle // 24pt SemiBold
TypographySystem.cardTitle    // 18pt SemiBold
TypographySystem.bodyText     // 16pt Regular
TypographySystem.caption      // 12pt Regular
TypographySystem.overline     // 10pt Medium
```

### Spacing (7 scale units)

```dart
SpacingScale.xs       // 4px
SpacingScale.sm       // 8px
SpacingScale.md       // 12px
SpacingScale.lg       // 16px
SpacingScale.xl       // 24px
SpacingScale.xxl      // 32px
SpacingScale.xxxl     // 48px
```

---

## 🧪 Testing & Validation

### Backend Health Check

```bash
cd backend
npm run test:health
```

**Expected output:**
```
✅ Server Connectivity
✅ Health Endpoint
✅ Auth Endpoints
✅ Activity Endpoints
✅ Progress Endpoints
✅ Database (Supabase)
✅ All health checks passed!
```

### Admin Panel Tests

```bash
cd admin_panel
flutter test test/integration_test.dart
```

**Tests cover:**
- Authentication flow (phone → OTP)
- Student CRUD operations
- Batch management
- Form validation
- Error handling
- Bilingual support
- Navigation

### Mobile App Tests

```bash
cd mobile_app
flutter test test/integration_test.dart
```

**Tests cover:**
- Login flow (role → phone → OTP)
- Student selection
- Daily marking workflow
- Progress tracking
- Leaderboard rankings
- Bilingual support

---

## 🔒 Security Features

### Authentication

- **Phone OTP Login** - Supabase Auth with SMS verification
- **JWT Tokens** - HS256 signed with 1-hour expiry
- **Refresh Tokens** - Secure HttpOnly cookies
- **Role-Based Access** - student, parent, teacher, admin roles

### Database

- **Row-Level Security (RLS)** - Supabase policies per role
- **Data Encryption** - At-rest (AES-256) and in-transit (TLS 1.2+)
- **Soft Deletes** - Archive with `status` field instead of hard delete
- **Audit Logs** - Track all user actions

### API

- **CORS** - Whitelist specific origins
- **Rate Limiting** - 100 requests/minute per user
- **Input Validation** - All endpoints validate & sanitize
- **HTTPS Only** - TLS 1.2+ required

---

## 📱 Bilingual Support

Both admin and mobile apps support **English** and **Malayalam (RTL)**:

```dart
// Access in any screen
final isMalayalam = context.isMalayalam;
final textDir = context.textDirection;

// Use in Text widgets
Text(
  isMalayalam ? 'നിരീക്ഷണം' : 'Observation',
  textDirection: isMalayalam ? TextDirection.rtl : TextDirection.ltr,
)

// Use in Row/Column for layout
Row(
  textDirection: isMalayalam ? TextDirection.rtl : TextDirection.ltr,
  children: [...],
)
```

---

## 🐛 Troubleshooting

### Backend Issues

**Backend won't start:**
```bash
# Check Node version (must be 18+)
node --version

# Check port 3000 is available
lsof -i :3000

# Verify .env has all variables
cat .env

# Check Supabase credentials
npm run db:status
```

**Database connection error:**
```bash
# Test connection directly
psql postgresql://[user]:[pass]@[host]/alif

# Reset local database
npm run db:reset

# Rerun migrations
npm run db:migrate
```

### Flutter Issues

**Build or run errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade

# Run with verbose output
flutter run -v

# Check Flutter installation
flutter doctor
```

**Compilation errors:**
```bash
# Format code
dart format lib/

# Check for errors
dart analyze

# Run tests to identify issues
flutter test --verbose
```

### API Connection Errors

**"Failed to connect to backend":**
1. Verify backend is running: `curl http://localhost:3000/api/health`
2. Check .env variables in backend
3. Verify CORS configuration
4. Check network connection

**"401 Unauthorized":**
1. Token may have expired (1-hour expiry)
2. Try logging out and back in
3. Check JWT in local storage/shared preferences

**"Database error":**
1. Check Supabase dashboard for status
2. Verify database URL in .env
3. Check Row-Level Security policies
4. Review database logs

---

## 📊 Data Models

### Activity Ratings

```
Level                  | Marks | Color
Excellent (ممتاز)     | 10    | Green
Satisfactory (جيد)    | 5     | Orange
Needs Improvement (ضعيف) | 2   | Yellow
Not Done (لم ينجز)    | 0     | Gray
```

### Daily Record Workflow

```
Student creates record
    ↓
Enters ratings for each activity
    ↓
Auto-save draft
    ↓
Submit for approval (locked)
    ↓
Parent/Teacher reviews
    ↓
Approved → Marks counted in progress
```

### Progress Calculation

```
Daily Marks = Sum of activity ratings
Completion % = (Activities with rating > 0) / Total activities × 100
Daily Score = Total marks / Max marks × 100

Weekly = Average of 7 daily records
Monthly = Average of 30 daily records
Leaderboard = Ranked by total marks (daily/weekly)
```

---

## 🚢 Deployment

### Backend Deployment (Docker)

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY src ./src
COPY dist ./dist
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Admin Panel Deployment (Vercel)

```bash
flutter build web --release
vercel --prod
```

### Mobile App Deployment

```bash
# Android
flutter build appbundle --release
# Upload to Google Play Console

# iOS
flutter build ios --release
# Upload to App Store Connect
```

---

## 📚 Additional Documentation

- **API Routes:** See `/backend/src/routes/` for detailed endpoint implementations
- **Database Schema:** Check Supabase dashboard for table structures
- **Components:** Review `/lib/design_system/components/` for usage examples
- **Services:** Study `/backend/src/services/` for business logic patterns

---

## 📞 Support & Issues

For problems or questions:

1. **Check Logs:**
   - Backend: `npm run logs` or check terminal output
   - Frontend: Open browser DevTools (F12) → Console tab

2. **Verify Setup:**
   - Run health checks: `npm run test:health`
   - Run tests: `flutter test`

3. **Debug:**
   - Add `print()` statements in Dart
   - Add `console.log()` in TypeScript
   - Use Supabase dashboard to inspect data

4. **Reset Everything:**
   ```bash
   backend: npm run db:reset && npm run db:seed
   admin: flutter clean && flutter pub get
   mobile: flutter clean && flutter pub get
   ```

---

## ✅ Checklist: Ready to Deploy?

- [ ] Backend health check passes: `npm run test:health` ✅
- [ ] Admin panel tests pass: `flutter test` ✅
- [ ] Mobile app tests pass: `flutter test` ✅
- [ ] All environment variables configured (.env)
- [ ] Database migrations applied
- [ ] Demo data seeded
- [ ] CORS configured for production URLs
- [ ] JWT secret configured securely
- [ ] HTTPS enabled on production
- [ ] Database backups configured
- [ ] Error logging/monitoring in place
- [ ] Rate limiting configured
- [ ] User acceptance testing completed

---

**Status:** ✅ Production Ready (Phase 1)  
**Version:** 1.0.0  
**Last Updated:** March 2026

