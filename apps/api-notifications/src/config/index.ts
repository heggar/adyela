export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3002', 10),
  apiPrefix: process.env.API_PREFIX || '/api/v1',

  sendgrid: {
    apiKey: process.env.SENDGRID_API_KEY || '',
    fromEmail: process.env.SENDGRID_FROM_EMAIL || 'noreply@adyela.com',
    fromName: process.env.SENDGRID_FROM_NAME || 'Adyela Healthcare',
  },

  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID || '',
    authToken: process.env.TWILIO_AUTH_TOKEN || '',
    phoneNumber: process.env.TWILIO_PHONE_NUMBER || '',
  },

  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  },

  pubsub: {
    topicNotifications: process.env.PUBSUB_TOPIC_NOTIFICATIONS || 'notifications',
    subscriptionAppointments:
      process.env.PUBSUB_SUBSCRIPTION_APPOINTMENTS || 'appointments-notifications',
    subscriptionPayments: process.env.PUBSUB_SUBSCRIPTION_PAYMENTS || 'payments-notifications',
  },

  auth: {
    serviceUrl: process.env.AUTH_SERVICE_URL || 'http://localhost:8001',
    validateEndpoint: process.env.AUTH_VALIDATE_TOKEN_ENDPOINT || '/api/v1/auth/validate-token',
  },

  cors: {
    origins: (process.env.CORS_ORIGINS || 'http://localhost:3000').split(','),
  },

  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
};

export enum NotificationType {
  EMAIL = 'email',
  SMS = 'sms',
  PUSH = 'push',
}

export enum NotificationStatus {
  PENDING = 'pending',
  SENT = 'sent',
  FAILED = 'failed',
  DELIVERED = 'delivered',
}

export enum NotificationTemplate {
  APPOINTMENT_CREATED = 'appointment_created',
  APPOINTMENT_CONFIRMED = 'appointment_confirmed',
  APPOINTMENT_CANCELLED = 'appointment_cancelled',
  APPOINTMENT_REMINDER = 'appointment_reminder',
  PAYMENT_RECEIVED = 'payment_received',
  PAYMENT_FAILED = 'payment_failed',
  PROFESSIONAL_APPROVED = 'professional_approved',
  PROFESSIONAL_REJECTED = 'professional_rejected',
  WELCOME_EMAIL = 'welcome_email',
}
