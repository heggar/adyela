import { Router, Response } from 'express';
import { z } from 'zod';
import { CreatePaymentIntentUseCase } from '../../application/use-cases/CreatePaymentIntent';
import { IPaymentRepository } from '../../application/ports/IPaymentRepository';
import { IStripeService } from '../../application/ports/IStripeService';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { asyncHandler } from '../middleware/errorHandler';
import { Currency, PaymentStatus } from '../../config';

// Request validation schemas
const CreatePaymentIntentSchema = z.object({
  appointmentId: z.string().uuid(),
  patientId: z.string().uuid(),
  professionalId: z.string().uuid(),
  amount: z.number().positive(),
  currency: z.nativeEnum(Currency),
  metadata: z.record(z.string()).optional(),
});

export const createPaymentRoutes = (
  paymentRepository: IPaymentRepository,
  stripeService: IStripeService
): Router => {
  const router = Router();

  // Create payment intent
  router.post(
    '/intent',
    authenticateToken,
    asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
      const validatedData = CreatePaymentIntentSchema.parse(req.body);

      const useCase = new CreatePaymentIntentUseCase(paymentRepository, stripeService);

      const payment = await useCase.execute(validatedData);

      return res.status(201).json({
        success: true,
        data: {
          paymentId: payment.id,
          clientSecret: payment.stripeClientSecret,
          amount: payment.amount,
          currency: payment.currency,
          status: payment.status,
        },
      });
    })
  );

  // Get payment by ID
  router.get(
    '/:id',
    authenticateToken,
    asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
      const { id } = req.params;
      const payment = await paymentRepository.findById(id);

      return res.json({
        success: true,
        data: {
          id: payment.id,
          appointmentId: payment.appointmentId,
          amount: payment.amount,
          currency: payment.currency,
          status: payment.status,
          createdAt: payment.createdAt,
          updatedAt: payment.updatedAt,
        },
      });
    })
  );

  // Get payment by appointment ID
  router.get(
    '/appointment/:appointmentId',
    authenticateToken,
    asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
      const { appointmentId } = req.params;
      const payment = await paymentRepository.findByAppointmentId(appointmentId);

      if (!payment) {
        return res.status(404).json({
          success: false,
          error: 'Payment not found for this appointment',
        });
      }

      return res.json({
        success: true,
        data: {
          id: payment.id,
          appointmentId: payment.appointmentId,
          amount: payment.amount,
          currency: payment.currency,
          status: payment.status,
          createdAt: payment.createdAt,
          updatedAt: payment.updatedAt,
        },
      });
    })
  );

  // Stripe webhook handler
  router.post(
    '/webhook',
    asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
      const signature = req.headers['stripe-signature'] as string;
      const payload = JSON.stringify(req.body);

      if (!signature) {
        return res.status(400).json({
          success: false,
          error: 'Missing stripe-signature header',
        });
      }

      // Construct and verify webhook event
      const event = await stripeService.constructWebhookEvent(payload, signature);

      // Handle different event types
      switch (event.type) {
        case 'payment_intent.succeeded': {
          const paymentIntent = event.data.object;
          const payment = await paymentRepository.findByStripePaymentIntentId(paymentIntent.id);

          if (payment) {
            await paymentRepository.updateStatus(payment.id, PaymentStatus.SUCCEEDED);
            console.log(`Payment ${payment.id} succeeded`);
          }
          break;
        }

        case 'payment_intent.payment_failed': {
          const paymentIntent = event.data.object;
          const payment = await paymentRepository.findByStripePaymentIntentId(paymentIntent.id);

          if (payment) {
            await paymentRepository.updateStatus(payment.id, PaymentStatus.FAILED);
            console.log(`Payment ${payment.id} failed`);
          }
          break;
        }

        case 'payment_intent.canceled': {
          const paymentIntent = event.data.object;
          const payment = await paymentRepository.findByStripePaymentIntentId(paymentIntent.id);

          if (payment) {
            await paymentRepository.updateStatus(payment.id, PaymentStatus.CANCELLED);
            console.log(`Payment ${payment.id} cancelled`);
          }
          break;
        }

        case 'charge.refunded': {
          const charge = event.data.object;
          const payment = await paymentRepository.findByStripePaymentIntentId(
            charge.payment_intent as string
          );

          if (payment) {
            await paymentRepository.updateStatus(payment.id, PaymentStatus.REFUNDED);
            console.log(`Payment ${payment.id} refunded`);
          }
          break;
        }

        default:
          console.log(`Unhandled event type: ${event.type}`);
      }

      return res.json({ received: true });
    })
  );

  return router;
};
