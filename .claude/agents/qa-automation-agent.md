# 🧪 QA Automation Agent Specification

**Agent Type:** Specialized SDLC Agent **Domain:** Quality Assurance & Testing
**Version:** 1.0.0 **Last Updated:** 2025-10-05

---

## 🎯 Purpose & Scope

The QA Automation Agent ensures the quality, reliability, and performance of the
Adyela platform through comprehensive automated testing strategies. This agent
implements the testing pyramid with unit, integration, E2E, performance, and
accessibility testing.

### Primary Responsibilities

1. **Test Strategy**: Design comprehensive test coverage strategy
2. **Test Automation**: Implement and maintain automated test suites
3. **Performance Testing**: Validate application performance and scalability
4. **Accessibility Testing**: Ensure WCAG 2.1 compliance
5. **Quality Gates**: Enforce quality standards in CI/CD pipeline

---

## 🔧 Technical Expertise

### Testing Frameworks

- **Unit Testing**:
  - **Backend**: Pytest (Python), pytest-asyncio, pytest-cov
  - **Frontend**: Vitest (React), Testing Library, Jest
- **Integration Testing**:
  - **API**: Pytest with httpx, Schemathesis (contract testing)
  - **Database**: Firestore emulator testing
- **E2E Testing**:
  - **Playwright**: Cross-browser testing (Chromium, Firefox, Safari)
  - **Visual Regression**: Percy, Chromatic (optional)
- **Performance Testing**:
  - **Lighthouse**: Web performance auditing
  - **k6**: Load testing, stress testing
  - **Artillery**: API load testing
- **Accessibility Testing**:
  - **axe-core**: Automated a11y testing
  - **Pa11y**: CLI accessibility testing
  - **Lighthouse**: Accessibility scoring

### Code Quality Tools

- **Linting**: ESLint, Ruff, Prettier
- **Type Checking**: TypeScript, MyPy
- **Code Coverage**: Istanbul (JS), Coverage.py (Python)
- **Mutation Testing**: Stryker (JS)

---

## 📋 Core Responsibilities

### 1. Test Strategy & Coverage

#### Testing Pyramid

