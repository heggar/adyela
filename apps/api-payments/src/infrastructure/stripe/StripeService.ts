import Stripe from 'stripe';
import { IStripeService, PaymentIntentResult } from '../../application/ports/IStripeService';
import { Currency } from '../../config';
import { PaymentProcessingError } from '../../domain/exceptions';

export class StripeService implements IStripeService {
  private stripe: Stripe;
  private webhookSecret: string;

  constructor(secretKey: string, webhookSecret: string) {
    this.stripe = new Stripe(secretKey, {
      apiVersion: '2023-10-16',
    });
    this.webhookSecret = webhookSecret;
  }

  async createPaymentIntent(
    amount: number,
    currency: Currency,
    metadata: Record<string, string>
  ): Promise<PaymentIntentResult> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency,
        metadata,
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return {
        paymentIntentId: paymentIntent.id,
        clientSecret: paymentIntent.client_secret!,
      };
    } catch (error) {
      throw new PaymentProcessingError(`Failed to create payment intent: ${error}`);
    }
  }

  async confirmPaymentIntent(paymentIntentId: string): Promise<void> {
    try {
      await this.stripe.paymentIntents.confirm(paymentIntentId);
    } catch (error) {
      throw new PaymentProcessingError(`Failed to confirm payment intent: ${error}`);
    }
  }

  async refundPayment(paymentIntentId: string, amount?: number): Promise<void> {
    try {
      const refundData: Stripe.RefundCreateParams = {
        payment_intent: paymentIntentId,
      };

      if (amount) {
        refundData.amount = Math.round(amount * 100);
      }

      await this.stripe.refunds.create(refundData);
    } catch (error) {
      throw new PaymentProcessingError(`Failed to refund payment: ${error}`);
    }
  }

  async constructWebhookEvent(payload: string, signature: string): Promise<any> {
    try {
      return this.stripe.webhooks.constructEvent(payload, signature, this.webhookSecret);
    } catch (error) {
      throw new PaymentProcessingError(`Invalid webhook signature: ${error}`);
    }
  }
}
