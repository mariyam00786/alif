<p align="center">
  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:0f2027,50:203a43,100:2c5364&height=220&section=header&text=Adhila%20K%20S&fontSize=48&fontColor=ffffff&animation=fadeIn&fontAlignY=38&desc=Full-Stack%20Developer%20%7C%20Next.js%20%7C%20MERN&descAlignY=58&descSize=18&descColor=a8d8ea" />
</p>

<p align="center">
  <!-- TODO: LinkedIn link കിട്ടുമ്പോൾ താഴെയുള്ള line uncomment ചെയ്യുക -->
  <!-- <a href="YOUR_LINKEDIN_URL">
    <img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=flat-square&logo=linkedin&logoColor=white" />
  </a> -->
  <a href="mailto:adhilasyedmuhammed@gmail.com">
    <img src="https://img.shields.io/badge/Gmail-EA4335?style=flat-square&logo=gmail&logoColor=white" />
  </a>
  <a href="Adhila_KS_Resume.pdf">
    <img src="https://img.shields.io/badge/Resume-View_My_Resume-4285F4?style=flat-square&logo=adobeacrobatreader&logoColor=white" />
  </a>
</p>

---

I'm a passionate Full-Stack Developer from India 🇮🇳  
Focused on building modern web apps, clean UI, and AI-powered applications that solve real problems.

---

### About me

- 🧠 I enjoy crafting responsive frontends and structured REST APIs
- ⚙️ Building full-stack apps with Next.js, React and the MERN stack
- 🚀 Interested in AI-powered applications & scalable architecture
- 🎯 Currently building Guestify — an event-management platform with my team
- 💬 Always open to collaborating on interesting ideas

---

### Tech I Work With

<code><img height="20" alt="javascript" src="https://raw.githubusercontent.com/github/explore/main/topics/javascript/javascript.png"></code>
<code><img height="20" alt="typescript" src="https://raw.githubusercontent.com/github/explore/main/topics/typescript/typescript.png"></code>
<code><img height="20" alt="react" src="https://raw.githubusercontent.com/github/explore/main/topics/react/react.png"></code>
<code><img height="20" alt="nextjs" src="https://raw.githubusercontent.com/github/explore/main/topics/nextjs/nextjs.png"></code>
<code><img height="20" alt="nodejs" src="https://raw.githubusercontent.com/github/explore/main/topics/nodejs/nodejs.png"></code>
<code><img height="20" alt="express" src="https://raw.githubusercontent.com/github/explore/main/topics/express/express.png"></code>
<code><img height="20" alt="mongodb" src="https://raw.githubusercontent.com/github/explore/main/topics/mongodb/mongodb.png"></code>
<code><img height="20" alt="mysql" src="https://raw.githubusercontent.com/github/explore/main/topics/mysql/mysql.png"></code>
<code><img height="20" alt="python" src="https://raw.githubusercontent.com/github/explore/main/topics/python/python.png"></code>
<code><img height="20" alt="tailwind" src="https://raw.githubusercontent.com/github/explore/main/topics/tailwind/tailwind.png"></code>
<code><img height="20" alt="git" src="https://raw.githubusercontent.com/github/explore/main/topics/git/git.png"></code>

---

### GitHub Stats

<p align="center">
  <img width="70%" src="https://streak-stats.demolab.com/?user=adhilasyedmuhammed-boop&theme=tokyonight&hide_border=true" />
</p>

<p align="center">
  <img width="80%" src="https://github-readme-activity-graph.vercel.app/graph?username=adhilasyedmuhammed-boop&theme=tokyo-night&hide_border=true&area=true" />
</p>

---

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:2c5364,100:0f2027&height=100&section=footer" />
</p>
=======
# Alif Online Moral School - Full Stack Application

Welcome to the Alif Online Moral School digital transformation project! This is a comprehensive student activity tracking system that digitizes the traditional "Ihthisab Chart" (Practical Record).

## 🎯 Project Overview

The Alif Online Moral School application is designed to:

