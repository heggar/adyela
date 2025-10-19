import { Payment, CreatePaymentData } from '../../domain/entities/Payment';
import { PaymentStatus } from '../../config';
import { IPaymentRepository } from '../ports/IPaymentRepository';
import { IStripeService } from '../ports/IStripeService';
import { InvalidPaymentAmountError } from '../../domain/exceptions';

export class CreatePaymentIntentUseCase {
  constructor(
    private paymentRepository: IPaymentRepository,
    private stripeService: IStripeService
  ) {}

  async execute(data: CreatePaymentData): Promise<Payment> {
    // Validate amount
    if (data.amount <= 0) {
      throw new InvalidPaymentAmountError(data.amount);
    }

    // Create Stripe payment intent
    const { paymentIntentId, clientSecret } = await this.stripeService.createPaymentIntent(
      data.amount,
      data.currency,
      {
        appointmentId: data.appointmentId,
        patientId: data.patientId,
        professionalId: data.professionalId,
        ...data.metadata,
      }
    );

    // Create payment record
    const payment: Payment = {
      id: crypto.randomUUID(),
      appointmentId: data.appointmentId,
      patientId: data.patientId,
      professionalId: data.professionalId,
      amount: data.amount,
      currency: data.currency,
      status: PaymentStatus.PENDING,
      stripePaymentIntentId: paymentIntentId,
      stripeClientSecret: clientSecret,
      metadata: data.metadata || {},
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // Save to repository
    return await this.paymentRepository.create(payment);
  }
}
