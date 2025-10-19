# api-payments

Payment processing microservice for the Adyela healthcare platform. Handles
Stripe payment intents, webhooks, and payment lifecycle management.

## Architecture

This microservice follows **Hexagonal Architecture (Ports & Adapters)** with
clear separation of concerns:

```
src/
├── domain/              # Business entities and domain logic
│   ├── entities/        # Payment entity
│   └── exceptions/      # Domain-specific exceptions
├── application/         # Use cases and ports (interfaces)
│   ├── ports/           # Repository and service interfaces
│   └── use-cases/       # Business logic orchestration
├── infrastructure/      # External service implementations
│   ├── repositories/    # Firestore payment repository
│   └── stripe/          # Stripe SDK integration
├── presentation/        # HTTP API layer
│   ├── routes/          # Express routes
│   └── middleware/      # Auth, error handling
└── config/              # Configuration and constants
```

## Features

- ✅ **Stripe Payment Intents** - Create and confirm payment intents
- ✅ **Webhook Handling** - Process Stripe webhook events
- ✅ **Payment Lifecycle** - Track payment status (pending →
  succeeded/failed/cancelled)
- ✅ **Refund Support** - Process full and partial refunds
- ✅ **Multi-Currency** - Support USD and EUR
- ✅ **Authentication** - Token-based auth via api-auth service
- ✅ **Firestore Storage** - Persistent payment records

## Tech Stack

- **Runtime**: Node.js 20+
- **Framework**: Express 4.18
- **Language**: TypeScript 5.3
- **Payment Provider**: Stripe SDK 14.12
- **Database**: Google Cloud Firestore
- **Validation**: Zod 3.22
- **Testing**: Jest + ts-jest

## Prerequisites

- Node.js >= 20.0.0
- Stripe account with API keys
- Google Cloud Firestore database
- api-auth service running (for authentication)

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Application
NODE_ENV=development
PORT=3001
API_PREFIX=/api/v1

# Stripe
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Google Cloud
GCP_PROJECT_ID=your-gcp-project-id

# Auth Service
AUTH_SERVICE_URL=http://localhost:8001
AUTH_VALIDATE_TOKEN_ENDPOINT=/api/v1/auth/validate-token

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Logging
LOG_LEVEL=info
```

## Installation

```bash
# Install dependencies
npm install

# or using pnpm (recommended)
pnpm install
```

## Development

```bash
# Start development server with hot reload
npm run dev

# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Lint code
npm run lint

# Format code
npm run format
```

## Build & Production

```bash
# Build for production
npm run build

# Start production server
npm start
```

## API Endpoints

### Authentication

All endpoints except `/health` and `/webhook` require Bearer token
authentication.

### Endpoints

#### Health Check

```http
GET /health
```

**Response:**

```json
{
  "status": "healthy",
  "service": "api-payments",
  "timestamp": "2025-01-01T10:00:00.000Z"
}
```

---

#### Create Payment Intent

```http
POST /api/v1/payments/intent
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "appointmentId": "uuid",
  "patientId": "uuid",
  "professionalId": "uuid",
  "amount": 150.0,
  "currency": "usd",
  "metadata": {
    "notes": "Initial consultation"
  }
}
```

**Response (201):**

```json
{
  "success": true,
  "data": {
    "paymentId": "payment_123",
    "clientSecret": "pi_123_secret_456",
    "amount": 150.0,
    "currency": "usd",
    "status": "pending"
  }
}
```

**Errors:**

- `400` - Invalid payment amount or validation error
- `401` - Missing or invalid authentication token
- `422` - Payment processing error

---

#### Get Payment by ID

```http
GET /api/v1/payments/:id
Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": "payment_123",
    "appointmentId": "appt_123",
    "amount": 150.0,
    "currency": "usd",
    "status": "succeeded",
    "createdAt": "2025-01-01T10:00:00.000Z",
    "updatedAt": "2025-01-01T10:05:00.000Z"
  }
}
```

**Errors:**

- `404` - Payment not found

---

#### Get Payment by Appointment

```http
GET /api/v1/payments/appointment/:appointmentId
Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": "payment_123",
    "appointmentId": "appt_123",
    "amount": 150.0,
    "currency": "usd",
    "status": "pending",
    "createdAt": "2025-01-01T10:00:00.000Z",
    "updatedAt": "2025-01-01T10:00:00.000Z"
  }
}
```

**Errors:**

- `404` - Payment not found for appointment

---

#### Stripe Webhook Handler

```http
POST /api/v1/payments/webhook
Content-Type: application/json
Stripe-Signature: <signature>
```

**Supported Events:**

- `payment_intent.succeeded` - Payment completed successfully
- `payment_intent.payment_failed` - Payment failed
- `payment_intent.canceled` - Payment canceled
- `charge.refunded` - Payment refunded

**Response (200):**

```json
{
  "received": true
}
```

**Errors:**

- `400` - Missing signature or invalid payload

## Payment Status Flow

```
pending → processing → succeeded ✓
                    → failed ✗
        → cancelled ✗