- **Track Daily Activities** - Students log Islamic practices (prayers, Quran reading, etc.) daily
- **Monitor Progress** - Teachers and parents track student progress with visualizations
- **Gamify Learning** - Badges, leaderboards, and streaks motivate students
- **Generate Reports** - Comprehensive analytics and reports for administrators
- **Support Multiple Roles** - Students, Parents, Teachers, and Administrators
- **Bilingual Interface** - Full Malayalam and English support

## 🏗️ Project Structure

```
alifschool/
├── design-system/           # 🎨 Shared design tokens and components
├── backend/                 # 🔧 Node.js/Express API server
├── admin-panel/             # 👨‍💼 Flutter web admin dashboard
├── mobile_app/              # 📱 Flutter mobile application
├── docs/                    # 📚 Product and setup documentation
├── documentation/           # 🧭 Architecture and redesign documentation
└── README.md               # This file
```

## Repository Canonical Paths

To avoid duplicate-folder drift, use these canonical app roots:

- Admin web app: `admin-panel/`
- Mobile app: `mobile_app/`
- Backend: `backend/`

If other similarly named folders exist, treat them as legacy and do not add new feature work there.

See redesign details in `documentation/ALIF_PROJECT_REDESIGN.md`.

## 🚀 Quick Start

### 30-Minute Setup

Get the backend running in 30 minutes using our step-by-step guides:

👉 **[Quick Setup Reference](./docs/QUICK_SETUP_REFERENCE.md)** ← Start here!

This includes:
1. Supabase setup with database
2. Firebase configuration
3. Environment variable setup
4. Server verification

### Setup Backend

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

Then follow the setup guides above to configure Supabase and Firebase.

### Setup Admin Panel

```bash
cd admin-panel
flutter pub get
flutter run -d chrome
```

### Setup Mobile App

```bash
cd mobile_app
flutter pub get
flutter run  # iOS/Android device
```

## 📋 Features

### Student/Parent Features
- ✅ Daily activity marking (Ihthisab chart)
- ✅ Progress tracking (daily, weekly, monthly)
- ✅ Visual progress charts
- ✅ Badge achievements
- ✅ Leaderboard rankings
- ✅ Parent dashboard for multiple children
- ✅ Push notifications and reminders

### Teacher Features
- ✅ Monitor student progress
- ✅ Batch-wise analytics
- ✅ Add remarks and feedback
- ✅ Send motivational messages
- ✅ View student reports

### Admin Features
- ✅ Full user management (students, teachers, parents)
- ✅ Batch and class management
- ✅ Activity/Category configuration
- ✅ Scoring rules and badges
- ✅ Comprehensive reports and exports
- ✅ Notification management
- ✅ System configuration

## 🎨 Design System

Comprehensive design system with:
- Color palette (Islamic Green + Gold theme)
- Typography system (Malayalam + English)
- Spacing system (4px base unit)
- Component styles
- Reusable tokens

See [Design System Documentation](./design-system/README.md)

## 🔧 Technology Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (iOS/Android) |
| Web Admin | Flutter Web |
| Backend | Node.js + Express.js + TypeScript |
| Database | Supabase (PostgreSQL) |
| Auth | Firebase + Supabase Auth |
| Storage | Supabase Storage |
| Messaging | Firebase Cloud Messaging |

## 📚 Documentation

### Setup Guides (Start Here!)

| Guide | Purpose |
|-------|---------|
| **[Quick Setup Reference](./docs/QUICK_SETUP_REFERENCE.md)** | 30-minute setup walkthrough |
| **[Supabase Setup](./docs/SUPABASE_SETUP_STEP_BY_STEP.md)** | Detailed Supabase configuration |
| **[Firebase Setup](./docs/FIREBASE_SETUP_STEP_BY_STEP.md)** | Detailed Firebase configuration |
| **[Environment Variables](./docs/ENV_CONFIGURATION_GUIDE.md)** | All .env variables explained |

### Development Guides

| Guide | Purpose |
|-------|---------|
| **[Design System Guide](./design-system/README.md)** | Color tokens, typography, spacing |
| **[Backend API](./backend/README.md)** | Backend setup and development |
| **[Database Schema](./docs/SUPABASE_SETUP.md)** | Complete database structure |
| **[Contributing Guidelines](./CONTRIBUTING.md)** | How to contribute to the project |

### Architecture & Planning