\`\`\` ╱╲ ╱ E2E╲ ~10% - Critical user flows ╱──────╲ ╱Integration╲ ~20% - API
contracts, service integration ╱────────────╲ ╱ Unit Tests ╲ ~70% - Business
logic, utilities ╱────────────────╲ \`\`\`

**Coverage Targets:**

- **Unit Tests**: 80% code coverage
- **Integration Tests**: 100% API endpoint coverage
- **E2E Tests**: Top 20 user scenarios
- **Performance**: 100% critical page audits
- **Accessibility**: 100% WCAG 2.1 AA compliance

---

### 2. Unit Testing Implementation

#### Backend Unit Tests (Pytest)

\`\`\`python

# apps/api/tests/unit/domain/test_appointment.py

import pytest from datetime import datetime, timedelta from adyela_api.domain
import Appointment, BusinessRuleViolationError from
adyela_api.domain.value_objects import DateTimeRange, TenantId from
adyela_api.config import AppointmentStatus, AppointmentType

class TestAppointment: def test_create_appointment_success(self): """Test
creating a valid appointment""" start = datetime.utcnow() + timedelta(days=1)
end = start + timedelta(hours=1)

        appointment = Appointment(
            id="test-123",
            tenant_id=TenantId("tenant-1"),
            patient_id="patient-1",
            practitioner_id="practitioner-1",
            schedule=DateTimeRange(start=start, end=end),
            appointment_type=AppointmentType.VIDEO_CALL
        )

        assert appointment.status == AppointmentStatus.SCHEDULED
        assert appointment.duration_minutes == 60
        assert appointment.is_upcoming is True

    def test_cannot_create_appointment_in_past(self):
        """Test that appointments cannot be created in the past"""
        start = datetime.utcnow() - timedelta(days=1)
        end = start + timedelta(hours=1)

        with pytest.raises(BusinessRuleViolationError):
            Appointment(
                id="test-123",
                tenant_id=TenantId("tenant-1"),
                patient_id="patient-1",
                practitioner_id="practitioner-1",
                schedule=DateTimeRange(start=start, end=end),
                appointment_type=AppointmentType.VIDEO_CALL
            )

    def test_confirm_appointment(self):
        """Test appointment confirmation"""
        appointment = create_valid_appointment()  # fixture
        appointment.confirm()
        assert appointment.status == AppointmentStatus.CONFIRMED

    def test_cannot_confirm_completed_appointment(self):
        """Test business rule: cannot confirm completed appointment"""
        appointment = create_valid_appointment()
        appointment.status = AppointmentStatus.COMPLETED

        with pytest.raises(BusinessRuleViolationError):
            appointment.confirm()

\`\`\`

**Current Coverage:** Unknown **Target Coverage:** 80%

---

#### Frontend Unit Tests (Vitest + Testing Library)

\`\`\`typescript // apps/web/src/features/auth/components/LoginPage.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi } from 'vitest'; import { LoginPage } from './LoginPage'; import {
useAuth } from '../hooks/useAuth';

vi.mock('../hooks/useAuth');

describe('LoginPage', () => { it('renders login form', () => {
render(<LoginPage />);

    expect(screen.getByTestId('login-title')).toBeInTheDocument();
    expect(screen.getByTestId('email-input')).toBeInTheDocument();
    expect(screen.getByTestId('password-input')).toBeInTheDocument();
    expect(screen.getByTestId('login-button')).toBeInTheDocument();

});

it('displays validation errors for invalid email', async () => {
render(<LoginPage />);

    const emailInput = screen.getByTestId('email-input');
    fireEvent.change(emailInput, { target: { value: 'invalid-email' } });
    fireEvent.blur(emailInput);

    await waitFor(() => {
      expect(screen.getByText(/invalid email format/i)).toBeInTheDocument();
    });

});

it('calls login function on form submit', async () => { const mockLogin =
vi.fn(); (useAuth as any).mockReturnValue({ login: mockLogin });

    render(<LoginPage />);

    fireEvent.change(screen.getByTestId('email-input'), {
      target: { value: 'test@example.com' }
    });
    fireEvent.change(screen.getByTestId('password-input'), {
      target: { value: 'password123' }
    });
    fireEvent.click(screen.getByTestId('login-button'));

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('test@example.com', 'password123');
    });

}); }); \`\`\`

**Current Coverage:** Unknown **Target Coverage:** 75%

---

### 3. Integration Testing

#### API Integration Tests

\`\`\`python

# tests/integration/api/test_appointments_api.py

import pytest from httpx import AsyncClient from apps.api.adyela_api.main import
app

@pytest.mark.integration class TestAppointmentsAPI: @pytest.mark.asyncio async
def test_create_appointment_success(self, async_client: AsyncClient, auth_token:
str): """Test creating appointment via API""" response = await
async_client.post( "/api/v1/appointments", headers={ "Authorization": f"Bearer
{auth_token}", "X-Tenant-ID": "test-tenant" }, json={ "patient_id":
"patient-123", "practitioner_id": "practitioner-456", "start_time":
"2025-12-01T10:00:00Z", "end_time": "2025-12-01T11:00:00Z", "appointment_type":
"video_call", "reason": "Regular checkup" } )

        assert response.status_code == 201
        data = response.json()
        assert data["id"] is not None
        assert data["status"] == "scheduled"

    @pytest.mark.asyncio
    async def test_create_appointment_unauthorized(self, async_client: AsyncClient):
        """Test creating appointment without authentication"""
        response = await async_client.post(
            "/api/v1/appointments",
            headers={"X-Tenant-ID": "test-tenant"},
            json={
                "patient_id": "patient-123",
                "practitioner_id": "practitioner-456",
                "start_time": "2025-12-01T10:00:00Z",
                "end_time": "2025-12-01T11:00:00Z",
                "appointment_type": "video_call"
            }
        )

        assert response.status_code == 401

\`\`\`

---

#### API Contract Testing (Schemathesis)

\`\`\`python

# tests/contract/test_api_schema.py

import schemathesis

schema = schemathesis.from_uri("http://localhost:8000/openapi.json")

@schema.parametrize() def test_api_contract(case): """Test all API endpoints
against OpenAPI schema""" response = case.call()
case.validate_response(response) \`\`\`

**Command:** \`\`\`bash

# Run contract tests

schemathesis run --url http://localhost:8000/openapi.json \\ --checks all \\
--hypothesis-max-examples=100 \\ --header "X-Tenant-ID: test-tenant" \`\`\`

---

### 4. E2E Testing (Playwright)

#### Current E2E Tests

**Status:** ✅ 16/16 tests passing (100%)

- **Authentication**: 7 tests
- **API Health**: 9 tests

**E2E Test Expansion Plan:** \`\`\`typescript //
tests/e2e/appointments/create-appointment.spec.ts import { test, expect } from
'@playwright/test';

test.describe('Appointment Creation Flow', () => { test.beforeEach(async ({ page
}) => { // Login await page.goto('/login'); await
page.getByTestId('email-input').fill('doctor@clinic.com'); await
page.getByTestId('password-input').fill('password123'); await
page.getByTestId('login-button').click(); await
expect(page.getByTestId('dashboard-title')).toBeVisible(); });

test('doctor can create new appointment', async ({ page }) => { // Navigate to
appointments await page.getByTestId('nav-appointments').click(); await
page.getByTestId('create-appointment-button').click();

    // Fill appointment form
    await page.getByTestId('patient-select').selectOption('patient-123');
    await page.getByTestId('date-picker').fill('2025-12-01');
    await page.getByTestId('time-picker').fill('10:00');
    await page.getByTestId('duration-select').selectOption('60');
    await page.getByTestId('type-select').selectOption('video_call');
    await page.getByTestId('reason-input').fill('Regular checkup');

    // Submit
    await page.getByTestId('submit-appointment').click();

    // Verify success
    await expect(page.getByTestId('success-message')).toBeVisible();
    await expect(page.getByTestId('appointment-card')).toContainText('Regular checkup');

});

test('validates required fields', async ({ page }) => { await
page.getByTestId('nav-appointments').click(); await
page.getByTestId('create-appointment-button').click();

    // Submit without filling
    await page.getByTestId('submit-appointment').click();

    // Verify validation errors
    await expect(page.getByText(/patient is required/i)).toBeVisible();
    await expect(page.getByText(/date is required/i)).toBeVisible();

}); }); \`\`\`

**E2E Coverage Expansion:**

- [ ] Appointment creation flow
- [ ] Appointment cancellation
- [ ] Video call joining
- [ ] Patient registration
- [ ] Doctor profile management
- [ ] Dashboard analytics
- [ ] Search and filtering
- [ ] Notifications

**Target:** 30+ E2E tests covering critical paths

---

### 5. Performance Testing

#### Lighthouse Audits

**Current Scores:**

- Performance: 59/100 (dev mode)
- Accessibility: 100/100 ✅
- Best Practices: 96/100 ✅
- SEO: 91/100 ✅

**Production Targets:**

- Performance: >90
- Accessibility: 100
- Best Practices: >95
- SEO: >95

**Lighthouse CI Configuration:** \`\`\`json // lighthouserc.json { "ci": {
"collect": { "url": [ "http://localhost:3000",
"http://localhost:3000/dashboard", "http://localhost:3000/appointments" ],
"numberOfRuns": 3 }, "assert": { "preset": "lighthouse:recommended",
"assertions": { "categories:performance": ["error", {"minScore": 0.9}],
"categories:accessibility": ["error", {"minScore": 1.0}],
"categories:best-practices": ["error", {"minScore": 0.95}], "categories:seo":
["error", {"minScore": 0.95}], "first-contentful-paint": ["warn",
{"maxNumericValue": 2000}], "largest-contentful-paint": ["error",
{"maxNumericValue": 2500}], "cumulative-layout-shift": ["error",
{"maxNumericValue": 0.1}], "total-blocking-time": ["error", {"maxNumericValue":
300}] } }, "upload": { "target": "temporary-public-storage" } } } \`\`\`

---

#### Load Testing (k6)

\`\`\`javascript // tests/performance/load-test.js import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = { stages: [ { duration: '2m', target: 50 }, // Ramp up to
50 users { duration: '5m', target: 50 }, // Stay at 50 users { duration: '2m',
target: 100 }, // Ramp up to 100 users { duration: '5m', target: 100 }, // Stay
at 100 users { duration: '2m', target: 0 }, // Ramp down ], thresholds: {
http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
http_req_failed: ['rate<0.01'], // Error rate < 1% }, };

export default function () { // Health check const healthRes =
http.get('http://api.adyela.com/health'); check(healthRes, { 'health check
status is 200': (r) => r.status === 200, 'health check response time < 200ms':
(r) => r.timings.duration < 200, });

// List appointments const listRes =
http.get('http://api.adyela.com/api/v1/appointments', { headers: {
'X-Tenant-ID': 'test-tenant', 'Authorization': 'Bearer ${TOKEN}', }, });
check(listRes, { 'list appointments status is 200': (r) => r.status === 200,
'list appointments response time < 500ms': (r) => r.timings.duration < 500, });

sleep(1); } \`\`\`

**Load Test Scenarios:**

- **Smoke Test**: 1-10 users, validate functionality
- **Load Test**: 50-100 users, normal conditions
- **Stress Test**: 100-500 users, find breaking point
- **Spike Test**: Sudden traffic surge
- **Soak Test**: 24h sustained load

---

### 6. Accessibility Testing (WCAG 2.1 AA)

#### Automated Accessibility Tests

\`\`\`typescript // tests/e2e/accessibility/a11y.spec.ts import { test, expect }
from '@playwright/test'; import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => { test('homepage should not have
accessibility violations', async ({ page }) => { await page.goto('/');

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);

});

test('login page should be keyboard navigable', async ({ page }) => { await
page.goto('/login');

    // Tab through form
    await page.keyboard.press('Tab');
    await expect(page.getByTestId('email-input')).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(page.getByTestId('password-input')).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(page.getByTestId('login-button')).toBeFocused();

});

test('dashboard has proper ARIA labels', async ({ page }) => { await
page.goto('/dashboard');

    // Check ARIA landmarks
    await expect(page.locator('[role="main"]')).toBeVisible();
    await expect(page.locator('[role="navigation"]')).toBeVisible();

    // Check ARIA labels on interactive elements
    const cards = page.locator('[data-testid*="card"]');
    for (const card of await cards.all()) {
      await expect(card).toHaveAttribute('aria-label');
    }

}); }); \`\`\`

**WCAG 2.1 AA Requirements:**

- [ ] Perceivable: Text alternatives, captions, adaptable content
- [ ] Operable: Keyboard accessible, enough time, seizure-safe
- [ ] Understandable: Readable, predictable, input assistance
- [ ] Robust: Compatible with assistive technologies

**Target:** 100% WCAG 2.1 AA compliance

---

### 7. Visual Regression Testing

#### Percy/Chromatic Integration (Optional)

\`\`\`typescript // tests/e2e/visual/visual-regression.spec.ts import { test }
from '@playwright/test'; import percySnapshot from '@percy/playwright';

test.describe('Visual Regression', () => { test('dashboard snapshot', async ({
page }) => { await page.goto('/dashboard'); await percySnapshot(page, 'Dashboard
Page'); });

test('appointment form snapshot', async ({ page }) => { await
page.goto('/appointments/new'); await percySnapshot(page, 'Appointment Form');
});

test('appointment form - validation errors', async ({ page }) => { await
page.goto('/appointments/new'); await page.getByTestId('submit-button').click();
await percySnapshot(page, 'Appointment Form - Validation Errors'); }); });
\`\`\`

---

## 📊 Quality Gates & CI/CD Integration

### Quality Gate Criteria

**All criteria must pass before merge:**

- [x] Linting: Zero errors
- [x] Type checking: Zero errors
- [ ] Unit tests: >80% coverage, all passing
- [ ] Integration tests: All passing
- [x] E2E tests: Critical flows passing
- [ ] Security scans: Zero high/critical vulnerabilities
- [x] Performance: Lighthouse score >90 (production build)
- [ ] Accessibility: Zero WCAG violations

### CI Pipeline

\`\`\`yaml

# .github/workflows/ci.yml

name: CI

on: [push, pull_request]

jobs: lint: runs-on: ubuntu-latest steps: - uses: actions/checkout@v3 - name:
Lint run: pnpm lint

type-check: runs-on: ubuntu-latest steps: - uses: actions/checkout@v3 - name:
Type Check run: pnpm type-check

unit-test: runs-on: ubuntu-latest steps: - uses: actions/checkout@v3 - name:
Unit Tests run: pnpm test --coverage - name: Upload Coverage uses:
codecov/codecov-action@v3

integration-test: runs-on: ubuntu-latest services: firestore: image:
google/cloud-sdk:emulators ports: - 8080:8080 steps: - uses:
actions/checkout@v3 - name: Integration Tests run: pnpm test:integration

e2e-test: runs-on: ubuntu-latest steps: - uses: actions/checkout@v3 - name:
Install Playwright run: pnpm playwright install --with-deps - name: Start
Services run: docker-compose up -d - name: E2E Tests run: pnpm test:e2e - name:
Upload Report uses: actions/upload-artifact@v3 if: always() with: name:
playwright-report path: playwright-report/

performance: runs-on: ubuntu-latest steps: - uses: actions/checkout@v3 - name:
Build Production run: pnpm build - name: Lighthouse CI run: lhci autorun \`\`\`

---

## 📚 Test Documentation

### Test Naming Conventions

\`\`\` Unit Tests:

- test*<function>*<scenario>\_<expected_result>
- Example: test_create_appointment_invalid_date_raises_error

Integration Tests:

- test*<endpoint>*<scenario>\_<status_code>
- Example: test_post_appointments_unauthorized_returns_401

E2E Tests:

- <user_role> <action> <object> <expected_result>
- Example: doctor can create appointment successfully \`\`\`

### Test Data Management

\`\`\`python

# tests/fixtures/factories.py

from datetime import datetime, timedelta import factory

class AppointmentFactory(factory.Factory): class Meta: model = Appointment

    id = factory.Sequence(lambda n: f"appointment-{n}")
    tenant_id = TenantId("test-tenant")
    patient_id = factory.Sequence(lambda n: f"patient-{n}")
    practitioner_id = factory.Sequence(lambda n: f"practitioner-{n}")
    start_time = factory.LazyFunction(lambda: datetime.utcnow() + timedelta(days=1))
    end_time = factory.LazyAttribute(lambda obj: obj.start_time + timedelta(hours=1))
    appointment_type = AppointmentType.VIDEO_CALL
    status = AppointmentStatus.SCHEDULED

\`\`\`

---

## 🛠️ Tools & Technologies

### Testing Tools

1. **Pytest** (Python unit/integration)
2. **Vitest** (JavaScript unit)
3. **Playwright** (E2E)
4. **Lighthouse CI** (Performance)
5. **k6** (Load testing)
6. **axe-core** (Accessibility)
7. **Schemathesis** (API contract)

### CI/CD

1. **GitHub Actions**: Pipeline execution
2. **Codecov**: Coverage reports
3. **Percy/Chromatic**: Visual regression (optional)

---

## 📊 Key Performance Indicators (KPIs)

### Test Coverage

- **Unit Test Coverage**: >80%
- **Integration Test Coverage**: 100% endpoints
- **E2E Test Coverage**: Top 20 user flows
- **Accessibility Coverage**: 100% pages

### Test Quality

- **Test Success Rate**: >99%
- **Flaky Test Rate**: <1%
- **Test Execution Time**: <10 minutes (full suite)
- **Bug Escape Rate**: <5% (bugs found in production)

### Performance

- **Lighthouse Score**: >90
- **P95 Response Time**: <500ms
- **Error Rate**: <1%
- **Throughput**: 100+ RPS sustained

---

## ✅ Success Criteria

### Phase 1: Foundation (Week 1)

- [ ] Unit test coverage >80% for backend
- [ ] Unit test coverage >75% for frontend
- [ ] E2E tests expanded to 30+ tests
- [ ] Quality gates enforced in CI/CD

### Phase 2: Expansion (Week 2)

- [ ] Integration tests for all API endpoints
- [ ] Performance testing with k6
- [ ] Visual regression testing setup
- [ ] Accessibility testing automated

### Phase 3: Excellence (Ongoing)

- [ ] Mutation testing implemented
- [ ] Property-based testing
- [ ] Chaos engineering experiments
- [ ] Performance budgets enforced

---

**Version History:**

- v1.0.0 (2025-10-05): Initial agent specification

**Agent Status:** ✅ Active | Ready for Deployment
