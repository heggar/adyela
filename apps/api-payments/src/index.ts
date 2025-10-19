import express, { Application } from 'express';
import cors from 'cors';
import { Firestore } from '@google-cloud/firestore';
import { config } from './config';
import { StripeService } from './infrastructure/stripe/StripeService';
import { FirestorePaymentRepository } from './infrastructure/repositories/FirestorePaymentRepository';
import { createPaymentRoutes } from './presentation/routes/payments';
import { errorHandler } from './presentation/middleware/errorHandler';

const app: Application = express();

// Initialize Firestore
const firestore = new Firestore({
  projectId: process.env.GCP_PROJECT_ID,
});

// Initialize services
const stripeService = new StripeService(config.stripe.secretKey, config.stripe.webhookSecret);
const paymentRepository = new FirestorePaymentRepository(firestore);

// Middleware
app.use(
  cors({
    origin: config.cors.origins,
    credentials: true,
  })
);

// For Stripe webhook, we need raw body
app.use('/api/v1/payments/webhook', express.raw({ type: 'application/json' }));

// For all other routes, parse JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'api-payments',
    timestamp: new Date().toISOString(),
  });
});

// API routes
app.use(`${config.apiPrefix}/payments`, createPaymentRoutes(paymentRepository, stripeService));

// Error handling middleware (must be last)
app.use(errorHandler);

// Start server
const PORT = config.port;
app.listen(PORT, () => {
  console.log(`🚀 api-payments running on port ${PORT}`);
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
