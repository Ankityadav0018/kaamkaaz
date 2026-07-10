# Kaamkaaz (कामकाज) — Hyperlocal Daily Wage Worker Platform

![Kaamkaaz Banner](https://img.shields.io/badge/Kaamkaaz-Hyperlocal_Jobs-primary)
![Flutter](https://img.shields.io/badge/Frontend-Flutter_3.x-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Backend-Node.js_Express-339933?logo=nodedotjs)
![MongoDB](https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb)
![Build](https://img.shields.io/badge/Release-AAB_Generated-success)
[![Coming Soon](https://img.shields.io/badge/Play_Store-Coming_Soon-lightgrey?logo=google-play)]()

Kaamkaaz is a high-fidelity, production-ready hyperlocal job marketplace designed specifically for daily wage (blue-collar) workers and local recruiters in rural and semi-urban India.

Unlike dispatch platforms, Kaamkaaz is an intermediary **job board + matchmaking system** that empowers the local community through verified identities and word-of-mouth growth. It bridges the gap between workers (Kaamgars) and recruiters, providing a seamless platform for job posting, application management, and professional networking with a focus on ease of use and premium design.

---

## 🚀 Key Features

### 💎 Premium User Experience
- **Animated Splash Screen & Onboarding**: A high-fidelity introduction with bouncing logo animations and interactive tours for both workers and recruiters.
- **Dynamic Localization (13 Languages)**: Full I18n support across the entire app for 13 Indian languages (English, Hindi, Punjabi, Bengali, Telugu, Marathi, Tamil, Gujarati, Kannada, Malayalam, Odia, Urdu, Rajasthani/Bhojpuri).
- **Smart Auth & Biometrics**: Firebase-powered authentication with a "Remember Me" feature, OTP verification, and Deep Linking for secure, seamless access.
- **Zero-Overflow Design**: Carefully calibrated UI layouts that ensure a perfect look on all device sizes without rendering exceptions.
- **Strict Error Handling**: Production-grade boundaries that gracefully manage loading states, network timeouts, and unexpected crashes with user-friendly "Try Again" screens, ensuring technical jargon or raw errors are never exposed.

### 🤖 AI-Powered Capabilities
- **Authentic Dialect Translations**: Custom Python scripts using Gemini AI to accurately map hyper-local dialects (like authentic Haryanvi and Rajasthani), surpassing standard translation APIs.
- **AI Voice Assistant (Beta)**: Built-in voice capabilities with dynamically configured Text-to-Speech (TTS) engine targeting regional male/female voice profiles for a natural conversational experience.

### 👥 Comprehensive Role-Based Ecosystem
#### 1. For Workers (Kaamgars)
- **Discover Jobs**: Real-time job feed showing opportunities within a 15-30km radius based on live GPS location.
- **Apply & Work**: Apply with a single tap. Track application status (Pending/Accepted/Hired/Completed) in the "My Jobs" history.
- **Verification (KYC)**: Multi-step document upload (Aadhaar, Live Selfie, Driving License) for admin approval and trusted skill badges.
- **Worker Media Portfolio ("Previous Work")**: A management portal for workers to upload project descriptions, photos, and videos to showcase to recruiters.
- **Emergency SOS Alerts**: Built-in safety features to instantly notify emergency contacts and the admin dashboard in case of critical situations.
- **Offline Mode**: Intelligent local caching to browse recent job listings even with poor internet connectivity.

#### 2. For Recruiters
- **Post a Job**: Create listings with GPS location, specific skill requirements (e.g., Plumber, Painter), wage details, and site photos.
- **Manage Applicants**: Review worker profiles including their **Verified Skill Badges**, past ratings, portfolios, and distance.
- **Hiring & Connection**: Accept applicants to reveal contact details. Connect via **Direct Call**, **WhatsApp**, or **In-App Chat**.
- **Past Workers & Network**: Access a history of previously hired workers to quickly re-invite trusted talent for new jobs.
- **Unified Refer & Earn Wallet**: Live, real-time referral tracking powered by Socket.io. Both recruiters and workers earn universal cash rewards instantly withdrawable via UPI.

#### 3. For Admins
- **Analytics Dashboard**: Real-time visualization of platform health, registration trends, and job distribution.
- **KYC Queue**: Manage and verify worker/driver documents and recruiter onboarding requests.
- **Dispute Resolution**: Review and resolve disputes raised by users regarding payments or work quality.
- **Withdrawal Management**: Monitor and process financial withdrawals securely.

### 🛡️ Robust Infrastructure
- **Secure Storage**: Sensitive data like passwords are encrypted using `flutter_secure_storage`.
- **Global Error Handling**: Integrated Firebase Crashlytics and custom error widgets for maximum stability.
- **Real-time Connectivity**: Optimized Socket.io integration for instant chat and notifications.

---

## 🛠️ Technology Stack

### Frontend (App / Mobile)
- **Framework**: Flutter (Dart) — Updated for **Android SDK 36** compatibility.
- **State Management**: Riverpod (`flutter_riverpod`) — Reactive and predictable state.
- **Navigation**: GoRouter (`go_router`) — Declarative, type-safe routing.
- **Localization**: Easy Localization (`easy_localization`) driving 13 dynamic translations.
- **Build Tools**: Optimized with R8/ProGuard, resource shrinking, and native ABI stripping.

### Backend (API / Server)
- **Runtime**: Node.js with Express.js
- **Database**: MongoDB (Mongoose) with Geospatial indexing (`2dsphere`).
- **Real-Time**: Socket.io for live chat/notifications and Firebase Admin SDK for push notifications.
- **Cloud**: Cloudinary for KYC document and site photo storage.
- **Auth**: Supabase and Firebase unified authentication flow.

---

## 📂 Project Structure

```text
kaamkaaz/
├── app/                        # Flutter Mobile Application
│   ├── lib/
│   │   ├── l10n/               # Localization (13 Indian languages)
│   │   ├── models/             # Data Models (JSON mapping)
│   │   ├── providers/          # Riverpod State Management
│   │   ├── screens/            # Role-based UI (Worker, Recruiter, Admin)
│   │   ├── services/           # API & Socket Services
│   │   ├── utils/              # App Constants, Themes & Config
│   │   └── widgets/            # Reusable UI Components
│   ├── assets/                 # Brand Assets (Icons, Images, Translations)
│   └── android/                # Native Release Config
├── backend/                    # Node.js Express API
│   ├── config/                 # DB, Firebase, Cloudinary Config
│   ├── controllers/            # Request Handlers (Logic)
│   ├── middleware/             # Auth & Verification Middleware
│   ├── models/                 # Mongoose Schemas
│   ├── routes/                 # API Endpoints
│   ├── services/               # Internal Services (SMS, Push)
│   ├── utils/                  # Helpers (Referrals, Notifications)
│   └── server.js               # Entry Point
└── README.md                   # Main Documentation
```

---

## ⚙️ Environment Variables
Create `backend/.env` with these keys:

| Variable | Description |
|----------|-------------|
| `MONGODB_URI` | MongoDB connection string |
| `JWT_SECRET` | Secret for signing tokens |
| `FIREBASE_SERVICE_ACCOUNT` | JSON string of Firebase service account |
| `CLOUDINARY_URL` | For KYC document uploads |
| `PORT` | Server port (default 5005) |
| `SUPABASE_URL` | Supabase endpoint |
| `SUPABASE_ANON_KEY` | Supabase Anon Key |

---

## 🚀 Getting Started

### 1. Backend Setup
1. `cd backend`
2. `npm install`
3. Configure `.env` with your credentials.
4. `npm start` (Server runs on port 5005)

### 2. Frontend Setup
1. `cd app`
2. `flutter pub get`
3. Generate localized keys: `dart run easy_localization:generate -S assets/languages -f keys -O lib/l10n -o locale_keys.g.dart`
4. Ensure `lib/utils/api_config.dart` points to your backend IP.
5. `flutter run` (or `flutter build appbundle --release`)

### 3. Managing Translations
Kaamkaaz supports 13 dynamic Indian regional languages. To add or update translation strings:
1. Define the new translation keys in the English source file: `app/assets/languages/en.json`.
2. Open `app/assets/languages/local_translate.py` and map the translations for the new keys in the `TRANSLATIONS` dictionary (supporting Hindi, Haryanvi, Rajasthani, Punjabi, Marathi, Gujarati, Bengali, Tamil, Telugu, Kannada, Malayalam, Odia, Urdu).
3. Run `python3 local_translate.py` inside `app/assets/languages/` to update all translation files.
4. Regenerate localization helper class: `dart run easy_localization:generate -S assets/languages -f keys -O lib/l10n -o locale_keys.g.dart`.

---

## 👨‍💻 Developer Rationale
Kaamkaaz was built with a **"High-Trust, Low-Friction"** philosophy. Every feature, from the Aadhaar verification to the localized UI, is designed to serve the unique needs of the Indian blue-collar workforce. The architecture is modular, ensuring that new skills or regions can be added with minimal code changes.

---
Developed with ❤️ by Ankit Yadav and the Kaamkaaz Team.
