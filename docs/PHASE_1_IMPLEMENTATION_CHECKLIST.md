# Phase 1 Implementation Checklist

## Overview

This checklist breaks Phase 1 into concrete tasks organized by component. Complete tasks in order within each section. Each task is self-contained and testable.

**Total estimated duration:** 2-3 weeks depending on team size.

---

## Part 1: Design System Foundation (Days 1-2)

### Goal
Make the design system complete, documented, and immediately usable by all teams.

### Tasks

- [ ] **1.1 - Review and Lock Colors**
  - File: `design-system/colors.ts`
  - Confirm green `#2E7D32`, gold `#FFA000`, ratings, and neutral palette
  - Export a `ColorPalette` constant for use in components
  - Document each color's purpose (primary, secondary, success, warning, etc.)
  - Test: All colors export without errors

- [ ] **1.2 - Confirm Typography Scale**
  - File: `design-system/typography.ts`
  - Ensure Poppins and Noto Sans Malayalam are listed
  - Define sizes: xs, sm, base, lg, xl, 2xl
  - Define weights: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)
  - Test: Typography exports with no errors; heading and body styles defined

- [ ] **1.3 - Finalize Spacing Scale**
  - File: `design-system/spacing.ts`
  - Confirm scale: 0, 4px, 8px, 12px, 16px, 20px, 24px, 32px, 48px, 64px
  - Document usage: gaps, padding, margins
  - Test: Spacing constants export; no conflicting values

- [ ] **1.4 - Create Component Token Documentation**
  - File: `design-system/COMPONENT_TOKENS.md`
  - Define reusable component styles:
    - Button: primary, secondary, outline, text variants
    - Input: default, focus, error, disabled states
    - Card: shadow, border, spacing rules
    - Badge: success, warning, error, info, neutral variants
    - Modal: z-index, overlay opacity, border radius
    - Table: row height, cell padding, header background
  - Test: Documentation is clear and complete

- [ ] **1.5 - Update Design System README**
  - File: `design-system/README.md`
  - Add: "How to use colors in your code"
  - Add: "How to apply typography"
  - Add: "Component token reference"
  - Add: "Bilingual content examples"
  - Test: README is clear and includes examples

---

## Part 2: Backend - Data Model & Core Services (Days 3-5)

### Goal
Establish the backend foundation with the Ihthisab data model, core services, and scoring engine.

### Tasks

- [ ] **2.1 - Extend Database Types**
  - File: `backend/src/types/database.ts`
  - Add types for:
    - `DailyRecord` (student daily entry)
    - `DailyRecordItem` (individual activity in daily record)
    - `ActivityScore` (computed marks for activity)
  - Ensure all types have nullable and optional fields where appropriate
  - Test: `npm run build` succeeds with no type errors

- [ ] **2.2 - Create Activity Scoring Service**
  - File: `backend/src/services/scoring-service.ts`
  - Function: `calculateActivityMarks(activityId, ratingId, quantity): number`
  - Implement default rules: Excellent=10, Satisfactory=5, NeedsImprovement=2, NotDone=0
  - Allow overrides from database activity_ratings table
  - Test: Unit tests for all rating types and custom quantities

- [ ] **2.3 - Create Activity Logging Service**
  - File: `backend/src/services/activity-logging-service.ts`
  - Function: `createDailyRecord(studentId, logDate, items[]): DailyRecord`
  - Function: `updateDailyRecord(recordId, items[]): DailyRecord`
  - Compute total marks from all items
  - Validate that all activities in a day are unique
  - Test: Unit tests for creation, update, and validation

- [ ] **2.4 - Create Student Progress Service**
  - File: `backend/src/services/progress-service.ts`
  - Function: `getDailyMarks(studentId, date): number`
  - Function: `getWeeklyTotal(studentId, startDate): number`
  - Function: `getMonthlyTotal(studentId, month): number`
  - Function: `getRank(studentId, batchId, date): number`
  - Test: Unit tests for all date ranges

- [ ] **2.5 - Create Activity Master Service**
  - File: `backend/src/services/activity-service.ts`
  - Function: `getCategories(): ActivityCategory[]`
  - Function: `getActivitiesByCategory(categoryId): Activity[]`
  - Function: `getRatings(activityId): ActivityRating[]`
  - Cache results in memory with 5-minute TTL
  - Test: Unit tests; caching is verified

