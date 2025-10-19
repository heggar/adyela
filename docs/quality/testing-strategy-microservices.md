# Estrategia de Testing para Microservicios

## 📊 Resumen Ejecutivo

Este documento define la estrategia completa de testing para la arquitectura de
microservicios de Adyela, desde unit tests hasta chaos engineering.

**Objetivos**:

- Garantizar calidad del código (coverage >80%)
- Prevenir regresiones en producción
- Validar contratos entre microservicios
- Detectar problemas de performance antes de producción

**Testing Pyramid**:

```
      /\
     /  \     E2E Tests (10%)
    /____\
   /      \   Integration Tests (20%)
  /________\
 /          \ Unit Tests (70%)
/__sto__Tests_\
```

---

## 🧪 1. Unit Testing

### Cobertura Target

| Componente            | Coverage Target | Herramienta                     |
| --------------------- | --------------- | ------------------------------- |
| **Backend (Python)**  | 80%             | pytest + pytest-cov             |
| **Admin Web (React)** | 80%             | vitest + @testing-library/react |
| **Mobile (Flutter)**  | 70%             | flutter_test                    |

### Backend Unit Tests (Python/FastAPI)

**Estructura**:

```
apps/api-appointments/
├── adyela_appointments/
│   ├── domain/
│   │   └── entities/
│   │       └── appointment.py
│   ├── application/
│   │   └── use_cases/
│   │       └── create_appointment.py
│   └── infrastructure/
│       └── firestore/
│           └── appointment_repository.py
└── tests/
    ├── unit/
    │   ├── domain/
    │   │   └── test_appointment.py
    │   ├── application/
    │   │   └── test_create_appointment_use_case.py
    │   └── infrastructure/
    │       └── test_appointment_repository.py
    ├── integration/
    └── e2e/
```

**Ejemplo - Test de Entidad (Domain)**:

```python
# tests/unit/domain/test_appointment.py
import pytest
from datetime import datetime, timedelta
from adyela_appointments.domain.entities.appointment import Appointment, AppointmentStatus

def test_appointment_creation():
    """Test crear cita válida"""
    appointment = Appointment(
        id="appt_123",
        patient_id="patient_456",
        professional_id="prof_789",
        tenant_id="tenant_abc",
        scheduled_at=datetime.now() + timedelta(days=1),
        duration_minutes=30,
        status=AppointmentStatus.CONFIRMED
    )

    assert appointment.id == "appt_123"
    assert appointment.status == AppointmentStatus.CONFIRMED
    assert appointment.is_in_future()

def test_appointment_cannot_be_in_past():
    """Test validación: cita no puede ser en el pasado"""
    with pytest.raises(ValueError, match="scheduled_at must be in the future"):
        Appointment(
            id="appt_123",
            patient_id="patient_456",
            professional_id="prof_789",
            tenant_id="tenant_abc",
            scheduled_at=datetime.now() - timedelta(days=1),  # Pasado
            duration_minutes=30,
            status=AppointmentStatus.CONFIRMED
        )

def test_appointment_cancel():
    """Test cancelar cita"""
    appointment = Appointment(...)
    appointment.cancel(reason="Patient requested")

    assert appointment.status == AppointmentStatus.CANCELLED
    assert appointment.cancellation_reason == "Patient requested"
```

**Ejemplo - Test de Use Case (Application)**:

```python
# tests/unit/application/test_create_appointment_use_case.py
import pytest
from unittest.mock import AsyncMock, Mock
from adyela_appointments.application.use_cases.create_appointment import CreateAppointmentUseCase
from adyela_appointments.application.dto import CreateAppointmentRequest

@pytest.fixture
def mock_appointment_repo():
    """Mock del repositorio"""
    repo = Mock()
    repo.save = AsyncMock()
    repo.find_by_id = AsyncMock(return_value=None)
    repo.check_conflict = AsyncMock(return_value=False)
    return repo

@pytest.fixture
def mock_auth_client():
    """Mock del cliente de autenticación"""
    client = Mock()
    client.validate_permissions = AsyncMock(return_value=True)
    return client

@pytest.fixture
def mock_event_bus():
    """Mock del bus de eventos"""
    bus = Mock()
    bus.publish = AsyncMock()
    return bus

@pytest.mark.asyncio
async def test_create_appointment_success(
    mock_appointment_repo,
    mock_auth_client,
    mock_event_bus
):
    """Test crear cita exitosamente"""
    use_case = CreateAppointmentUseCase(
        appointment_repo=mock_appointment_repo,
        auth_client=mock_auth_client,
        event_bus=mock_event_bus
    )

    request = CreateAppointmentRequest(
        patient_id="patient_456",
        professional_id="prof_789",
        tenant_id="tenant_abc",
        scheduled_at=datetime.now() + timedelta(days=1),
        duration_minutes=30,
        user_id="patient_456"  # Paciente creando su propia cita
    )

    appointment = await use_case.execute(request)

    # Assertions
    assert appointment.patient_id == "patient_456"
    assert appointment.status == AppointmentStatus.CONFIRMED

    # Verify interactions
    mock_auth_client.validate_permissions.assert_called_once_with(
        user_id="patient_456",
        tenant_id="tenant_abc",
        resource="appointments",
        action="create"
    )
    mock_appointment_repo.check_conflict.assert_called_once()
    mock_appointment_repo.save.assert_called_once()
    mock_event_bus.publish.assert_called_once_with(
        "appointment.created",
        appointment.dict()
    )

@pytest.mark.asyncio
async def test_create_appointment_permission_denied(
    mock_appointment_repo,
    mock_auth_client,
    mock_event_bus
):
    """Test crear cita sin permisos falla"""
    mock_auth_client.validate_permissions = AsyncMock(return_value=False)

    use_case = CreateAppointmentUseCase(
        appointment_repo=mock_appointment_repo,
        auth_client=mock_auth_client,
        event_bus=mock_event_bus
    )

    request = CreateAppointmentRequest(...)

    with pytest.raises(PermissionDeniedError):
        await use_case.execute(request)

    # Verify no se guardó ni se publicó evento
    mock_appointment_repo.save.assert_not_called()
    mock_event_bus.publish.assert_not_called()
```

**Run tests**:

```bash
# All tests
pytest

# With coverage
pytest --cov=adyela_appointments --cov-report=html

# Specific test
pytest tests/unit/application/test_create_appointment_use_case.py -v

# Parallel execution
pytest -n auto
```

### Frontend Unit Tests (React + Vitest)

**Ejemplo - Component Test**:

```typescript
// apps/web-admin/src/features/professionals/components/ApprovalCard.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ApprovalCard } from './ApprovalCard';

describe('ApprovalCard', () => {
  const mockProfessional = {
    id: 'prof_123',
    name: 'Dr. Carlos García',
    specialty: 'Psicología',
    email: 'carlos@example.com',
    status: 'PENDING_APPROVAL',
    documents: [
      { type: 'license', url: 'https://...', name: 'licencia.pdf' }
    ]
  };

  it('renders professional information', () => {
    render(<ApprovalCard professional={mockProfessional} />);

    expect(screen.getByText('Dr. Carlos García')).toBeInTheDocument();
    expect(screen.getByText('Psicología')).toBeInTheDocument();
    expect(screen.getByText('carlos@example.com')).toBeInTheDocument();
  });

  it('calls onApprove when approve button clicked', async () => {
    const onApprove = vi.fn();
    render(
      <ApprovalCard
        professional={mockProfessional}
        onApprove={onApprove}
      />
    );

    const approveButton = screen.getByRole('button', { name: /aprobar/i });
    fireEvent.click(approveButton);

    expect(onApprove).toHaveBeenCalledWith('prof_123');
  });

  it('shows confirmation dialog before rejecting', async () => {
    const onReject = vi.fn();
    render(
      <ApprovalCard
        professional={mockProfessional}
        onReject={onReject}
      />
    );

    const rejectButton = screen.getByRole('button', { name: /rechazar/i });
    fireEvent.click(rejectButton);

    // Dialog should appear
    expect(screen.getByText(/razón del rechazo/i)).toBeInTheDocument();
  });
});
```

**Run tests**:

```bash
# All tests
pnpm test

# With coverage
pnpm test:coverage

# Watch mode
pnpm test --watch
```

### Mobile Unit Tests (Flutter) ✅ IMPLEMENTADO

**Estructura de Tests Flutter**:

```
apps/mobile-patient/
└── test/
    ├── unit/              # Tests de lógica de negocio
    ├── widget/            # Tests de widgets (UI)
    └── integration/       # Tests de integración Flutter

packages/flutter-shared/
└── test/
    ├── professional_card_test.dart  # ✅ Shared widget tests
    ├── appointment_card_test.dart   # ✅ Shared widget tests
    └── empty_state_test.dart        # ✅ Shared widget tests
```

**Ejemplo - Widget Test (Shared Component)**:

```dart
// packages/flutter-shared/test/appointment_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_core/flutter_core.dart';

void main() {
  group('AppointmentCard', () {
    final appointment = Appointment(
      id: 'appt_123',
      professionalName: 'Dr. Carlos García',
      specialty: 'Psicología',
      scheduledAt: DateTime(2025, 10, 20, 10, 0),
      status: AppointmentStatus.confirmed,
    );

    testWidgets('displays appointment information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentCard(appointment: appointment),
          ),
        ),
      );

      expect(find.text('Dr. Carlos García'), findsOneWidget);
      expect(find.text('Psicología'), findsOneWidget);
      expect(find.text('20 Oct 2025 10:00'), findsOneWidget);
    });

    testWidgets('shows cancel button for confirmed appointments', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentCard(appointment: appointment),
          ),
        ),
      );

      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('calls onCancel when cancel button tapped', (WidgetTester tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentCard(
              appointment: appointment,
              onCancel: () { cancelCalled = true; },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });
  });
}
```

**Run tests**:

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test
flutter test test/features/appointments/appointment_card_test.dart
```

---

## 🔗 2. Integration Testing

### Test con Firestore Emulator

**Setup**:

```bash
# Install Firebase emulator
firebase setup:emulators:firestore

# Start emulator
firebase emulators:start --only firestore
```

**Test Example**:

```python
# tests/integration/test_appointment_repository.py
import pytest
from google.cloud import firestore
from adyela_appointments.infrastructure.firestore.appointment_repository import AppointmentRepository

@pytest.fixture
def firestore_client():
    """Firestore client pointing to emulator"""
    import os
    os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"

    client = firestore.Client(project="test-project")
    yield client

    # Cleanup: delete all data
    for collection in client.collections():
        for doc in collection.stream():
            doc.reference.delete()

@pytest.mark.asyncio
async def test_save_and_retrieve_appointment(firestore_client):
    """Test guardar y recuperar cita de Firestore"""
    repo = AppointmentRepository(firestore_client)

    appointment = Appointment(
        id="appt_test_123",
        patient_id="patient_456",
        professional_id="prof_789",
        tenant_id="tenant_abc",
        scheduled_at=datetime.now() + timedelta(days=1),
        duration_minutes=30,
        status=AppointmentStatus.CONFIRMED
    )

    # Save
    await repo.save(appointment)

    # Retrieve
    retrieved = await repo.find_by_id("appt_test_123", "tenant_abc")

    assert retrieved is not None
    assert retrieved.id == appointment.id
    assert retrieved.patient_id == appointment.patient_id
    assert retrieved.status == AppointmentStatus.CONFIRMED

@pytest.mark.asyncio
async def test_check_appointment_conflict(firestore_client):
    """Test detectar conflictos de horario"""
    repo = AppointmentRepository(firestore_client)

    # Create existing appointment
    existing = Appointment(
        id="appt_existing",
        professional_id="prof_789",
        tenant_id="tenant_abc",
        scheduled_at=datetime(2025, 10, 20, 10, 0),
        duration_minutes=30,
        status=AppointmentStatus.CONFIRMED
    )
    await repo.save(existing)

    # Try to create overlapping appointment
    conflict = await repo.check_conflict(
        professional_id="prof_789",
        tenant_id="tenant_abc",
        scheduled_at=datetime(2025, 10, 20, 10, 15),  # Overlaps!
        duration_minutes=30
    )

    assert conflict is True
```

### Test con Testcontainers (Cloud SQL)

```python
# tests/integration/test_analytics_repository.py
import pytest
from testcontainers.postgres import PostgresContainer
from sqlalchemy import create_engine
from adyela_analytics.infrastructure.postgres.analytics_repository import AnalyticsRepository

