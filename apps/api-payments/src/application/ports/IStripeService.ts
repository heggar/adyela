import { Currency } from '../../config';

export interface PaymentIntentResult {
  paymentIntentId: string;
  clientSecret: string;
}

export interface IStripeService {
  createPaymentIntent(
    amount: number,
    currency: Currency,
    metadata: Record<string, string>
  ): Promise<PaymentIntentResult>;
  confirmPaymentIntent(paymentIntentId: string): Promise<void>;
  refundPayment(paymentIntentId: string, amount?: number): Promise<void>;
  constructWebhookEvent(payload: string, signature: string): Promise<any>;
}
