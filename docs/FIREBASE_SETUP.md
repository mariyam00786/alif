# Alif Online Moral School - Complete Application Setup Guide

## Firebase Setup Guide

### Prerequisites

- Firebase account (https://console.firebase.google.com)
- Firebase CLI installed (`npm install -g firebase-tools`)

### Setup Steps

#### 1. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Create a project"
3. Fill in project name: `alif-school`
4. Enable Google Analytics (optional)
5. Create project

#### 2. Get Service Account Key

1. Go to **Project Settings** (gear icon)
2. Go to **Service Accounts** tab
3. Click "Generate New Private Key"
4. Save as `firebase-service-account.json` in backend directory

#### 3. Get Firebase Configuration

1. Click "Add app" → Select "Web"
2. Copy the configuration object
3. Add to `.env` file in backend directory

#### 4. Enable Authentication

1. Go to **Authentication** in sidebar
2. Click "Get Started"
3. Enable **Phone** provider for OTP
4. Configure phone verification settings

#### 5. Set Up Cloud Messaging (FCM)

1. Go to **Cloud Messaging** tab
2. Copy **Server Key** and **Sender ID**
3. Add to configuration

#### 6. Deploy Rules (Optional)

Define Firebase Security Rules for Realtime Database:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "notifications": {
      ".read": "auth.uid != null",
      ".write": "root.child('roles').child(auth.uid).val() === 'admin'"
    }
  }
}
```

## Full Setup Checklist

### Backend Setup

- [ ] Clone repository
- [ ] Run `npm install` in backend directory
- [ ] Create `.env` file from `.env.example`
- [ ] Set up Supabase project
- [ ] Set up Firebase project
- [ ] Initialize database schema
- [ ] Run `npm run dev` to start server

### Admin Panel Setup

- [ ] Navigate to admin-panel directory
- [ ] Run `npm install`
- [ ] Configure Supabase and Firebase credentials
- [ ] Run development server

### Design System

- [ ] Review design tokens in `design-system/`
- [ ] Ensure consistent use across frontend applications

### Mobile App

- [ ] Flutter SDK installed
- [ ] Configure Firebase for Flutter
- [ ] Set up Supabase SDK for Flutter
- [ ] Create Flutter app using design system tokens

## Project Structure

```
alifschool/
├── design-system/          # Shared design system
│   ├── colors.ts          # Color palette
│   ├── typography.ts      # Typography scale
│   ├── spacing.ts         # Spacing system
│   ├── theme.ts           # Master theme
│   └── README.md          # Design system docs
│
├── backend/               # Node.js/Express API
│   ├── src/
│   │   ├── config/       # Firebase, Supabase config
│   │   ├── controllers/  # Request handlers
│   │   ├── routes/       # API routes
│   │   ├── services/     # Business logic
│   │   ├── types/        # TypeScript types
│   │   └── app.ts        # Express app
│   ├── package.json
│   ├── tsconfig.json
│   ├── .env.example
│   └── README.md
│
├── admin-panel/           # Flutter Web admin panel
│   ├── lib/
│   │   ├── config/       # Config files
│   │   ├── screens/      # Admin screens
│   │   ├── widgets/      # Reusable widgets
│   │   └── main.dart
│   └── pubspec.yaml
│
├── mobile_app/            # Flutter mobile app
│   ├── lib/
│   │   ├── config/
│   │   ├── screens/      # Student/Teacher screens
│   │   ├── widgets/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── docs/                  # Documentation
│   ├── SUPABASE_SETUP.md
│   ├── FIREBASE_SETUP.md
│   ├── API_DOCUMENTATION.md
│   └── DESIGN_SYSTEM.md
│
└── .github/               # GitHub configuration
    └── workflows/         # CI/CD workflows
```

## Technology Stack Summary

| Component | Technology |
|-----------|-----------|
| **Mobile App** | Flutter (iOS/Android) |
| **Admin Panel** | Flutter Web |
| **Backend API** | Node.js + Express.js + TypeScript |
| **Database** | Supabase (PostgreSQL) |
| **Authentication** | Firebase + Supabase Auth |
| **File Storage** | Supabase Storage |
| **Push Notifications** | Firebase Cloud Messaging |
| **Design System** | Centralized token-based system |

## Quick Start

### Start Backend Development

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your credentials
npm run dev
```

Server runs at `http://localhost:3000`

### Start Admin Panel

```bash
cd admin-panel
flutter pub get
flutter run -d chrome  # Or your device
```

### Start Mobile App

```bash
cd mobile-app
flutter pub get
flutter run  # iOS/Android device
```

## Key Features

### Student/Parent Module
- ✅ Daily activity tracking (Ihthisab chart)
- ✅ Progress visualization (charts, heatmap)
- ✅ Leaderboard
- ✅ Badge system
- ✅ Parent dashboard (multiple children)

### Teacher Module
- ✅ Monitor student progress
- ✅ Batch analytics
- ✅ Add remarks/feedback
- ✅ Send notifications

### Admin Module
- ✅ Student management
- ✅ Teacher management
- ✅ Batch/Class management
- ✅ Activity configuration
- ✅ Scoring/rating rules
- ✅ Reports and exports
- ✅ Notification management

### System Features
- ✅ Bilingual support (Malayalam/English)
- ✅ OTP-based authentication
- ✅ Push notifications
- ✅ Offline support (mobile)
- ✅ Data export (PDF/Excel)
- ✅ Row-level security (RLS)

## Development Guidelines

### Code Quality

- Use TypeScript for type safety
- Follow ESLint configuration
- Write unit tests for critical functions
- Use consistent naming conventions

### Git Workflow

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "feat: description"`
3. Push: `git push origin feature/your-feature`
4. Create pull request

### Commit Message Format

```
feat: add new feature
fix: fix a bug
docs: update documentation
style: formatting changes
refactor: code restructuring
test: add tests
chore: maintenance tasks
```

## Deployment

### Backend Deployment

Supported platforms:
- Vercel (recommended for serverless)
- Railway
- Heroku
- AWS/Google Cloud
- Docker

### Admin/Mobile App Deployment

- **Android**: Google Play Store
- **iOS**: Apple App Store
- **Web**: Vercel, Netlify, Firebase Hosting

## Environment Variables

All sensitive configuration is managed through environment variables:

- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (backend only)
- `FIREBASE_PROJECT_ID` - Firebase project ID
- Firebase service account credentials
- JWT secret
- CORS origins
- etc.

**Never commit `.env` files to version control.**

## Monitoring and Logging

- Application logs: Check console output
- Supabase logs: View in Supabase dashboard
- Firebase logs: View in Firebase console
- Error tracking: Integration with Sentry (optional)

## Support and Documentation

- [Design System README](./design-system/README.md)
- [Backend README](./backend/README.md)
- [Supabase Setup Guide](./docs/SUPABASE_SETUP.md)
- [Firebase Setup Guide](./docs/FIREBASE_SETUP.md)
- [API Documentation](./docs/API_DOCUMENTATION.md)
- [Functional Requirements](./docs/FRD.md)

## Team Contact

For questions or issues:
- Development: development@alifschool.com
- Design: design@alifschool.com
- DevOps: devops@alifschool.com

## License

MIT License - See LICENSE file for details

## Contributing

Please read CONTRIBUTING.md for guidelines on how to contribute to this project.

---

**Last Updated**: June 17, 2026  
**Version**: 1.0.0  
**Status**: Development

