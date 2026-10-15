# Alif School — Vercel Deployment Guide

This guide explains how to deploy the entire **Alif School** ecosystem to **Vercel**:
1. **Backend API** (`backend/`) — Node.js Express API running as Vercel Serverless Functions
2. **Admin Panel** (`admin-panel/`) — Flutter Web operational dashboard
3. **Student & Parent Portal** (`mobile_app/`) — Flutter Web self-service portal

---

## Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │    GitHub: mariyam00786/alif         │
                      └──────────────────┬───────────────────┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         ▼                               ▼                               ▼
 ┌───────────────┐               ┌───────────────┐               ┌───────────────┐
 │ Project 1     │               │ Project 2     │               │ Project 3     │
 │ alif-api      │               │ alif-admin    │               │ alif-student  │
 ├───────────────┤               ├───────────────┤               ├───────────────┤
 │ Root: backend │               │ Root: admin-  │               │ Root: mobile_ │
 │ Node.js /     │               │ panel         │               │ app           │
 │ Express API   │               │ Flutter Web   │               │ Flutter Web   │
 └───────┬───────┘               └───────┬───────┘               └───────┬───────┘
         │                               │                               │
         │ API Requests                  │ Calls API                     │ Calls API
         └───────────────────────────────┴───────────────────────────────┘
```

---

## Method 1: GitHub Dashboard Import (Recommended)

Because the project is a monorepo hosted at `https://github.com/mariyam00786/alif`, you create **three linked projects** in your Vercel Dashboard. Each project automatically redeploys when you push to `main`.

---

### Step 1: Deploy the Backend API (`backend/`)

1. Go to [vercel.com/new](https://vercel.com/new).
2. Select your repository: **`mariyam00786/alif`**.
3. Configure the project:
   - **Project Name:** `alif-api` (or your preferred name)
   - **Framework Preset:** `Other`
   - **Root Directory:** Click **Edit** and choose **`backend`**
   - **Build Command:** `npm run build`
   - **Output Directory:** Leave default
4. Add **Environment Variables**:

| Variable | Recommended / Example Value | Description |
| :--- | :--- | :--- |
| `NODE_ENV` | `production` | Production mode |
| `PORT` | `3000` | Port default |
| `JWT_SECRET` | `your-secure-jwt-secret-key-min-32-chars` | Signing key for session tokens |
| `JWT_EXPIRES_IN` | `7d` | Token expiry duration |
| `SUPABASE_URL` | `https://your-project.supabase.co` | Remote Supabase project URL |
| `SUPABASE_ANON_KEY` | `eyJ...` | Supabase public anonymous key |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJ...` | Supabase service role key (backend only) |
| `FIREBASE_PROJECT_ID` | `alif-school` | *(Optional)* Firebase project ID |
| `MSGHEX_API_KEY` | *(Optional)* | WhatsApp OTP provider key |

5. Click **Deploy**.
6. Once deployed, copy your API URL:  
   👉 **`https://alif-api.vercel.app`** (your API base URL will be `https://alif-api.vercel.app/api`).

---

### Step 2: Deploy the Admin Panel (`admin-panel/`)

1. Go to [vercel.com/new](https://vercel.com/new).
2. Select the same repository: **`mariyam00786/alif`**.
3. Configure the project:
   - **Project Name:** `alif-admin`
   - **Framework Preset:** `Other`
   - **Root Directory:** Click **Edit** and choose **`admin-panel`**
   - **Build Command:** `bash vercel-build.sh` (already pre-configured in `vercel.json`)
   - **Output Directory:** `build/web` (already pre-configured in `vercel.json`)
4. Add **Environment Variables**:

| Variable | Value | Description |
| :--- | :--- | :--- |
| `API_BASE_URL` | `https://alif-api.vercel.app/api` | Point to the Backend API from Step 1 |

5. Click **Deploy**.
6. Your Admin Panel will be live at:  
   👉 **`https://alif-admin.vercel.app`**

---

### Step 3: Deploy the Student & Parent Portal (`mobile_app/`)

1. Go to [vercel.com/new](https://vercel.com/new).
2. Select the repository: **`mariyam00786/alif`**.
3. Configure the project:
   - **Project Name:** `alif-student` (or `alif-portal`)
   - **Framework Preset:** `Other`
   - **Root Directory:** Click **Edit** and choose **`mobile_app`**
   - **Build Command:** `bash vercel-build.sh` (already pre-configured in `vercel.json`)
   - **Output Directory:** `build/web` (already pre-configured in `vercel.json`)
4. Add **Environment Variables**:

| Variable | Value | Description |
| :--- | :--- | :--- |
| `API_BASE_URL` | `https://alif-api.vercel.app/api` | Point to the Backend API from Step 1 |

5. Click **Deploy**.
6. Your Student Portal will be live at:  
   👉 **`https://alif-student.vercel.app`**

---

## Method 2: Deploy via Vercel CLI

If you prefer to deploy directly from your local terminal:

### 1. Authenticate Vercel CLI
```bash
vercel login
```

### 2. Deploy Backend API
```bash
cd backend
vercel --prod
```

### 3. Deploy Admin Panel
```bash
cd ../admin-panel
flutter build web --release --dart-define=API_BASE_URL=https://your-api.vercel.app/api
vercel --prod
```

### 4. Deploy Mobile / Student App
```bash
cd ../mobile_app
flutter build web --release --dart-define=API_BASE_URL=https://your-api.vercel.app/api
vercel --prod
```

---

## Pre-configured Files Reference

All necessary Vercel configuration files have been created in the repository:

- [`backend/vercel.json`](file:///c:/Users/JAMSHEER/Desktop/alifschool/backend/vercel.json) — Routes all incoming traffic to `api/index.ts`.
- [`backend/api/index.ts`](file:///c:/Users/JAMSHEER/Desktop/alifschool/backend/api/index.ts) — Serverless entrypoint exporting the Express application.
- [`admin-panel/vercel.json`](file:///c:/Users/JAMSHEER/Desktop/alifschool/admin-panel/vercel.json) — SPA routing to `index.html` and caching headers for Flutter assets.
- [`admin-panel/vercel-build.sh`](file:///c:/Users/JAMSHEER/Desktop/alifschool/admin-panel/vercel-build.sh) — Builds Flutter Web release in Vercel CI.
- [`mobile_app/vercel.json`](file:///c:/Users/JAMSHEER/Desktop/alifschool/mobile_app/vercel.json) — SPA routing to `index.html` and asset caching.
- [`mobile_app/vercel-build.sh`](file:///c:/Users/JAMSHEER/Desktop/alifschool/mobile_app/vercel-build.sh) — Builds Flutter Web release in Vercel CI.
