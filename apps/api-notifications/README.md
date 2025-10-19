# api-notifications

Notifications microservice for the Adyela healthcare platform. Handles multi-channel notifications including email (SendGrid), SMS (Twilio), and push notifications (Firebase).

## Architecture

This microservice follows **Hexagonal Architecture (Ports & Adapters)** with clear separation of concerns:

```
src/
├── domain/              # Business entities and domain logic
│   ├── entities/        # Notification entity
│   └── exceptions/      # Domain-specific exceptions
├── application/         # Use cases and ports (interfaces)
│   ├── ports/           # Repository and service interfaces
│   └── use-cases/       # Business logic orchestration
├── infrastructure/      # External service implementations
│   ├── email/           # SendGrid integration
│   ├── sms/             # Twilio integration
│   ├── push/            # Firebase Cloud Messaging
│   └── repositories/    # Firestore notification repository
├── presentation/        # HTTP API layer
│   ├── routes/          # Express routes
│   └── middleware/      # Auth, error handling
└── config/              # Configuration and constants
```

## Features

- ✅ **Email Notifications** - SendGrid integration with HTML templates
- ✅ **SMS Notifications** - Twilio SMS delivery
- ✅ **Push Notifications** - Firebase Cloud Messaging (FCM)
- ✅ **Template Management** - Pre-defined templates for common events
- ✅ **Notification History** - Track sent notifications in Firestore
- ✅ **Status Tracking** - pending → sent → delivered/failed
- ✅ **Multi-Channel** - Support for email, SMS, and push in a single service
- ✅ **Authentication** - Token-based auth via api-auth service

## Tech Stack

- **Runtime**: Node.js 20+
- **Framework**: Express 4.18
- **Language**: TypeScript 5.3
- **Email**: SendGrid SDK
- **SMS**: Twilio SDK
- **Push**: Firebase Admin SDK
- **Database**: Google Cloud Firestore
- **Validation**: Zod 3.22
- **Testing**: Jest + ts-jest

## Prerequisites

- Node.js >= 20.0.0
- SendGrid account with API key
- Twilio account with credentials
- Firebase project with Cloud Messaging enabled
- Google Cloud Firestore database
- api-auth service running (for authentication)

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Application
NODE_ENV=development
PORT=3002
API_PREFIX=/api/v1

# SendGrid
SENDGRID_API_KEY=SG.your_sendgrid_api_key_here
SENDGRID_FROM_EMAIL=noreply@adyela.com
SENDGRID_FROM_NAME=Adyela Healthcare

# Twilio
TWILIO_ACCOUNT_SID=ACyour_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+1234567890

# Firebase
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=your-private-key-here

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

All endpoints require Bearer token authentication.

### Endpoints

#### Health Check

```http
GET /health
```

**Response:**

```json
{
  "status": "healthy",
  "service": "api-notifications",
  "timestamp": "2025-01-18T10:00:00.000Z"
}
```

---

#### Send Notification

```http
POST /api/v1/notifications/send
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "type": "email",
  "template": "appointment_confirmed",
  "recipient": "patient@example.com",
  "subject": "Appointment Confirmation",
  "data": {
    "date": "2025-01-20",
    "time": "10:00 AM"
  },
  "metadata": {
    "appointmentId": "appt_123"
  }
}
```

**Response (201):**

```json
{
  "success": true,
  "data": {
    "id": "notification_123",
    "type": "email",
    "template": "appointment_confirmed",
    "recipient": "patient@example.com",
    "status": "sent",
    "sentAt": "2025-01-18T10:00:00.000Z"
  }
}
```

**Notification Types:**

- `email` - Email notification via SendGrid
- `sms` - SMS notification via Twilio
- `push` - Push notification via Firebase

**Errors:**

- `400` - Invalid recipient or validation error
- `401` - Missing or invalid authentication token
- `422` - Notification send error

---

#### Get Notification by ID

```http
GET /api/v1/notifications/:id
Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "data": {
    "id": "notification_123",
    "type": "email",
    "template": "appointment_confirmed",
    "recipient": "patient@example.com",
    "subject": "Appointment Confirmation",
    "status": "sent",
    "sentAt": "2025-01-18T10:00:00.000Z",
    "deliveredAt": "2025-01-18T10:00:05.000Z",
    "createdAt": "2025-01-18T10:00:00.000Z",
    "updatedAt": "2025-01-18T10:00:05.000Z"
  }
}
```

**Errors:**

- `404` - Notification not found

---

#### Get Notifications by Recipient

