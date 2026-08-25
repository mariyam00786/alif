# Phase 1 Foundation - Alif Online Moral School

This document freezes the product foundation before implementation begins.
It defines the exact scope for the first build, the branding rules, the digital Ihthisab model, and the design system constraints that every screen must follow.

## 1. Phase 1 Goal

Build a stable product foundation that makes the rest of the app consistent and reusable.

The deliverables for Phase 1 are:
- Final product scope for the MVP
- Locked branding and visual direction
- Digital Ihthisab chart data model
- Reusable design system tokens and components
- Shared patterns for Malayalam and English UI

## 2. Exact Scope From FRD and Paper Sample

### In Scope For Phase 1
- Authentication and role-based access foundation
- Student profile and parent linkage foundation
- Teacher profile and batch assignment foundation
- Daily Ihthisab activity structure
- Rating and scoring rules
- Quantity-based activities such as Quran page counts
- Calendar-based daily logs
- Weekly and monthly progress summaries
- Leaderboard-ready scoring model
- Badge-ready achievement model
- Admin-ready master data for batches, classes, categories, and activities

### Out Of Scope For Phase 1
- Full Flutter admin panel implementation
- Full student mobile app implementation
- Push notification workflows
- PDF and Excel exports
- Advanced analytics and AI insights
- Parent-teacher messaging
- Attendance module
- Fee management

### MVP Rule
If a feature does not directly support daily marking, scoring, progress tracking, or basic administration of the Ihthisab chart, it stays out of Phase 1.

## 3. Branding Lock

### Brand Direction
The product should feel:
- Calm
- Trustworthy
- Educational
- Islamic
- Child-friendly without looking childish

### Color Direction
Use the already defined design system as the source of truth:
- Primary green: `#2E7D32`
- Secondary gold: `#FFA000`
- Success / Excellent: `#4CAF50`
- Satisfactory: `#FFC107`
- Needs Improvement: `#FF9800`
- Not Done / Neutral: `#9E9E9E`

### Typography Direction
Use bilingual typography consistently:
- English: Poppins or Roboto style scale
- Malayalam: Noto Sans Malayalam or Manjari style scale

### Logo Usage Rules
- Use the same logo across admin, mobile, and backend-facing marketing screens
- Keep logo colors aligned with the green/gold palette
- Do not introduce a competing accent palette
- Keep the logo on light backgrounds by default

### UI Tone
- Clean and structured
- Soft spacing and rounded cards
- No heavy gradients
- No flashy neon colors
- High contrast for readability

## 4. Digital Ihthisab Data Model

The paper sample becomes a structured daily log model.

### Core Structure
- A student has one daily record per date
- Each daily record contains multiple category groups
- Each activity inside a category stores one rating or one quantity
- Marks are computed from the selected rating or quantity rule
- The log is saved with the student, date, and approval state

### Suggested Logical Model

#### DailyRecord
- `id`
- `student_id`
- `log_date`
- `submitted_by`
- `parent_approved`
- `total_marks`
- `notes`
- `created_at`
- `updated_at`

#### DailyRecordItem
- `id`
- `daily_record_id`
- `activity_id`
- `rating_id`
- `quantity`
- `marks_earned`
- `item_notes`

#### ActivityCategory
- Example: Prayer, Sunnah Prayers, Daily Routine

#### Activity
- Example: Subhi, Zuhr, Quran Recitation, Dhikr & Duas

#### ActivityRating
- Example: Excellent, Satisfactory, Needs Improvement, Not Done

### Paper Sample Mapping

#### Sample 1: Prayer rows
The paper chart has prayer rows like Subhi, Zuhr, Asr, Maghrib, and Isha.

Digital mapping:
- Category: Prayer
- Activities: Subhi, Zuhr, Asr, Maghrib, Isha
- Ratings: Excellent, Satisfactory, Needs Improvement, Not Done

#### Sample 2: Sunnah prayer rows
The paper chart has before/after prayer rows.

Digital mapping:
- Category: Sunnah Prayers
- Activities: Before Subhi, Before Zuhr, After Zuhr, After Maghrib, After Isha

#### Sample 3: Quran page counting
The paper sample includes quantity-based scoring for Quran reading.

Digital mapping:
- Category: Daily Routine
- Activity: Quran Recitation
- Input type: quantity
- Rules: 10 pages, 5 pages, 2 pages, or configurable quantity bands

### Scoring Rules
- Excellent = 10 marks
- Satisfactory = 5 marks
- Needs Improvement = 2 marks
- Not Done = 0 marks

Special activities may override the default rule when needed.

## 5. Reusable Design System Rules

### Design System Must Be The Source Of Truth
All screens must use the shared tokens and not hardcode visual values.

### Mandatory Reusable Tokens
- Colors
- Typography
- Spacing
- Border radius
- Shadows
- Z-index
- Motion timing

### Mandatory Reusable Components
- Button
- Text input
- Select dropdown
- Card
- Badge
- Table
- Modal
- Tabs
- Date picker wrapper
- Rating selector
- Quantity input
- Student picker
- Progress summary card

### Reuse Rules
- Do not create a new visual style for each module
- Do not introduce one-off colors or spacing values
- Keep form controls and cards consistent across admin and mobile
- Reuse the same rating controls everywhere the user marks an activity

## 6. Language and Localization Rules

- Malayalam is primary for content and activity names
- English is always available for navigation and admin clarity
- Every activity master record should support `name` and `name_ml`
- Every report and notification should support bilingual output
- Text direction stays LTR, but Malayalam typography must be supported natively

## 7. Module Boundaries For Phase 1

### Foundation Modules
- Auth and role detection
- Profile and student linkage
- Master data setup
- Daily log data model
- Score computation
- Shared UI tokens

### Deferred Modules
- Reporting dashboards
- Notification sending
- Achievements automation
- Full admin workflows
- Parent switcher UI
- Teacher analytics screens

## 8. Implementation Order

1. Confirm branding and design tokens
2. Finalize daily record data model
3. Build reusable UI primitives
4. Create master tables and scoring rules
5. Connect the data model to the backend
6. Add seed data for default activities
7. Validate the model against the paper chart

## 9. Acceptance Criteria For Phase 1

Phase 1 is complete when:
- The logo and brand colors are fixed
- Malayalam and English typography rules are set
- The paper chart has a one-to-one digital model
- Reusable components are defined and used consistently
- Scoring rules are documented and deterministic
- No screen depends on hardcoded visual styling

## 10. Reference To Existing Foundation

The current design tokens already support this phase:
- Colors: [design-system/colors.ts](../design-system/colors.ts)
- Typography: [design-system/typography.ts](../design-system/typography.ts)
- Spacing: [design-system/spacing.ts](../design-system/spacing.ts)
- Theme: [design-system/theme.ts](../design-system/theme.ts)

The current database types already cover the main entities:
- [backend/src/types/database.ts](../backend/src/types/database.ts)

## 11. Resulting Product Shape

After Phase 1, the app should already know:
- What it is tracking
- How it is scored
- How the paper chart maps to data
- How the UI looks and behaves
- How Malayalam and English are supported

That makes later work on admin, mobile, teacher, reports, and notifications much faster and more consistent.