@pytest.fixture(scope="module")
def postgres_container():
    """Start PostgreSQL container"""
    with PostgresContainer("postgres:16") as postgres:
        yield postgres

@pytest.fixture
def db_engine(postgres_container):
    """Create SQLAlchemy engine"""
    connection_url = postgres_container.get_connection_url()
    engine = create_engine(connection_url)

    # Run migrations
    from adyela_analytics.infrastructure.postgres import migrations
    migrations.run(engine)

    yield engine

    engine.dispose()

def test_save_and_query_analytics(db_engine):
    """Test guardar y consultar analytics"""
    repo = AnalyticsRepository(db_engine)

    # Insert metric
    repo.record_appointment_created(
        tenant_id="tenant_abc",
        professional_id="prof_789",
        specialty="Psicología",
        timestamp=datetime.now()
    )

    # Query metrics
    metrics = repo.get_appointments_by_specialty(
        tenant_id="tenant_abc",
        start_date=datetime.now() - timedelta(days=1),
        end_date=datetime.now() + timedelta(days=1)
    )

    assert len(metrics) == 1
    assert metrics[0]["specialty"] == "Psicología"
    assert metrics[0]["count"] == 1
```

---

## 📜 3. Contract Testing (Pact)

**Por qué Contract Testing?**

- Garantizar que microservicios sean compatibles
- Detectar breaking changes antes de producción
- Independencia de deployments (no necesitamos todo el stack para testear)

### Consumer Contract (api-appointments → api-auth)

```python
# tests/contract/test_auth_service_contract.py
from pact import Consumer, Provider
import pytest

pact = Consumer("api-appointments").has_pact_with(
    Provider("api-auth"),
    pact_dir="pacts"
)

@pytest.mark.pact
def test_validate_permissions_contract():
    """Contract: api-appointments espera validar permisos en api-auth"""

    expected_request = {
        "user_id": "user_123",
        "tenant_id": "tenant_abc",
        "resource": "appointments",
        "action": "create"
    }

    expected_response = {
        "allowed": True,
        "user_id": "user_123",
        "roles": ["patient"]
    }

    (pact
     .given("user exists and has permission")
     .upon_receiving("a permission validation request")
     .with_request(
         method="POST",
         path="/api/v2/auth/validate",
         headers={"Content-Type": "application/json"},
         body=expected_request
     )
     .will_respond_with(
         status=200,
         headers={"Content-Type": "application/json"},
         body=expected_response
     ))

    with pact:
        # Call actual service (or mock)
        from adyela_appointments.infrastructure.auth_client import AuthServiceClient

        client = AuthServiceClient(base_url=pact.uri)
        result = await client.validate_permissions(
            user_id="user_123",
            tenant_id="tenant_abc",
            resource="appointments",
            action="create"
        )

        assert result["allowed"] is True
        assert result["user_id"] == "user_123"

# This generates a pact file: pacts/api-appointments-api-auth.json
```

### Provider Verification (api-auth verifica el contract)

```python
# apps/api-auth/tests/contract/test_verify_pact.py
from pact import Verifier

def test_verify_pact_with_api_appointments():
    """Verify that api-auth satisfies contract with api-appointments"""

    verifier = Verifier(
        provider="api-auth",
        provider_base_url="http://localhost:8080"  # api-auth running locally
    )

    # Verify against pact file
    output, logs = verifier.verify_pacts(
        "../api-appointments/pacts/api-appointments-api-auth.json",
        provider_states_setup_url="http://localhost:8080/_pact/provider_states"
    )

    assert output == 0, f"Pact verification failed: {logs}"
```

**CI/CD Integration**:

```yaml
# .github/workflows/contract-tests.yml
name: Contract Tests

on: [pull_request]

jobs:
  pact:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Run consumer tests (generate pacts)
      - name: Run consumer contract tests
        run: |
          cd apps/api-appointments
          pytest tests/contract/ --pact

      # Publish pacts to Pact Broker (optional)
      - name: Publish pacts
        run: |
          pact-broker publish pacts \
            --consumer-app-version=${{ github.sha }} \
            --broker-base-url=https://pact-broker.adyela.com

      # Run provider verification
      - name: Start api-auth
        run: |
          cd apps/api-auth
          docker-compose up -d

      - name: Verify provider contracts
        run: |
          cd apps/api-auth
          pytest tests/contract/test_verify_pact.py
