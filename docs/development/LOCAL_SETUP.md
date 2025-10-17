# 🏠 Local Development Setup - Adyela

Complete guide to set up and run Adyela locally with Docker Compose and Firebase
Emulators.

---

## 📋 Prerequisites

### Required Software

- **Docker Desktop** >= 24.0
  - Download: https://www.docker.com/products/docker-desktop
  - Make sure Docker Compose v2 is included

- **Git** >= 2.30
  - Download: https://git-scm.com/downloads

### Optional (for direct development without Docker)

- **Node.js** >= 20.0 (with pnpm)
- **Python** >= 3.12 (with Poetry)

---

## 🚀 Quick Start (5 minutes)

### 1. Clone the repository

```bash
git clone https://github.com/heggar/adyela.git
cd adyela
```

### 2. Copy environment files

```bash
# Root project
cp .env.example .env

# API
cp apps/api/.env.example apps/api/.env

# Web
cp apps/web/.env.example apps/web/.env
```

**Note:** The `.env.example` files are already configured for local development
with emulators. No changes needed!

### 3. Start all services

```bash
docker-compose -f docker-compose.dev.yml up
```

**First run takes 5-10 minutes** to download images and build containers.

### 4. Access the application

Once all services are running, open:

- **Web App**: http://localhost:3000
- **API Docs**: http://localhost:8000/docs
- **Firebase Emulator UI**: http://localhost:4000
- **Redis Commander** (optional): http://localhost:8081

### 5. Test the setup

```bash
# In a new terminal
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","environment":"development"}
```

✅ **You're ready to develop!**

---

## 📦 Services Overview

The local development environment includes:

| Service                       | Port | Description              | Access                |
| ----------------------------- | ---- | ------------------------ | --------------------- |
| **Web (Vite)**                | 3000 | React PWA frontend       | http://localhost:3000 |
| **API (FastAPI)**             | 8000 | Backend API              | http://localhost:8000 |
| **Firestore Emulator**        | 8080 | Database emulator        | localhost:8080        |
| **Firebase Auth Emulator**    | 9099 | Authentication           | localhost:9099        |
| **Firebase Storage Emulator** | 9199 | File storage             | localhost:9199        |
| **Firebase UI**               | 4000 | Emulator management UI   | http://localhost:4000 |
| **Redis**                     | 6379 | Cache & sessions         | localhost:6379        |
| **Redis Commander**           | 8081 | Redis GUI (optional)     | http://localhost:8081 |
| **Mailhog**                   | 8025 | Email testing (optional) | http://localhost:8025 |

---

## 🔧 Detailed Setup

### Environment Variables Explained

#### `.env` (Root)

```bash
ENVIRONMENT=development
# COMPOSE_PROFILES=tools  # Uncomment to enable Redis Commander & Mailhog
```

#### `apps/api/.env`

Key variables (already set in `.env.example`):

```bash
# Firebase Emulators (Local)
FIREBASE_PROJECT_ID=adyela-dev
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099

# Redis
REDIS_URL=redis://:dev-redis-password@localhost:6379/0

# Security (dev only)
SECRET_KEY=dev-secret-key-change-in-production-minimum-32-characters
```

#### `apps/web/.env`

Key variables (already set in `.env.example`):

```bash
# API
VITE_API_URL=http://localhost:8000

# Firebase Emulators
VITE_FIREBASE_PROJECT_ID=adyela-dev
VITE_FIREBASE_AUTH_EMULATOR_URL=http://localhost:9099
VITE_FIRESTORE_EMULATOR_HOST=localhost:8080
```

---

## 🛠 Docker Compose Commands

### Start services

```bash
# Start all services
docker-compose -f docker-compose.dev.yml up

# Start in background (detached mode)
docker-compose -f docker-compose.dev.yml up -d

# Start with optional tools (Redis Commander, Mailhog)
docker-compose --profile tools -f docker-compose.dev.yml up
```

### Stop services

