import { StripeService } from '../../src/infrastructure/stripe/StripeService';
import Stripe from 'stripe';
import { Currency } from '../../src/config';
import { PaymentProcessingError } from '../../src/domain/exceptions';

jest.mock('stripe');

describe('StripeService', () => {
  let stripeService: StripeService;
  let mockStripe: jest.Mocked<Stripe>;

  beforeEach(() => {
    mockStripe = {
      paymentIntents: {
        create: jest.fn(),
        confirm: jest.fn(),
      },
      refunds: {
        create: jest.fn(),
      },
      webhooks: {
        constructEvent: jest.fn(),
      },
    } as any;

    (Stripe as any).mockImplementation(() => mockStripe);
    stripeService = new StripeService('sk_test_123', 'whsec_123');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createPaymentIntent', () => {
    it('should create a payment intent successfully', async () => {
      // Arrange
      const amount = 100.5;
      const currency = Currency.USD;
      const metadata = {
        appointmentId: 'appt_123',
        patientId: 'patient_123',
      };

      const mockPaymentIntent = {
        id: 'pi_123',
        client_secret: 'pi_123_secret_456',
        amount: 10050,
        currency: 'usd',
      };

      mockStripe.paymentIntents.create.mockResolvedValue(mockPaymentIntent as any);

      // Act
      const result = await stripeService.createPaymentIntent(amount, currency, metadata);

      // Assert
      expect(mockStripe.paymentIntents.create).toHaveBeenCalledWith({
        amount: 10050, // $100.50 in cents
        currency: 'usd',
        metadata,
        automatic_payment_methods: { enabled: true },
      });
      expect(result).toEqual({
        paymentIntentId: 'pi_123',
        clientSecret: 'pi_123_secret_456',
      });
    });

    it('should convert amount to cents correctly', async () => {
      // Arrange
      const amount = 49.99;
      mockStripe.paymentIntents.create.mockResolvedValue({
        id: 'pi_123',
        client_secret: 'secret',
      } as any);

      // Act
      await stripeService.createPaymentIntent(amount, Currency.USD, {});

      // Assert
      expect(mockStripe.paymentIntents.create).toHaveBeenCalledWith(
        expect.objectContaining({
          amount: 4999, // $49.99 in cents
        })
      );
    });

    it('should throw PaymentProcessingError on failure', async () => {
      // Arrange
      mockStripe.paymentIntents.create.mockRejectedValue(new Error('Stripe API error'));

      // Act & Assert
      await expect(stripeService.createPaymentIntent(100, Currency.USD, {})).rejects.toThrow(
        PaymentProcessingError
      );
    });
  });

  describe('confirmPaymentIntent', () => {
    it('should confirm payment intent successfully', async () => {
      // Arrange
      const paymentIntentId = 'pi_123';
      mockStripe.paymentIntents.confirm.mockResolvedValue({} as any);

      // Act
      await stripeService.confirmPaymentIntent(paymentIntentId);

      // Assert
      expect(mockStripe.paymentIntents.confirm).toHaveBeenCalledWith(paymentIntentId);
    });

    it('should throw PaymentProcessingError on failure', async () => {
      // Arrange
      mockStripe.paymentIntents.confirm.mockRejectedValue(new Error('Confirmation failed'));

      // Act & Assert
      await expect(stripeService.confirmPaymentIntent('pi_123')).rejects.toThrow(
        PaymentProcessingError
      );
    });
  });

  describe('refundPayment', () => {
    it('should create full refund when amount not specified', async () => {
      // Arrange
      const paymentIntentId = 'pi_123';
      mockStripe.refunds.create.mockResolvedValue({} as any);

      // Act
      await stripeService.refundPayment(paymentIntentId);

      // Assert
      expect(mockStripe.refunds.create).toHaveBeenCalledWith({
        payment_intent: paymentIntentId,
      });
    });

    it('should create partial refund when amount specified', async () => {
      // Arrange
      const paymentIntentId = 'pi_123';
      const refundAmount = 50.75;
      mockStripe.refunds.create.mockResolvedValue({} as any);

      // Act
      await stripeService.refundPayment(paymentIntentId, refundAmount);

      // Assert
      expect(mockStripe.refunds.create).toHaveBeenCalledWith({
        payment_intent: paymentIntentId,
        amount: 5075, // $50.75 in cents
      });
    });

    it('should throw PaymentProcessingError on failure', async () => {
      // Arrange
      mockStripe.refunds.create.mockRejectedValue(new Error('Refund failed'));

      // Act & Assert
      await expect(stripeService.refundPayment('pi_123')).rejects.toThrow(PaymentProcessingError);
    });
  });

  describe('constructWebhookEvent', () => {
    it('should construct webhook event successfully', async () => {
      // Arrange
      const payload = '{"type":"payment_intent.succeeded"}';
      const signature = 'sig_123';
      const mockEvent = { type: 'payment_intent.succeeded', data: {} };

      mockStripe.webhooks.constructEvent.mockReturnValue(mockEvent as any);

      // Act
      const result = await stripeService.constructWebhookEvent(payload, signature);

      // Assert
      expect(mockStripe.webhooks.constructEvent).toHaveBeenCalledWith(
        payload,
        signature,
        'whsec_123'
      );
      expect(result).toEqual(mockEvent);
    });

    it('should throw PaymentProcessingError on invalid signature', async () => {
      // Arrange
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error('Invalid signature');
      });

      // Act & Assert
      await expect(stripeService.constructWebhookEvent('payload', 'invalid_sig')).rejects.toThrow(
        PaymentProcessingError
      );
    });
  });
});