- [ ] **2.6 - Create Authentication Service**
  - File: `backend/src/services/auth-service.ts`
  - Function: `verifyOTP(phone, code): {userId, role}`
  - Function: `createToken(userId): jwt`
  - Function: `getUserRole(userId): 'student'|'parent'|'teacher'|'admin'`
  - Integrate with Supabase Auth and Firebase
  - Test: Unit tests for OTP flow; token creation and verification

- [ ] **2.7 - Create Seed Data Script**
  - File: `backend/scripts/seed-activities.ts`
  - Seed tables:
    - `activity_categories`: Prayer, Sunnah Prayers, Daily Routine, Quran, Dhikr, etc.
    - `activities`: Subhi, Zuhr, Asr, Maghrib, Isha, Quran Recitation, etc.
    - `activity_ratings`: Excellent, Satisfactory, Needs Improvement, Not Done
  - Include Malayalam and English names for each
  - Test: Run script; verify data in Supabase

- [ ] **2.8 - Create API Health Endpoint**
  - File: `backend/src/routes/health.ts`
  - Endpoint: `GET /health`
  - Response: `{status, timestamp, version}`
  - Test: Endpoint returns 200 with correct schema

---

## Part 3: Backend - API Routes (Days 6-7)

### Goal
Build the REST endpoints that the admin panel and mobile app will use.

### Tasks

- [ ] **3.1 - Create Daily Record Endpoints**
  - File: `backend/src/routes/daily-records.ts`
  - `POST /api/daily-records` - Create new daily record
  - `GET /api/daily-records/:recordId` - Get single record
  - `PUT /api/daily-records/:recordId` - Update record
  - `GET /api/students/:studentId/daily-records` - Get records for student
  - Validate: student ownership, date uniqueness
  - Test: All endpoints return 200/201/400 correctly

- [ ] **3.2 - Create Activity Endpoints**
  - File: `backend/src/routes/activities.ts`
  - `GET /api/activities/categories` - List all categories
  - `GET /api/activities/categories/:categoryId` - Get category details
  - `GET /api/activities` - List all activities with filters
  - `GET /api/activities/:activityId/ratings` - Get rating options
  - Test: All endpoints return correct data structure

- [ ] **3.3 - Create Student Progress Endpoints**
  - File: `backend/src/routes/progress.ts`
  - `GET /api/students/:studentId/progress/daily/:date` - Daily marks
  - `GET /api/students/:studentId/progress/weekly/:startDate` - Weekly summary
  - `GET /api/students/:studentId/progress/monthly/:month` - Monthly summary
  - `GET /api/batches/:batchId/leaderboard/:date` - Batch leaderboard
  - Test: All endpoints return correct summary format

- [ ] **3.4 - Create Student Management Endpoints**
  - File: `backend/src/routes/students.ts`
  - `POST /api/students` - Create student (admin only)
  - `GET /api/students/:studentId` - Get student profile
  - `PUT /api/students/:studentId` - Update student (admin only)
  - `GET /api/batches/:batchId/students` - List batch students
  - Validate: Admin role for create/update
  - Test: Role-based access works

- [ ] **3.5 - Create Master Data Endpoints**
  - File: `backend/src/routes/master-data.ts`
  - `GET /api/batches` - List all batches
  - `GET /api/classes` - List all classes
  - `POST /api/batches` - Create batch (admin only)
  - `POST /api/classes` - Create class (admin only)
  - Validate: Admin role
  - Test: CRUD operations work

- [ ] **3.6 - Add Error Handling Middleware**
  - File: `backend/src/middleware/error-handler.ts`
  - Catch all errors and return consistent error format
  - Format: `{success: false, error: string, statusCode: number}`
  - Test: All endpoints return errors in correct format

- [ ] **3.7 - Add Authentication Middleware**
  - File: `backend/src/middleware/auth.ts`
  - Middleware: `verifyToken()` - validate JWT
  - Middleware: `requireRole(role)` - check user role
  - Attach user info to `req.user`
  - Test: Protected endpoints reject invalid tokens

---

## Part 4: Design System - Reusable Components (Days 8-9)

### Goal
Create Flutter widget library that all screens will use.

### Tasks

- [ ] **4.1 - Create Flutter Button Component**
  - File: `design-system/lib/components/button.dart`
  - Variants: primary, secondary, outline, text
  - Sizes: small, medium, large
  - States: enabled, disabled, loading
  - Props: onPressed, child, variant, size, disabled
  - Test: All variants render correctly

- [ ] **4.2 - Create Flutter Input Component**
  - File: `design-system/lib/components/input.dart`
  - Types: text, phone, password, email
  - States: default, focus, error, disabled
  - Props: value, onChanged, error, label, placeholder
  - Supports Malayalam keyboard
  - Test: All states display correctly

