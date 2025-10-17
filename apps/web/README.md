# Adyela Web - React PWA

Progressive Web App for medical appointments with video calls.

## 🚀 Stack

- **React 18** with TypeScript
- **Vite** for blazing fast dev and builds
- **TailwindCSS** for styling
- **React Router v6** for routing
- **Zustand** for state management
- **React Query** for data fetching
- **React Hook Form + Zod** for forms
- **i18next** for internationalization (ES/EN)
- **Vitest** for testing

## 📦 Project Structure

```
src/
├── app/                 # Application setup and routing
├── features/            # Feature-based modules
│   ├── auth/           # Authentication
│   ├── appointments/   # Appointments management
│   └── video/          # Video calls
├── components/         # Shared components
│   ├── layout/        # Layout components
│   └── ui/            # UI components
├── hooks/             # Custom hooks
├── services/          # API services
├── store/             # Zustand stores
├── i18n/              # Internationalization
├── styles/            # Global styles
├── utils/             # Utilities
└── types/             # TypeScript types
```

## 🛠️ Development

```bash
# Install dependencies
pnpm install

# Start dev server
pnpm dev

# Build for production
pnpm build

# Preview production build
pnpm preview

# Run tests
pnpm test

# Run tests with UI
pnpm test:ui

# Type check
pnpm type-check

# Lint
pnpm lint
```

### OAuth Testing Local

For testing OAuth authentication locally:

```bash
# Start Firebase Emulator
firebase emulators:start --only auth,firestore

# Run complete OAuth testing environment
./scripts/test-oauth-local.sh
```

This will start:

- Firebase Emulator (Auth + Firestore)
- Backend API (port 8000)
- Frontend (port 5173)
- Firebase Emulator UI (port 4000)

## 🌍 Environment Variables

Copy `.env.example` to `.env.local` and configure:

```bash
cp .env.example .env.local
```

Required variables:

- `VITE_API_BASE_URL` - Backend API URL
- `VITE_FIREBASE_*` - Firebase configuration
- `VITE_JITSI_DOMAIN` - Jitsi domain for video calls

### OAuth Configuration

For local development with Firebase Emulator:

```env
# Firebase Configuration for Local Development
VITE_FIREBASE_API_KEY=demo-key
VITE_FIREBASE_AUTH_DOMAIN=localhost
VITE_FIREBASE_PROJECT_ID=demo-adyela
VITE_FIREBASE_STORAGE_BUCKET=demo-adyela.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abcdef123456

# API Configuration
VITE_API_BASE_URL=http://localhost:8000
```

See [OAuth Setup Guide](../../docs/guides/OAUTH_SETUP.md) for production
configuration.

## 📱 PWA Features

- ✅ Offline support with Service Worker
- ✅ Install as app on mobile/desktop
- ✅ Push notifications support
- ✅ Background sync
- ✅ Optimized caching strategy

## 🧪 Testing

Tests are organized by type:

- `tests/unit/` - Unit tests
- `tests/integration/` - Integration tests

Run tests:

```bash
pnpm test              # Run all tests
pnpm test:ui           # Run with UI
pnpm test:coverage     # With coverage report
```

## 🌐 Internationalization

Supported languages:

- 🇪🇸 Spanish (default)
- 🇬🇧 English

Add translations in:

- `src/i18n/locales/es/translation.json`
- `src/i18n/locales/en/translation.json`

## 🎨 Styling

TailwindCSS with custom theme:

- Primary colors: Blue shades
- Secondary colors: Gray shades
- Custom components: `.btn`, `.input`, `.card`

## 📄 License

See [LICENSE](../../LICENSE)