succeeded → refunded
```

## Testing

### Unit Tests

Tests are located in `tests/unit/` and cover:

- ✅ StripeService - Payment intent creation, confirmation, refunds, webhook
  validation
- ✅ CreatePaymentIntentUseCase - Business logic validation
- ✅ FirestorePaymentRepository - Database operations

```bash
# Run all tests
npm test

# Run with coverage (target: 80%+)
npm run test:coverage
```

### Test Coverage Thresholds

Configured in `jest.config.js`:

- Branches: 80%
- Functions: 80%
- Lines: 80%
- Statements: 80%

## Error Handling

The service uses domain-specific exceptions:

- `PaymentNotFoundException` - Payment record not found (404)
- `InvalidPaymentAmountError` - Amount <= 0 (400)
- `PaymentProcessingError` - Stripe API errors (422)

All errors are caught by the global error handler middleware.

## Stripe Webhook Setup

1. Configure webhook endpoint in Stripe Dashboard:

   ```
   https://your-domain.com/api/v1/payments/webhook
   ```

2. Select events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`
   - `charge.refunded`

3. Copy webhook signing secret to `STRIPE_WEBHOOK_SECRET`

4. Test webhook locally:

   ```bash
   # Install Stripe CLI
   stripe listen --forward-to localhost:3001/api/v1/payments/webhook

   # Trigger test event
   stripe trigger payment_intent.succeeded
   ```

## Firestore Data Model

### Collection: `payments`

```typescript
{
  id: string; // UUID
  appointmentId: string; // UUID
  patientId: string; // UUID
  professionalId: string; // UUID
  amount: number; // Decimal (e.g., 150.00)
  currency: 'usd' | 'eur';
  status: 'pending' | 'processing' | 'succeeded' | 'failed' | 'cancelled' | 'refunded';
  stripePaymentIntentId: string; // Stripe PI ID
  stripeClientSecret: string; // For client-side confirmation
  metadata: Record<string, string>;
  createdAt: Date;
  updatedAt: Date;
}
```

## Integration with Other Services

### api-auth

Validates JWT tokens for all authenticated endpoints.

**Token Validation Flow:**

1. Client sends `Authorization: Bearer <token>`
2. api-payments forwards token to api-auth validation endpoint
3. api-auth returns user data or 401
4. api-payments proceeds or rejects request

### api-appointments

Payments are created for appointments.

**Event Flow:**

1. Appointment created → Payment intent created
2. Payment succeeded → Appointment confirmed (via webhook → event)
3. Payment failed → Appointment cancelled

### Recommended Event Listeners

Subscribe to payment events via Google Pub/Sub:

```typescript
// Events published by api-payments
PaymentCreated { paymentId, appointmentId, amount, status }
PaymentSucceeded { paymentId, appointmentId }
PaymentFailed { paymentId, appointmentId, reason }
PaymentRefunded { paymentId, appointmentId, amount }
```

## Security Considerations

- ✅ **No hardcoded secrets** - All credentials in environment variables
- ✅ **Webhook signature verification** - Prevents forged webhook events
- ✅ **Amount validation** - Prevents negative or zero payments
- ✅ **Authentication required** - All endpoints except webhook require valid
  JWT
- ✅ **CORS configured** - Only allowed origins can access API
- ⚠️ **PCI Compliance** - Using Stripe handles PCI compliance (no card data
  stored)

## Monitoring & Logging

- HTTP requests logged with method, path, status
- Payment lifecycle events logged (created, succeeded, failed)
- Errors logged with stack traces in development
- Webhook events logged for audit trail

## Future Enhancements

- [ ] Support more currencies (GBP, CAD, etc.)
- [ ] Subscription payments for recurring appointments
- [ ] Payment method management (save cards)
- [ ] Invoice generation
- [ ] Payment analytics and reporting
- [ ] Retry logic for failed webhooks
- [ ] Rate limiting

## License

UNLICENSED - Private use only

---

**Maintained by**: Adyela Development Team **Version**: 0.1.0 **Last Updated**:
2025-01-18