```http
GET /api/v1/notifications/recipient/:recipient?limit=50
Authorization: Bearer <token>
```

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": "notification_123",
      "type": "email",
      "template": "appointment_confirmed",
      "status": "sent",
      "sentAt": "2025-01-18T10:00:00.000Z",
      "createdAt": "2025-01-18T10:00:00.000Z"
    }
  ]
}
```

## Notification Templates

### Available Templates

| Template                | Type        | Description                       |
| ----------------------- | ----------- | --------------------------------- |
| `appointment_created`   | All         | Appointment created confirmation  |
| `appointment_confirmed` | All         | Appointment confirmation          |
| `appointment_cancelled` | All         | Appointment cancellation notice   |
| `appointment_reminder`  | Email, SMS  | Appointment reminder (24h before) |
| `payment_received`      | Email, Push | Payment received confirmation     |
| `payment_failed`        | Email, SMS  | Payment failure notification      |
| `professional_approved` | Email       | Professional account approved     |
| `professional_rejected` | Email       | Professional account rejected     |
| `welcome_email`         | Email       | Welcome email for new users       |

### Template Variables

Templates support variable substitution using `{{variable}}` syntax:

```javascript
// Example: appointment_confirmed template
"Your appointment on {{date}} at {{time}} has been confirmed."

// With data:
{
  "date": "2025-01-20",
  "time": "10:00 AM"
}

// Renders to:
"Your appointment on 2025-01-20 at 10:00 AM has been confirmed."
```

## Notification Status Flow

```
pending → sent → delivered ✓
            ↓
          failed ✗
```

## Testing

### Unit Tests

Tests are located in `tests/unit/` and cover:

- ✅ SendGridService - Email sending functionality
- ✅ TwilioService - SMS sending functionality
- ✅ SendNotificationUseCase - Business logic and orchestration

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

- `NotificationNotFoundException` - Notification record not found (404)
- `InvalidRecipientError` - Empty or invalid recipient (400)
- `NotificationSendError` - Sending failed (422)
- `TemplateNotFoundError` - Template not found (404)

All errors are caught by the global error handler middleware.

## Firestore Data Model

### Collection: `notifications`

```typescript
{
  id: string;                    // UUID
  type: "email" | "sms" | "push";
  template: string;              // Template name
  recipient: string;             // Email, phone, or device token
  subject?: string;              // For emails
  body: string;                  // Rendered message
  data?: Record<string, unknown>; // Template variables
  status: "pending" | "sent" | "failed" | "delivered";
  sentAt?: Date;
  deliveredAt?: Date;
  failureReason?: string;
  metadata: Record<string, string>;
  createdAt: Date;
  updatedAt: Date;
}
```

## Integration with Other Services

### api-auth

Validates JWT tokens for all authenticated endpoints.

### api-appointments

Notifications are sent for appointment events:

- Appointment created → `appointment_created` notification
- Appointment confirmed → `appointment_confirmed` notification
- Appointment cancelled → `appointment_cancelled` notification
- 24h before → `appointment_reminder` notification

### api-payments

Notifications are sent for payment events:

- Payment succeeded → `payment_received` notification
- Payment failed → `payment_failed` notification

### api-admin

Notifications are sent for professional approval:

- Account approved → `professional_approved` notification
- Account rejected → `professional_rejected` notification

## Event-Driven Architecture

### Pub/Sub Integration (Future)

The service can subscribe to Pub/Sub topics to send notifications automatically:

```typescript
// Subscribe to appointment events
pubsub.subscription('appointments-notifications').on('message', async message => {
  const event = JSON.parse(message.data.toString());

  if (event.type === 'AppointmentCreated') {
    await sendNotificationUseCase.execute({
      type: NotificationType.EMAIL,
      template: NotificationTemplate.APPOINTMENT_CREATED,
      recipient: event.patientEmail,
      data: { date: event.date, time: event.time },
    });
  }

  message.ack();
});
```

## Security Considerations

- ✅ **No hardcoded secrets** - All credentials in environment variables
- ✅ **Authentication required** - All endpoints require valid JWT
- ✅ **Input validation** - Zod schemas validate all inputs
- ✅ **Rate limiting** - Should be implemented at API Gateway level
- ⚠️ **HIPAA Compliance** - PHI may be included in notifications, ensure encryption

## Monitoring & Logging

- HTTP requests logged with method, path, status
- Notification lifecycle events logged (sent, failed)
- Errors logged with stack traces in development
- Failed notifications should trigger alerts

## Future Enhancements

- [ ] Template management UI/API
- [ ] Scheduled notifications (cron jobs)
- [ ] Notification preferences per user
- [ ] Delivery status webhooks (SendGrid, Twilio)
- [ ] Rich HTML email templates
- [ ] Notification retry logic
- [ ] A/B testing for notification content
- [ ] Analytics and reporting

## License

UNLICENSED - Private use only

---

**Maintained by**: Adyela Development Team
**Version**: 0.1.0
**Last Updated**: 2025-01-18
