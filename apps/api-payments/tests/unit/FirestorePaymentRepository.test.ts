import { FirestorePaymentRepository } from '../../src/infrastructure/repositories/FirestorePaymentRepository';
import { Payment } from '../../src/domain/entities/Payment';
import { PaymentStatus, Currency } from '../../src/config';
import { PaymentNotFoundException } from '../../src/domain/exceptions';
import { Firestore } from '@google-cloud/firestore';

describe('FirestorePaymentRepository', () => {
  let repository: FirestorePaymentRepository;
  let mockFirestore: jest.Mocked<Firestore>;
  let mockCollection: any;
  let mockDocRef: any;

  beforeEach(() => {
    mockDocRef = {
      set: jest.fn().mockResolvedValue(undefined),
      get: jest.fn(),
      update: jest.fn().mockResolvedValue(undefined),
    };

    mockCollection = {
      doc: jest.fn().mockReturnValue(mockDocRef),
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn(),
    };

    mockFirestore = {
      collection: jest.fn().mockReturnValue(mockCollection),
    } as any;

    repository = new FirestorePaymentRepository(mockFirestore);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  const samplePayment: Payment = {
    id: 'payment_123',
    appointmentId: 'appt_123',
    patientId: 'patient_123',
    professionalId: 'prof_123',
    amount: 100.0,
    currency: Currency.USD,
    status: PaymentStatus.PENDING,
    stripePaymentIntentId: 'pi_123',
    stripeClientSecret: 'pi_123_secret',
    metadata: { notes: 'Test payment' },
    createdAt: new Date('2025-01-01T10:00:00Z'),
    updatedAt: new Date('2025-01-01T10:00:00Z'),
  };

  describe('create', () => {
    it('should create payment successfully', async () => {
      // Act
      const result = await repository.create(samplePayment);

      // Assert
      expect(mockFirestore.collection).toHaveBeenCalledWith('payments');
      expect(mockCollection.doc).toHaveBeenCalledWith('payment_123');
      expect(mockDocRef.set).toHaveBeenCalledWith({
        ...samplePayment,
        createdAt: '2025-01-01T10:00:00.000Z',
        updatedAt: '2025-01-01T10:00:00.000Z',
      });
      expect(result).toEqual(samplePayment);
    });

    it('should convert dates to ISO strings', async () => {
      // Act
      await repository.create(samplePayment);

      // Assert
      expect(mockDocRef.set).toHaveBeenCalledWith(
        expect.objectContaining({
          createdAt: expect.stringContaining('2025-01-01'),
          updatedAt: expect.stringContaining('2025-01-01'),
        })
      );
    });
  });

  describe('findById', () => {
    it('should find payment by ID successfully', async () => {
      // Arrange
      mockDocRef.get.mockResolvedValue({
        exists: true,
        data: () => ({
          ...samplePayment,
          createdAt: '2025-01-01T10:00:00.000Z',
          updatedAt: '2025-01-01T10:00:00.000Z',
        }),
      });

      // Act
      const result = await repository.findById('payment_123');

      // Assert
      expect(mockCollection.doc).toHaveBeenCalledWith('payment_123');
      expect(result.id).toBe('payment_123');
      expect(result.createdAt).toBeInstanceOf(Date);
      expect(result.updatedAt).toBeInstanceOf(Date);
    });

    it('should throw PaymentNotFoundException when payment not found', async () => {
      // Arrange
      mockDocRef.get.mockResolvedValue({
        exists: false,
      });

      // Act & Assert
      await expect(repository.findById('nonexistent_123')).rejects.toThrow(
        PaymentNotFoundException
      );
    });
  });

  describe('findByAppointmentId', () => {
    it('should find payment by appointment ID', async () => {
      // Arrange
      const mockSnapshot = {
        empty: false,
        docs: [
          {
            data: () => ({
              ...samplePayment,
              createdAt: '2025-01-01T10:00:00.000Z',
              updatedAt: '2025-01-01T10:00:00.000Z',
            }),
          },
        ],
      };

      mockCollection.get.mockResolvedValue(mockSnapshot);

      // Act
      const result = await repository.findByAppointmentId('appt_123');

      // Assert
      expect(mockCollection.where).toHaveBeenCalledWith('appointmentId', '==', 'appt_123');
      expect(mockCollection.limit).toHaveBeenCalledWith(1);
      expect(result).not.toBeNull();
      expect(result?.appointmentId).toBe('appt_123');
    });

    it('should return null when no payment found', async () => {
      // Arrange
      mockCollection.get.mockResolvedValue({
        empty: true,
        docs: [],
      });

      // Act
      const result = await repository.findByAppointmentId('nonexistent');

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('findByStripePaymentIntentId', () => {
    it('should find payment by Stripe payment intent ID', async () => {
      // Arrange
      const mockSnapshot = {
        empty: false,
        docs: [
          {
            data: () => ({
              ...samplePayment,
              createdAt: '2025-01-01T10:00:00.000Z',
              updatedAt: '2025-01-01T10:00:00.000Z',
            }),
          },
        ],
      };

      mockCollection.get.mockResolvedValue(mockSnapshot);

      // Act
      const result = await repository.findByStripePaymentIntentId('pi_123');

      // Assert
      expect(mockCollection.where).toHaveBeenCalledWith('stripePaymentIntentId', '==', 'pi_123');
      expect(result).not.toBeNull();
      expect(result?.stripePaymentIntentId).toBe('pi_123');
    });

    it('should return null when no payment found', async () => {
      // Arrange
      mockCollection.get.mockResolvedValue({
        empty: true,
        docs: [],
      });

      // Act
      const result = await repository.findByStripePaymentIntentId('nonexistent');

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('update', () => {
    it('should update payment successfully', async () => {
      // Arrange
      mockDocRef.get.mockResolvedValue({
        exists: true,
      });

      const updatedPayment = {
        ...samplePayment,
        status: PaymentStatus.SUCCEEDED,
      };

      // Act
      const result = await repository.update(updatedPayment);

      // Assert
      expect(mockDocRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: PaymentStatus.SUCCEEDED,
        })
      );
      expect(result.status).toBe(PaymentStatus.SUCCEEDED);
      expect(result.updatedAt).toBeInstanceOf(Date);
    });

    it('should throw PaymentNotFoundException when payment not found', async () => {
      // Arrange
      mockDocRef.get.mockResolvedValue({
        exists: false,
      });

      // Act & Assert
      await expect(repository.update(samplePayment)).rejects.toThrow(PaymentNotFoundException);
    });

    it('should update the updatedAt timestamp', async () => {
      // Arrange
      mockDocRef.get.mockResolvedValue({
        exists: true,
      });

      const oldDate = new Date('2025-01-01T10:00:00Z');
      const paymentToUpdate = { ...samplePayment, updatedAt: oldDate };

      // Act
      const result = await repository.update(paymentToUpdate);

      // Assert
      expect(result.updatedAt.getTime()).toBeGreaterThan(oldDate.getTime());
    });
  });

  describe('updateStatus', () => {
    it('should update payment status successfully', async () => {
      // Arrange
      mockDocRef.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          ...samplePayment,
          createdAt: '2025-01-01T10:00:00.000Z',
          updatedAt: '2025-01-01T10:00:00.000Z',
        }),
      });

      mockDocRef.get.mockResolvedValueOnce({
        exists: true,
      });

      // Act
      const result = await repository.updateStatus('payment_123', PaymentStatus.SUCCEEDED);

      // Assert
      expect(result.status).toBe(PaymentStatus.SUCCEEDED);
      expect(mockDocRef.update).toHaveBeenCalled();
    });

    it('should throw PaymentNotFoundException when payment not found', async () => {
      // Arrange
      mockDocRef.get.mockResolvedValue({
        exists: false,
      });

      // Act & Assert
      await expect(repository.updateStatus('nonexistent', PaymentStatus.SUCCEEDED)).rejects.toThrow(
        PaymentNotFoundException
      );
    });
  });
});