- [ ] **4.3 - Create Flutter Card Component**
  - File: `design-system/lib/components/card.dart`
  - Props: child, padding, shadow, onTap
  - Rounded borders, consistent shadow
  - Support nested cards
  - Test: Cards display with correct styling

- [ ] **4.4 - Create Flutter Badge Component**
  - File: `design-system/lib/components/badge.dart`
  - Variants: success, warning, error, info, neutral
  - Props: label, variant
  - Display activity rating scores
  - Test: All rating types display

- [ ] **4.5 - Create Flutter Rating Selector**
  - File: `design-system/lib/components/rating_selector.dart`
  - Props: ratings[], onSelect(rating)
  - Visual feedback for selected rating
  - Support for activity-specific colors
  - Test: Selection works and shows visual feedback

- [ ] **4.6 - Create Flutter Quantity Input**
  - File: `design-system/lib/components/quantity_input.dart`
  - Props: value, onChanged, min, max, unit (e.g., "pages")
  - +/- buttons or text input
  - Validate min/max
  - Test: Increment/decrement and validation work

- [ ] **4.7 - Create Flutter Progress Summary Card**
  - File: `design-system/lib/components/progress_summary.dart`
  - Props: totalMarks, completionPercent, date
  - Display marks earned and rank
  - Bilingual support (Malayalam/English)
  - Test: Component displays all data correctly

- [ ] **4.8 - Create Flutter Theme Provider**
  - File: `design-system/lib/theme.dart`
  - Export: `AlifTheme` with all color and typography tokens
  - Use in `ThemeData` and `MaterialColor`
  - Make available globally via provider or constant
  - Test: Theme applies to all widgets

---

## Part 5: Admin Panel - Core Screens (Days 10-12)

### Goal
Build the admin panel foundation with master data management screens.

### Tasks

- [ ] **5.1 - Set Up Admin Panel Project Structure**
  - Directory: `admin-panel/lib/`
  - Create: `config/`, `screens/`, `widgets/`, `services/`
  - Create: `main.dart` with basic navigation
  - Create: `pubspec.yaml` with dependencies:
    - supabase_flutter
    - firebase_core
    - provider
    - intl (for localization)
  - Test: App launches without errors

- [ ] **5.2 - Create Admin Authentication Screen**
  - File: `admin-panel/lib/screens/login_screen.dart`
  - Input: phone number
  - OTP verification flow
  - Redirect to dashboard on success
  - Validate: admin role required
  - Test: Login and OTP flow works

- [ ] **5.3 - Create Admin Dashboard Screen**
  - File: `admin-panel/lib/screens/dashboard_screen.dart`
  - Display:
    - Total students count
    - Active batches count
    - Batch dropdown selector
    - Quick leaderboard (top 5 students)
  - Use progress summary card
  - Test: Dashboard loads data correctly

- [ ] **5.4 - Create Batch Management Screen**
  - File: `admin-panel/lib/screens/batch_management_screen.dart`
  - List batches in table/list
  - Create new batch (modal form)
  - Edit batch name and capacity
  - Delete batch (with confirmation)
  - Test: CRUD operations work

- [ ] **5.5 - Create Student Management Screen**
  - File: `admin-panel/lib/screens/student_management_screen.dart`
  - Filter by batch/class
  - List students with status
  - Create new student (form with batch selector)
  - Edit student name, parent phone
  - Delete student (with confirmation)
  - Test: CRUD operations work

- [ ] **5.6 - Create Activity Configuration Screen**
  - File: `admin-panel/lib/screens/activity_config_screen.dart`
  - List activity categories
  - Edit category names (Malayalam/English)
  - Reorder categories by drag
  - Add/remove activities in each category
  - Test: All operations work; order persists

- [ ] **5.7 - Create Rating Configuration Screen**
  - File: `admin-panel/lib/screens/rating_config_screen.dart`
  - For each activity, configure ratings
  - Edit: rating name, marks, color
  - Ensure consistent rating names (Excellent, etc.)
  - Test: Ratings save correctly

- [ ] **5.8 - Create API Service Layer**
  - File: `admin-panel/lib/services/api_service.dart`
  - Methods for all backend endpoints
  - Handle errors and auth failures
  - Cache API responses
  - Test: All methods work; errors handled gracefully