```

---

## 🌐 4. E2E Testing Multi-Plataforma

### E2E Tests - Admin Web (Playwright)

**Ya existente** (100% critical paths passing) - **Mantener**

```typescript
// tests/e2e/admin/approve-professional.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Professional Approval Flow', () => {
  test('admin can approve professional application', async ({ page }) => {
    // Login as admin
    await page.goto('/login');
    await page.fill('[data-testid="email"]', 'admin@adye.care');
    await page.fill('[data-testid="password"]', 'test-password');
    await page.click('[data-testid="login-button"]');

    // Navigate to approvals
    await page.click('[data-testid="nav-approvals"]');
    await expect(page).toHaveURL('/admin/approvals');

    // Find pending professional
    const professionalCard = page
      .locator('[data-testid="professional-card"]')
      .first();
    await expect(professionalCard).toBeVisible();

    // View documents
    await professionalCard.click('[data-testid="view-documents"]');
    await expect(page.locator('[data-testid="document-viewer"]')).toBeVisible();

    // Approve
    await page.click('[data-testid="approve-button"]');

    // Verify confirmation
    await expect(page.locator('[data-testid="success-toast"]')).toContainText(
      'Profesional aprobado'
    );

    // Verify removed from list
    await expect(professionalCard).not.toBeVisible();
  });
});
```

### E2E Tests - Mobile (Flutter integration_test)

```dart
// apps/mobile-patient/integration_test/book_appointment_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_patient/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Book Appointment Flow', () {
    testWidgets('patient can search and book appointment', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('email-field')), 'patient@example.com');
      await tester.enterText(find.byKey(const Key('password-field')), 'password');
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();

      // Search for professionals
      await tester.tap(find.byKey(const Key('search-tab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('specialty-search')), 'Psicología');
      await tester.tap(find.byKey(const Key('search-button')));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.text('Psicología'), findsWidgets);

      // Select professional
      await tester.tap(find.byKey(const Key('professional-card')).first);
      await tester.pumpAndSettle();

      // Book appointment
      await tester.tap(find.text('Reservar Cita'));
      await tester.pumpAndSettle();

      // Select date and time
      await tester.tap(find.text('Mañana'));
      await tester.tap(find.text('10:00 AM'));
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Verify confirmation
      expect(find.text('Cita confirmada'), findsOneWidget);
    });
  });
}
```

**Run E2E tests**:

```bash
# Playwright (admin web)
pnpm playwright test

# Flutter integration tests (mobile)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/book_appointment_test.dart
```

---

## ⚡ 5. Performance Testing

### Load Testing con k6

```javascript
// tests/performance/load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp to 200 users
    { duration: '5m', target: 200 }, // Stay at 200 users
    { duration: '2m', target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'], // 95% requests < 200ms
    errors: ['rate<0.01'], // Error rate < 1%
  },
};

