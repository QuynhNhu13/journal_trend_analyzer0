# Journal Trend Analyzer — Web Admin

A React + Vite + TypeScript + TailwindCSS admin dashboard for the
`journal-trend-analyzer-3f87b` Firebase project. It shares the mobile app's pink
Material 3 identity and is deployed to Firebase Hosting.

This project is fully independent from the Flutter app — it does not import or
modify any Dart code.

## Stack

- React 18 + Vite 5 + TypeScript (strict)
- TailwindCSS 3 (design tokens mirrored from `lib/theme/app_theme.dart`)
- Firebase JS SDK v10 (`auth`, `firestore`, `storage`)
- react-router-dom 6

## Local setup

```bash
cd admin_web
npm install
cp .env.example .env   # fill with the web app config (see below)
npm run dev            # http://localhost:5173
```

### Environment (`.env`)

Values come from Firebase Console → Project settings → General → Your apps →
`journal_trend_analyzer (web)`:

```dotenv
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=journal-trend-analyzer-3f87b.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=journal-trend-analyzer-3f87b
VITE_FIREBASE_STORAGE_BUCKET=journal-trend-analyzer-3f87b.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=442283477331
VITE_FIREBASE_APP_ID=1:442283477331:web:2f01f96f65c38e705639a6
VITE_FIREBASE_MEASUREMENT_ID=G-FXWDJBK1SZ
```

## Admin access

After Google Sign-In, the app reads `admins/{yourEmail}` in Firestore. If the
document exists, you enter the dashboard; otherwise you see "Access denied".
Add admins from the Firebase Console (see the repo root instructions).

## Scripts

| Command          | Description                                        |
| ---------------- | -------------------------------------------------- |
| `npm run dev`    | Start the Vite dev server                          |
| `npm run build`  | Type-check and build to `dist/`                    |
| `npm run preview`| Preview the production build locally               |
| `npm run deploy` | Build, then `firebase deploy --only hosting`       |

## Deploy

Firebase Hosting config lives at the **repo root** (`firebase.json`,
`.firebaserc`) and serves `admin_web/dist` with SPA rewrites. From the repo root:

```bash
cd admin_web && npm run build && cd ..
firebase deploy --only hosting
```