- [ ] **5.9 - Add Navigation and Menu**
  - File: `admin-panel/lib/widgets/admin_drawer.dart`
  - Links to: Dashboard, Students, Batches, Activities, Ratings, Reports
  - Show current user role
  - Add logout button
  - Test: Navigation works; user info displays

---

## Part 6: Mobile App - Core Screens (Days 13-15)

### Goal
Build the student/parent mobile app foundation with daily marking and progress screens.

### Tasks

- [ ] **6.1 - Set Up Mobile App Project Structure**
  - Directory: `mobile_app/lib/`
  - Create: `config/`, `screens/`, `widgets/`, `services/`
  - Create: `main.dart` with basic navigation
  - Create: `pubspec.yaml` with dependencies:
    - supabase_flutter
    - firebase_core
    - provider
    - intl
  - Test: App launches on device/emulator

- [ ] **6.2 - Create Mobile Authentication Screen**
  - File: `mobile_app/lib/screens/login_screen.dart`
  - Input: phone number
  - OTP verification
  - Save token to device
  - Redirect to dashboard on success
  - Test: Login flow works end-to-end

- [ ] **6.3 - Create Student Selector Screen**
  - File: `mobile_app/lib/screens/student_selector_screen.dart`
  - For parent: list children; select one
  - For student: auto-select self
  - Display student name and batch
  - Test: Selection persists; correct student data loads

- [ ] **6.4 - Create Daily Marking Screen**
  - File: `mobile_app/lib/screens/daily_marking_screen.dart`
  - Display today's date (editable for historical entry)
  - List all activity categories
  - For each activity in category: show rating selector or quantity input
  - Button: Save Daily Record
  - Validate: all activities filled
  - Test: Daily record saves; data persists

- [ ] **6.5 - Create Daily Summary Screen**
  - File: `mobile_app/lib/screens/daily_summary_screen.dart`
  - Display:
    - Today's date
    - Total marks earned
    - Breakdown by category
    - Rank in batch
  - Use progress summary card
  - Button: Edit Today's Record (if not submitted)
  - Test: Summary displays correct data

- [ ] **6.6 - Create Weekly Progress Screen**
  - File: `mobile_app/lib/screens/weekly_progress_screen.dart`
  - Calendar view: show marks for each day
  - Color code: green (excellent), yellow (satisfactory), orange (needs improvement)
  - Display weekly total
  - Tap day to view details
  - Test: Calendar displays correctly; taps work

- [ ] **6.7 - Create Monthly Progress Screen**
  - File: `mobile_app/lib/screens/monthly_progress_screen.dart`
  - Display month picker
  - Show monthly total marks
  - Heatmap: color intensity by marks
  - Display rank in batch for month
  - Test: Month switching works; data updates

- [ ] **6.8 - Create Batch Leaderboard Screen**
  - File: `mobile_app/lib/screens/leaderboard_screen.dart`
  - Date picker: select date
  - List students ranked by marks for that date
  - Highlight current student
  - Show marks and rank position
  - Test: Leaderboard loads and displays ranks

- [ ] **6.9 - Create Mobile API Service**
  - File: `mobile_app/lib/services/api_service.dart`
  - Methods: login, getDailyRecords, saveDailyRecord, getProgress, getLeaderboard
  - Local caching with Hive
  - Offline support for recent data
  - Test: All methods work; caching works

- [ ] **6.10 - Add Mobile Navigation**
  - File: `mobile_app/lib/widgets/bottom_nav.dart`
  - Bottom navigation: Home, Mark, Progress, Leaderboard, Profile
  - Consistent icon styling
  - Active/inactive states
  - Test: Navigation works; state persists

---

## Part 7: Integration & Validation (Days 16-17)

### Goal
Ensure all components work together and the Phase 1 scope is complete.

### Tasks

- [ ] **7.1 - Test Full Backend Flow**
  - Start backend: `npm run dev`
  - Call each API endpoint with Postman/Insomnia
  - Verify: health, activities, daily records, progress
  - Verify: errors are formatted correctly
  - Document: API examples in Postman collection

- [ ] **7.2 - Test Admin Panel Integration**
  - Configure admin panel with backend URL
  - Login as admin
  - Create batch, add students, configure activities
  - Save seed data
  - Verify: data persists in Supabase

- [ ] **7.3 - Test Mobile App Integration**
  - Configure mobile app with backend URL
  - Login as student
  - Create daily record with all activities
  - View progress screens
  - Verify: data syncs with backend

- [ ] **7.4 - Test Design System Usage**
  - Verify: all screens use design tokens
  - Check: no hardcoded colors or spacing
  - Verify: typography follows scale
  - Verify: buttons and inputs are consistent

