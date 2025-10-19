import express, { Application } from 'express';
import cors from 'cors';
import { Firestore } from '@google-cloud/firestore';
import { config } from './config';
import { SendGridService } from './infrastructure/email/SendGridService';
import { TwilioService } from './infrastructure/sms/TwilioService';
import { FirebaseService } from './infrastructure/push/FirebaseService';
import { FirestoreNotificationRepository } from './infrastructure/repositories/FirestoreNotificationRepository';
import { createNotificationRoutes } from './presentation/routes/notifications';
import { errorHandler } from './presentation/middleware/errorHandler';

const app: Application = express();

// Initialize Firestore
const firestore = new Firestore({
  projectId: process.env.GCP_PROJECT_ID,
});

// Initialize services
const emailService = new SendGridService(
  config.sendgrid.apiKey,
  config.sendgrid.fromEmail,
  config.sendgrid.fromName
);

const smsService = new TwilioService(
  config.twilio.accountSid,
  config.twilio.authToken,
  config.twilio.phoneNumber
);

const pushService = new FirebaseService(
  config.firebase.projectId,
  config.firebase.clientEmail,
  config.firebase.privateKey
);

const notificationRepository = new FirestoreNotificationRepository(firestore);

// Middleware
app.use(
  cors({
    origin: config.cors.origins,
    credentials: true,
  })
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'api-notifications',
    timestamp: new Date().toISOString(),
  });
});

// API routes
app.use(
  `${config.apiPrefix}/notifications`,
  createNotificationRoutes(notificationRepository, emailService, smsService, pushService)
);

// Error handling middleware (must be last)
app.use(errorHandler);

// Start server
const PORT = config.port;
app.listen(PORT, () => {
  console.log(`🚀 api-notifications running on port ${PORT}`);
  console.log(`📝 Environment: ${config.nodeEnv}`);
  console.log(`🔗 API Prefix: ${config.apiPrefix}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  process.exit(0);
});

export default app;