export default function () {
  const BASE_URL = 'https://api-appointments-staging.run.app';

  // Create appointment
  const payload = JSON.stringify({
    patient_id: 'patient_load_test',
    professional_id: 'prof_load_test',
    tenant_id: 'tenant_load_test',
    scheduled_at: new Date(Date.now() + 86400000).toISOString(),
    duration_minutes: 30,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${__ENV.API_TOKEN}`,
    },
  };

  const res = http.post(`${BASE_URL}/api/v2/appointments`, payload, params);

  check(res, {
    'status is 201': r => r.status === 201,
    'response time < 200ms': r => r.timings.duration < 200,
  }) || errorRate.add(1);

  sleep(1);
}
```

**Run load test**:

```bash
k6 run tests/performance/load-test.js
```

### Lighthouse CI (Frontend Performance)

```yaml
# .github/workflows/lighthouse-ci.yml
name: Lighthouse CI

on: [pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4

      - name: Install dependencies
        run: pnpm install

      - name: Build web-admin
        run: pnpm --filter web-admin build

      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            http://localhost:3000
            http://localhost:3000/admin/approvals
          budgetPath: ./lighthouse-budget.json
          uploadArtifacts: true

# lighthouse-budget.json
{
  "performance": 90,
  "accessibility": 100,
  "best-practices": 90,
  "seo": 90
}
```

---

## 🔒 6. Security Testing

### SAST (Static Application Security Testing)

**Already integrated**: Bandit (Python), ESLint security rules (React)

### DAST (Dynamic Application Security Testing)

**OWASP ZAP Scan**:

```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  schedule:
    - cron: '0 2 * * 0' # Weekly on Sunday 2 AM

jobs:
  zap-scan:
    runs-on: ubuntu-latest
    steps:
      - name: ZAP Scan
        uses: zaproxy/action-full-scan@v0.7.0
        with:
          target: 'https://staging.adyela.com'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'
```

### Dependency Scanning

**Already integrated**: Snyk, Trivy in CI/CD

---

## 🌀 7. Chaos Engineering (Fase 3)

**Testing resilience** a través de fault injection

```python
# tests/chaos/test_api_auth_down.py
import pytest
import httpx
from adyela_appointments.infrastructure.auth_client import AuthServiceClient

@pytest.mark.chaos
async def test_appointments_resilient_when_auth_down():
    """Test que api-appointments maneja caída de api-auth con circuit breaker"""

    # Simular api-auth down
    with mock.patch.object(httpx.AsyncClient, 'post', side_effect=httpx.ConnectError):
        auth_client = AuthServiceClient(base_url="https://api-auth.run.app")

        # Intentar validar permisos
        result = await auth_client.validate_permissions(
            user_id="user_123",
            tenant_id="tenant_abc",
            resource="appointments",
            action="create"
        )

        # Circuit breaker debe fallar rápido (no esperar timeout)
        # y retornar fallback: deny permission
        assert result is False  # Fail-secure
```

**Tools**: Chaos Mesh, Gremlin (cloud native chaos engineering)

---

## ✅ Quality Gates en CI/CD

**Todas las PR deben pasar**:

```yaml
# .github/workflows/ci.yml
name: CI Quality Gates

on: [pull_request]

jobs:
  quality-gates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # 1. Linting
      - name: Lint Python
        run: ruff check .

      - name: Lint TypeScript
        run: pnpm eslint

      # 2. Type Checking
      - name: MyPy (Python)
        run: mypy adyela_api/

      - name: TypeScript Check
        run: pnpm tsc --noEmit

      # 3. Unit Tests
      - name: Python Unit Tests
        run: pytest tests/unit/ --cov --cov-fail-under=80

      - name: React Unit Tests
        run:
          pnpm test --coverage --coverageThreshold='{"global":{"branches":80}}'

      # 4. Security Scans
      - name: Trivy Scan
        run: trivy fs .

      - name: Snyk Scan
        run: snyk test

      # 5. Integration Tests
      - name: Start Emulators
        run: firebase emulators:start --only firestore &

      - name: Integration Tests
        run: pytest tests/integration/

      # 6. Contract Tests
      - name: Pact Consumer Tests
        run: pytest tests/contract/ --pact

      # ALL MUST PASS ✅
```

---

## 📋 Checklist de Testing

### MVP (Mes 1-6)

- [x] **Unit tests**: 80% backend, 80% web admin (ya existe)
- [ ] **Unit tests**: 70% mobile Flutter (nuevo)
- [ ] **Integration tests**: Firestore emulator (nuevo)
- [x] **E2E tests**: 100% critical paths web admin (ya existe)
- [ ] **E2E tests**: 100% critical paths mobile (nuevo)
- [ ] **Contract tests**: api-appointments ↔ api-auth (nuevo)
- [ ] **Performance**: Lighthouse CI >90 (nuevo)

### Post-MVP (Mes 7-12)

- [ ] **Contract tests**: Todos los microservicios
- [ ] **Load testing**: k6 con 1k usuarios concurrentes
- [ ] **Security testing**: OWASP ZAP weekly scans
- [ ] **Chaos testing**: Circuit breaker, timeout scenarios
- [ ] **Performance**: API p95 <200ms validated

---

**Documento**: `docs/quality/testing-strategy-microservices.md` **Versión**: 1.1
**Última actualización**: 2025-10-18 **Estado**: Flutter testing section
agregada, E2E tests pending **Owner**: QA + Engineering Team **Próxima
revisión**: Implementación de tests E2E Flutter