```bash
# Stop all services
docker-compose -f docker-compose.dev.yml down

# Stop and remove volumes (CAUTION: deletes data)
docker-compose -f docker-compose.dev.yml down -v
```

### View logs

```bash
# All services
docker-compose -f docker-compose.dev.yml logs

# Specific service
docker-compose -f docker-compose.dev.yml logs api
docker-compose -f docker-compose.dev.yml logs web

# Follow logs (live)
docker-compose -f docker-compose.dev.yml logs -f api
```

### Rebuild services

```bash
# Rebuild all
docker-compose -f docker-compose.dev.yml build

# Rebuild specific service
docker-compose -f docker-compose.dev.yml build api

# Rebuild and start
docker-compose -f docker-compose.dev.yml up --build
```

### Execute commands in containers

```bash
# API: Run tests
docker-compose -f docker-compose.dev.yml exec api poetry run pytest

# API: Run migrations (future)
docker-compose -f docker-compose.dev.yml exec api poetry run alembic upgrade head

# Web: Install dependencies
docker-compose -f docker-compose.dev.yml exec web pnpm install

# Web: Run tests
docker-compose -f docker-compose.dev.yml exec web pnpm test

# Redis: Connect to CLI
docker-compose -f docker-compose.dev.yml exec redis redis-cli -a dev-redis-password
```

---

## 🧪 Testing

### Run all tests

```bash
# API tests
docker-compose -f docker-compose.dev.yml exec api poetry run pytest

# Web tests
docker-compose -f docker-compose.dev.yml exec web pnpm test

# E2E tests (requires services running)
docker-compose -f docker-compose.dev.yml exec web pnpm test:e2e
```

### Run with coverage

```bash
# API coverage
docker-compose -f docker-compose.dev.yml exec api poetry run pytest --cov=adyela_api --cov-report=html

# Web coverage
docker-compose -f docker-compose.dev.yml exec web pnpm test:coverage
```

---

## 🔥 Firebase Emulator

### Access Emulator UI

http://localhost:4000

Features:

- View Firestore collections and documents
- Manage authentication users
- View storage files
- Export/import data

### Export data

Data is automatically exported to `./firebase-data/` on shutdown:

```bash
docker-compose -f docker-compose.dev.yml down
# Data saved to ./firebase-data/
```

### Import data

Place exported data in `./firebase-data/` and restart:

```bash
docker-compose -f docker-compose.dev.yml up
# Data loaded from ./firebase-data/
```

### Create test users