- [Functional Requirements Document](./FRD.md) *(Provided)*
- [GitHub Copilot Instructions](./.github/copilot-instructions.md)
- [Phase 1 Foundation Spec](./docs/PHASE_1_FOUNDATION.md) - Frozen scope, branding, data model
- **[Phase 1 Implementation Checklist](./docs/PHASE_1_IMPLEMENTATION_CHECKLIST.md)** ← Start implementation here!

## 🔑 Key Configuration Files

- `.env.example` - Backend environment variables template
- `design-system/theme.ts` - Master design tokens
- `backend/tsconfig.json` - TypeScript configuration
- `backend/src/config/config.ts` - Application configuration

## 🚢 Deployment

### Backend
- Ready for Vercel, Railway, Heroku, or Docker deployment
- Environment-based configuration
- Supabase integration

### Admin Panel & Mobile
- Flutter web deployment to Firebase Hosting, Vercel, Netlify
- Mobile apps to Google Play Store and Apple App Store

## 🔐 Security

- Row-level security (RLS) in Supabase
- JWT-based API authentication
- OTP-based user authentication
- Environment variable management
- CORS configuration
- Rate limiting

## 📊 Database

Complete schema includes:
- Profiles and user management
- Student, teacher, parent tables
- Batch and class management
- Activity categories and ratings
- Daily activity logs
- Badges and achievements
- Notifications

See [Database Schema](./docs/SUPABASE_SETUP.md#5-complete-database-schema)

## 🎯 Development Workflow

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd alifschool
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Setup Environment**
   ```bash
   cd backend && cp .env.example .env
   # Edit .env with your credentials
   ```

4. **Start Development**
   ```bash
   npm run backend:dev
   ```

5. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

6. **Make Changes & Commit**
   ```bash
   git commit -m "feat: add your feature"
   ```

## 📦 Available Scripts

### Root Level
```bash
npm install-all          # Install all dependencies
npm run backend:dev      # Start backend development
npm run backend:build    # Build backend
npm run backend:start    # Start production backend
npm run backend:test     # Run backend tests
npm run lint             # Lint backend code
npm run test             # Run all tests
```

### Backend
```bash
cd backend
npm run dev              # Development server
npm run build            # Build TypeScript
npm run watch            # Watch TypeScript
npm start                # Production server
npm test                 # Run tests
npm run supabase:start   # Start local Supabase
npm run firebase:init    # Initialize Firebase
```

## 🐛 Troubleshooting

### Backend Connection Issues
- Check `SUPABASE_URL` and credentials in `.env`
- Verify Supabase project is active
- Ensure Firebase service account is configured

### Database Issues
- Run migrations: `npm run supabase:db:push`
- Check schema: `npm run supabase:db:pull`

### Environment Variables
- Copy `.env.example` to `.env`
- Never commit `.env` to version control
- Use different credentials for dev/prod

## 📞 Support

For issues and questions:
- 📧 Email: support@alifschool.com
- 🐛 Issues: Create GitHub issue
- 💬 Discussions: GitHub discussions

## 📜 License

MIT License - See LICENSE file for details

## 👥 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and lint
5. Create a pull request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines

## 🎓 Educational Purpose

This application is built for educational institution to:
- Encourage Islamic moral practices
- Track student progress systematically
- Provide feedback to students and parents
- Recognize and reward achievements
- Create a supportive learning community

## 📅 Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Phase 1: Setup | 1 week | ✅ In Progress |
| Phase 2: Admin Panel | 2 weeks | 📋 Planned |
| Phase 3: Student App | 2 weeks | 📋 Planned |
| Phase 4: Teacher Module | 1 week | 📋 Planned |
| Phase 5: Advanced Features | 2 weeks | 📋 Planned |
| Phase 6: Testing & Launch | 1 week | 📋 Planned |

## 🔄 Version History

- **v1.0.0** (Jun 17, 2026) - Initial project setup with design system and backend scaffolding

---

**Project Name:** Alif Online Moral School  
**Version:** 1.0.0  
**Status:** 🚀 In Development  
**Last Updated:** June 17, 2026
>>>>>>> 2ee4978a4d823e2032637b7a613bb700f82c09be
