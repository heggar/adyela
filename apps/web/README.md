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

## 🌍 Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Required variables:

- `VITE_API_URL` - Backend API URL
- `VITE_FIREBASE_*` - Firebase configuration
- `VITE_JITSI_DOMAIN` - Jitsi domain for video calls

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
