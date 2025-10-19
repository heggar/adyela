import { CreatePaymentIntentUseCase } from '../../src/application/use-cases/CreatePaymentIntent';
import { IPaymentRepository } from '../../src/application/ports/IPaymentRepository';
import { IStripeService } from '../../src/application/ports/IStripeService';
import { Currency, PaymentStatus } from '../../src/config';
import { InvalidPaymentAmountError } from '../../src/domain/exceptions';

describe('CreatePaymentIntentUseCase', () => {
  let useCase: CreatePaymentIntentUseCase;
  let mockPaymentRepository: jest.Mocked<IPaymentRepository>;
  let mockStripeService: jest.Mocked<IStripeService>;

  beforeEach(() => {
    mockPaymentRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      findByAppointmentId: jest.fn(),
      findByStripePaymentIntentId: jest.fn(),
      update: jest.fn(),
      updateStatus: jest.fn(),
    } as any;

    mockStripeService = {
      createPaymentIntent: jest.fn(),
      confirmPaymentIntent: jest.fn(),
      refundPayment: jest.fn(),
      constructWebhookEvent: jest.fn(),
    } as any;

    useCase = new CreatePaymentIntentUseCase(mockPaymentRepository, mockStripeService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('execute', () => {
    const validPaymentData = {
      appointmentId: 'appt_123',
      patientId: 'patient_123',
      professionalId: 'prof_123',
      amount: 150.0,
      currency: Currency.USD,
      metadata: {
        notes: 'Initial consultation',
      },
    };

    it('should create payment intent successfully', async () => {
      // Arrange
      const stripeResult = {
        paymentIntentId: 'pi_123',
        clientSecret: 'pi_123_secret_456',
      };

      mockStripeService.createPaymentIntent.mockResolvedValue(stripeResult);
      mockPaymentRepository.create.mockImplementation(payment => Promise.resolve(payment));

      // Act
      const result = await useCase.execute(validPaymentData);

      // Assert
      expect(mockStripeService.createPaymentIntent).toHaveBeenCalledWith(
        150.0,
        Currency.USD,
        expect.objectContaining({
          appointmentId: 'appt_123',
          patientId: 'patient_123',
          professionalId: 'prof_123',
          notes: 'Initial consultation',
        })
      );

      expect(mockPaymentRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          appointmentId: 'appt_123',
          patientId: 'patient_123',
          professionalId: 'prof_123',
          amount: 150.0,
          currency: Currency.USD,
          status: PaymentStatus.PENDING,
          stripePaymentIntentId: 'pi_123',
          stripeClientSecret: 'pi_123_secret_456',
        })
      );

      expect(result).toMatchObject({
        appointmentId: 'appt_123',
        amount: 150.0,
        status: PaymentStatus.PENDING,
        stripePaymentIntentId: 'pi_123',
      });
    });

    it('should throw InvalidPaymentAmountError for negative amount', async () => {
      // Arrange
      const invalidData = {
        ...validPaymentData,
        amount: -50,
      };

      // Act & Assert
      await expect(useCase.execute(invalidData)).rejects.toThrow(InvalidPaymentAmountError);
      expect(mockStripeService.createPaymentIntent).not.toHaveBeenCalled();
      expect(mockPaymentRepository.create).not.toHaveBeenCalled();
    });

    it('should throw InvalidPaymentAmountError for zero amount', async () => {
      // Arrange
      const invalidData = {
        ...validPaymentData,
        amount: 0,
      };

      // Act & Assert
      await expect(useCase.execute(invalidData)).rejects.toThrow(InvalidPaymentAmountError);
    });

    it('should include metadata in Stripe payment intent', async () => {
      // Arrange
      const customMetadata = {
        custom_field: 'custom_value',
        another_field: 'another_value',
      };

      mockStripeService.createPaymentIntent.mockResolvedValue({
        paymentIntentId: 'pi_123',
        clientSecret: 'secret',
      });
      mockPaymentRepository.create.mockImplementation(p => Promise.resolve(p));

      // Act
      await useCase.execute({
        ...validPaymentData,
        metadata: customMetadata,
      });

      // Assert
      expect(mockStripeService.createPaymentIntent).toHaveBeenCalledWith(
        expect.any(Number),
        expect.any(String),
        expect.objectContaining(customMetadata)
      );
    });

    it('should handle missing metadata gracefully', async () => {
      // Arrange
      const dataWithoutMetadata = {
        appointmentId: 'appt_123',
        patientId: 'patient_123',
        professionalId: 'prof_123',
        amount: 100,
        currency: Currency.USD,
      };

      mockStripeService.createPaymentIntent.mockResolvedValue({
        paymentIntentId: 'pi_123',
        clientSecret: 'secret',
      });
      mockPaymentRepository.create.mockImplementation(p => Promise.resolve(p));

      // Act
      const result = await useCase.execute(dataWithoutMetadata);

      // Assert
      expect(result.metadata).toEqual({});
    });

    it('should generate unique payment ID', async () => {
      // Arrange
      mockStripeService.createPaymentIntent.mockResolvedValue({
        paymentIntentId: 'pi_123',
        clientSecret: 'secret',
      });

      const createdPayments: any[] = [];
      mockPaymentRepository.create.mockImplementation(payment => {
        createdPayments.push(payment);
        return Promise.resolve(payment);
      });

      // Act
      await useCase.execute(validPaymentData);
      await useCase.execute(validPaymentData);

      // Assert
      expect(createdPayments[0].id).not.toEqual(createdPayments[1].id);
    });

    it('should set createdAt and updatedAt timestamps', async () => {
      // Arrange
      mockStripeService.createPaymentIntent.mockResolvedValue({
        paymentIntentId: 'pi_123',
        clientSecret: 'secret',
      });
      mockPaymentRepository.create.mockImplementation(p => Promise.resolve(p));

      // Act
      const result = await useCase.execute(validPaymentData);

      // Assert
      expect(result.createdAt).toBeInstanceOf(Date);
      expect(result.updatedAt).toBeInstanceOf(Date);
    });
  });
});