Via Emulator UI (http://localhost:4000):

1. Go to **Authentication** tab
2. Click **Add user**
3. Enter email/password
4. Copy UID for testing

Or via API:

```bash
curl -X POST http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "returnSecureToken": true
  }'
```

---

## 📊 Redis Management

### Connect via Redis CLI

```bash
docker-compose -f docker-compose.dev.yml exec redis redis-cli -a dev-redis-password
```

### Common Redis commands

```bash
# View all keys
KEYS *

# Get value
GET key_name

# Delete key
DEL key_name

# Clear all data
FLUSHALL
```

### Using Redis Commander (GUI)

1. Start with tools profile:

   ```bash
   docker-compose --profile tools -f docker-compose.dev.yml up
   ```

2. Open http://localhost:8081

---

## 📧 Email Testing with Mailhog

### Enable Mailhog

```bash
# Start with tools profile
docker-compose --profile tools -f docker-compose.dev.yml up
```

### Access Mailhog UI

http://localhost:8025

### Configure API to use Mailhog

In `apps/api/.env`:

```bash
SMTP_HOST=mailhog
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=
```

All emails sent by the API will appear in Mailhog UI!

---

## 🐛 Troubleshooting

### Port already in use

```bash
# Check what's using the port
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.dev.yml
```

### Docker containers won't start

```bash
# Clean everything
docker-compose -f docker-compose.dev.yml down -v
docker system prune -af

# Rebuild
docker-compose -f docker-compose.dev.yml up --build
```

### Firebase emulator connection refused

```bash
# Make sure emulator is running
docker-compose -f docker-compose.dev.yml ps firebase

# Check logs
docker-compose -f docker-compose.dev.yml logs firebase

# Restart emulator
docker-compose -f docker-compose.dev.yml restart firebase
```

### API hot-reload not working

```bash
# Restart API service
docker-compose -f docker-compose.dev.yml restart api

# Or rebuild
docker-compose -f docker-compose.dev.yml up --build api
```

### Web hot-reload not working

```bash
# Check Vite HMR port (5173) is mapped
# Restart web service
docker-compose -f docker-compose.dev.yml restart web
```

### Cannot connect from host to containers

**Issue**: API/Web running but cannot access from browser

**Solution**: Make sure Docker Desktop is running and ports are mapped
correctly:

```bash
docker-compose -f docker-compose.dev.yml ps
# Should show 0.0.0.0:3000->3000/tcp, etc.
```

### Database schema issues

```bash
# Clear Firestore data
rm -rf firebase-data/firestore_export

# Restart emulator
docker-compose -f docker-compose.dev.yml restart firestore
```

---

## 🔄 Development Workflow

### 1. Start development

```bash
# Start all services in background
docker-compose -f docker-compose.dev.yml up -d

# Watch logs (optional)
docker-compose -f docker-compose.dev.yml logs -f
```

### 2. Make changes

- API code: `apps/api/` - Auto-reloads on save
- Web code: `apps/web/` - HMR (Hot Module Replacement)

### 3. Run tests

```bash
# API tests
docker-compose -f docker-compose.dev.yml exec api poetry run pytest

# Web tests
docker-compose -f docker-compose.dev.yml exec web pnpm test
```

### 4. Commit changes

```bash
git add .
git commit -m "feat: your feature description"
# Husky hooks run automatically (lint, format, tests)
```

### 5. Push and create PR

```bash
git push origin your-branch
# Create PR on GitHub
# CI workflows run automatically
```

### 6. Stop development

```bash
# Stop services
docker-compose -f docker-compose.dev.yml down

# Or keep data and restart later
docker-compose -f docker-compose.dev.yml stop
```

---

## 🎯 Best Practices

### 1. Use separate terminals

- **Terminal 1**: Docker Compose logs
- **Terminal 2**: Git commands
- **Terminal 3**: Docker exec commands (testing, etc.)

### 2. Periodic cleanup

```bash
# Weekly cleanup to free space
docker system prune -f

# Remove unused volumes
docker volume prune -f
```

### 3. Keep emulator data

```bash
# Export before major changes
docker-compose -f docker-compose.dev.yml down
# Data saved to ./firebase-data/

# Backup if needed
cp -r firebase-data firebase-data-backup
```

### 4. Update dependencies

```bash
# API
docker-compose -f docker-compose.dev.yml exec api poetry update

# Web
docker-compose -f docker-compose.dev.yml exec web pnpm update

# Rebuild after updates
docker-compose -f docker-compose.dev.yml up --build
```

---

## 🌐 Running without Docker (Alternative)

### API (Python)

```bash
cd apps/api

# Install dependencies
poetry install

# Start Firebase emulators (separate terminal)
firebase emulators:start

# Run API
export FIRESTORE_EMULATOR_HOST=localhost:8080
export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
poetry run uvicorn adyela_api.main:app --reload
```

### Web (Node.js)

```bash
cd apps/web

# Install dependencies
pnpm install

# Run dev server
pnpm dev
```

---

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [FastAPI Development](https://fastapi.tiangolo.com/)
- [Vite Development](https://vitejs.dev/guide/)

---

## 🆘 Getting Help

1. Check troubleshooting section above
2. View logs: `docker-compose -f docker-compose.dev.yml logs`
3. Open an issue: https://github.com/heggar/adyela/issues
4. Check CI/CD workflows for similar errors

---

**Happy coding! 🚀**