- [ ] **7.5 - Test Bilingual Support**
  - Add Malayalam strings to all text fields
  - Verify: Malayalam renders correctly
  - Verify: activity names display in both languages
  - Test: language switcher works (if implemented)

- [ ] **7.6 - Test Data Model Against Paper Chart**
  - Map paper Ihthisab chart to digital record
  - Create sample daily record matching paper chart
  - Verify: all fields correspond
  - Verify: marks calculation matches paper rules

- [ ] **7.7 - Write Integration Tests**
  - File: `backend/tests/integration.test.ts`
  - Test: full flow from login to daily record to progress
  - Test: scoring rules
  - Test: leaderboard ranking
  - Run: `npm test`

- [ ] **7.8 - Document API Schema**
  - File: `docs/API_SCHEMA.md`
  - Endpoint: request/response examples
  - Error codes and meanings
  - Authentication flow
  - Pagination (if applicable)

---

## Part 8: Cleanup & Documentation (Days 18)

### Goal
Finalize Phase 1 with clear documentation and ready-to-use foundation.

### Tasks

- [ ] **8.1 - Create Backend README**
  - File: `backend/README.md`
  - How to run: `npm run dev`
  - Project structure
  - Services overview
  - API endpoints quick reference

- [ ] **8.2 - Create Admin Panel README**
  - File: `admin-panel/README.md`
  - How to run: `flutter run -d chrome`
  - Screen overview
  - Configuration steps
  - Troubleshooting

- [ ] **8.3 - Create Mobile App README**
  - File: `mobile_app/README.md`
  - How to run: `flutter run`
  - Screen overview
  - Configuration steps
  - Troubleshooting

- [ ] **8.4 - Update Main README**
  - File: `README.md`
  - Link to Phase 1 completion checklist
  - Update status to "Phase 1 Complete"
  - Add quick start for all three components

- [ ] **8.5 - Create Database Migration Notes**
  - File: `docs/MIGRATIONS.md`
  - List all tables created
  - Seed data reference
  - How to add new activities

- [ ] **8.6 - Add Code Comments**
  - Ensure: all services have JSDoc comments
  - Ensure: all API endpoints have descriptions
  - Ensure: complex logic has inline comments

- [ ] **8.7 - Final Testing Checklist**
  - [ ] Backend health endpoint works
  - [ ] Admin can login and see dashboard
  - [ ] Student can login and mark activities
  - [ ] Daily marks calculate correctly
  - [ ] Weekly/monthly progress displays
  - [ ] Leaderboard shows correct ranking
  - [ ] All text is bilingual-ready

- [ ] **8.8 - Phase 1 Sign-Off**
  - All tasks complete
  - Documentation complete
  - No TODOs left in code
  - Ready for Phase 2 (Flutter admin UI, mobile UI, reports)

---

## Success Criteria

Phase 1 is complete when:
- ✅ Design system is locked and documented
- ✅ Backend API is running and tested
- ✅ Admin panel manages master data
- ✅ Mobile app marks activities and shows progress
- ✅ Data model maps to paper Ihthisab chart
- ✅ Scoring rules work correctly
- ✅ All components use shared design tokens
- ✅ Bilingual support is baked in
- ✅ Complete documentation exists
- ✅ No hardcoded visual styling in any component

---

## Team Assignments

**Recommended split:**
- **Backend developer**: Tasks 2.x, 3.x, 7.1, 8.1
- **Design system / Flutter lead**: Tasks 1.x, 4.x, 8.2, 8.3
- **Admin panel developer**: Tasks 5.x, 7.2, 8.2
- **Mobile app developer**: Tasks 6.x, 7.3, 8.3

All developers collaborate on integration (7.x) and final docs (8.x).

---

## Git Workflow

For each task:
```bash
git checkout -b task/task-number-short-name
# Work on task
git commit -m "feat: task number - brief description"
git push origin task/task-number-short-name
# Create pull request, merge
```

Example:
```bash
git checkout -b task/2-1-database-types
# Add DailyRecord type
git commit -m "feat: 2.1 - add daily record database types"
git push origin task/2-1-database-types
```

---

## Time Tracking

Keep a simple log:
- Task start date
- Task end date
- Actual vs. estimated time
- Blockers or notes

This helps refine estimates for Phase 2.

---

**Next Phase:** Once Phase 1 is complete, Phase 2 focuses on:
- Admin panel UI refinement
- Mobile app UI refinement
- Reporting dashboards
- Notification system
- Badge/achievement automation

