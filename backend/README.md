# Alif Online Moral School Backend

## Overview

Backend API for the Alif Online Moral School application. Built with Node.js, Express.js, Supabase, and Firebase.

## Technology Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Firebase Admin SDK + Supabase Auth
- **Language**: TypeScript
- **File Storage**: Supabase Storage

## Project Structure

```
backend/
├── src/
│   ├── config/             # Configuration files
│   │   ├── config.ts       # Main configuration
│   │   ├── supabase.ts     # Supabase client setup
│   │   └── firebase.ts     # Firebase admin setup
│   ├── controllers/        # Route controllers
│   ├── routes/             # API routes
│   ├── middleware/         # Custom middleware
│   ├── services/           # Business logic
│   ├── database/           # Database queries
│   ├── types/              # TypeScript types
│   └── app.ts              # Main application file
├── package.json
├── tsconfig.json
├── .env.example            # Environment variables template
└── README.md
```

## Setup Instructions

### Prerequisites

- Node.js 18+ and npm 9+
- Supabase account and project
- Firebase project
- Git

### Quick Start (30 minutes)

Follow the **Quick Setup Reference** for fastest setup:

📖 [Quick Setup Reference Guide](../docs/QUICK_SETUP_REFERENCE.md)

This guide walks you through:
1. ✅ Supabase setup (10 min)
2. ✅ Firebase setup (10 min)
3. ✅ .env configuration (5 min)
4. ✅ Verification (5 min)

### Detailed Setup Guides

For more detailed instructions:

| Step | Guide |
|------|-------|
| **Supabase Setup** | [SUPABASE_SETUP_STEP_BY_STEP.md](../docs/SUPABASE_SETUP_STEP_BY_STEP.md) |
| **Firebase Setup** | [FIREBASE_SETUP_STEP_BY_STEP.md](../docs/FIREBASE_SETUP_STEP_BY_STEP.md) |
| **Environment Variables** | [ENV_CONFIGURATION_GUIDE.md](../docs/ENV_CONFIGURATION_GUIDE.md) |

### Step-by-Step Installation

#### 1. Clone and Install

```bash
cd backend
npm install
```

#### 2. Set Up Supabase

See: [SUPABASE_SETUP_STEP_BY_STEP.md](../docs/SUPABASE_SETUP_STEP_BY_STEP.md)

- Create Supabase project
- Get API credentials
- Create database schema
- Enable authentication

#### 3. Set Up Firebase

See: [FIREBASE_SETUP_STEP_BY_STEP.md](../docs/FIREBASE_SETUP_STEP_BY_STEP.md)

- Create Firebase project
- Register web app
- Download service account
- Enable phone authentication

#### 4. Configure Environment

See: [ENV_CONFIGURATION_GUIDE.md](../docs/ENV_CONFIGURATION_GUIDE.md)

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your credentials from Supabase and Firebase
# See ENV_CONFIGURATION_GUIDE.md for detailed variable descriptions
```

#### 5. Start Development Server

```bash
npm run dev
```

Server will start at `http://localhost:3000`

You should see:
```
✅ Supabase schema is initialized
✅ Firebase Admin SDK initialized
🕌 Server running on http://localhost:3000
```

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm start` | Start production server |
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Build TypeScript to JavaScript |
| `npm run watch` | Watch TypeScript files and build |
| `npm run lint` | Run ESLint |
| `npm test` | Run tests |
| `npm run test:watch` | Run tests in watch mode |
| `npm run supabase:start` | Start local Supabase instance |
| `npm run supabase:db:push` | Push migrations to Supabase |
| `npm run firebase:init` | Initialize Firebase |

## API Endpoints

### Authentication
- `POST /api/auth/supabase-signin` - Exchange Supabase Google access token for app JWT
- `POST /api/auth/google-signin` - Legacy Firebase token exchange path
- `POST /api/auth/request-otp` - Legacy OTP request endpoint
- `POST /api/auth/verify-otp` - Legacy OTP verification endpoint
- `POST /api/auth/logout` - Logout user

### Admin (coming soon)
- `GET /api/admin/students` - List students
- `POST /api/admin/students` - Create student
- `GET /api/admin/teachers` - List teachers
- `POST /api/admin/teachers` - Create teacher
- ... more endpoints

### Student (coming soon)
- `GET /api/student/activities` - Get today's activities
- `POST /api/student/activities/log` - Log activity
- `GET /api/student/progress/daily` - Daily progress

### Teacher (coming soon)
- `GET /api/teacher/batches` - Get assigned batches
- `GET /api/teacher/students` - Get students
- ... more endpoints

## Database Schema

The database schema includes:

- **profiles** - User profiles with roles
- **students** - Student information
- **teachers** - Teacher information
- **batches** - Class batches
- **classes** - Classes within batches
- **activity_categories** - Activity categories (Prayer, Daily Routine, etc.)
- **activities** - Individual activities
- **activity_ratings** - Rating options (Excellent, Satisfactory, etc.)
- **activity_logs** - Daily activity logs
- **badges** - Achievement badges
- **student_badges** - Earned badges
- **notifications** - Notifications
- **parent_students** - Parent-student relationships

See `src/types/database.ts` for complete type definitions.

## Configuration

All configuration is managed through environment variables (`.env` file).

Key configurations:
- `SUPABASE_URL` & `SUPABASE_ANON_KEY` - Supabase credentials
- `FIREBASE_PROJECT_ID` - Firebase project
- `JWT_SECRET` - JWT signing secret
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)

See `.env.example` for all available options.

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test**
   ```bash
   npm run dev
   npm run test
   ```

3. **Build and lint**
   ```bash
   npm run build
   npm run lint
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add your feature"
   git push origin feature/your-feature-name
   ```

## Deployment

### Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

### Deploy to Heroku

```bash
# Install Heroku CLI
# https://devcenter.heroku.com/articles/heroku-cli

# Login
heroku login

# Create app
heroku create alif-school-api

# Deploy
git push heroku main
```

### Deploy to Railway / Render

Follow platform-specific instructions after connecting your Git repository.

## Security Considerations

- **Never commit `.env` file** - Use `.env.example` as template
- **Rotate JWT secret** regularly in production
- **Use environment-specific keys** for Firebase and Supabase
- **Enable CORS** only for trusted origins
- **Rate limiting** is configured by default
- **Input validation** should be added to all endpoints

## Monitoring and Logging

- Log level can be controlled via `LOG_LEVEL` env variable
- Logs are output in JSON format by default
- Monitor API health via `/health` endpoint

## Error Handling

Standard API response format:

```json
{
  "success": false,
  "error": "Error name",
  "message": "Error description"
}
```

## Contributing

1. Follow the existing code structure
2. Use TypeScript for type safety
3. Add tests for new features
4. Update documentation

## License

MIT

## Support

For issues and questions, please contact the Alif School development team.
