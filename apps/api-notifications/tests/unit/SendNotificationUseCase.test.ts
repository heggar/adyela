import { SendNotificationUseCase } from '../../src/application/use-cases/SendNotification';
import { INotificationRepository } from '../../src/application/ports/INotificationRepository';
import { IEmailService } from '../../src/application/ports/IEmailService';
import { ISMSService } from '../../src/application/ports/ISMSService';
import { IPushService } from '../../src/application/ports/IPushService';
import { NotificationType, NotificationStatus, NotificationTemplate } from '../../src/config';
import { InvalidRecipientError, NotificationSendError } from '../../src/domain/exceptions';

describe('SendNotificationUseCase', () => {
  let useCase: SendNotificationUseCase;
  let mockNotificationRepository: jest.Mocked<INotificationRepository>;
  let mockEmailService: jest.Mocked<IEmailService>;
  let mockSMSService: jest.Mocked<ISMSService>;
  let mockPushService: jest.Mocked<IPushService>;

  beforeEach(() => {
    mockNotificationRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      findByRecipient: jest.fn(),
      update: jest.fn(),
      updateStatus: jest.fn(),
    } as any;

    mockEmailService = {
      sendEmail: jest.fn(),
    } as any;

    mockSMSService = {
      sendSMS: jest.fn(),
    } as any;

    mockPushService = {
      sendPush: jest.fn(),
    } as any;

    useCase = new SendNotificationUseCase(
      mockNotificationRepository,
      mockEmailService,
      mockSMSService,
      mockPushService
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('execute', () => {
    const validEmailData = {
      type: NotificationType.EMAIL,
      template: NotificationTemplate.APPOINTMENT_CONFIRMED,
      recipient: 'patient@example.com',
      subject: 'Appointment Confirmed',
      data: {
        date: '2025-01-20',
        time: '10:00 AM',
      },
    };

    it('should send email notification successfully', async () => {
      // Arrange
      mockNotificationRepository.create.mockImplementation(notification =>
        Promise.resolve(notification)
      );
      mockNotificationRepository.updateStatus.mockImplementation((id, status) =>
        Promise.resolve({
          id,
          status,
          type: NotificationType.EMAIL,
          template: NotificationTemplate.APPOINTMENT_CONFIRMED,
          recipient: 'patient@example.com',
          body: 'Your appointment on 2025-01-20 at 10:00 AM has been confirmed.',
          metadata: {},
          createdAt: new Date(),
          updatedAt: new Date(),
        } as any)
      );
      mockEmailService.sendEmail.mockResolvedValue();

      // Act
      const result = await useCase.execute(validEmailData);

      // Assert
      expect(mockNotificationRepository.create).toHaveBeenCalled();
      expect(mockEmailService.sendEmail).toHaveBeenCalledWith({
        to: 'patient@example.com',
        subject: 'Appointment Confirmed',
        html: 'Your appointment on 2025-01-20 at 10:00 AM has been confirmed.',
      });
      expect(mockNotificationRepository.updateStatus).toHaveBeenCalledWith(
        expect.any(String),
        NotificationStatus.SENT
      );
      expect(result.status).toBe(NotificationStatus.SENT);
    });

    it('should send SMS notification successfully', async () => {
      // Arrange
      const smsData = {
        type: NotificationType.SMS,
        template: NotificationTemplate.APPOINTMENT_REMINDER,
        recipient: '+1234567890',
        data: { time: '10:00 AM' },
      };

      mockNotificationRepository.create.mockImplementation(notification =>
        Promise.resolve(notification)
      );
      mockNotificationRepository.updateStatus.mockImplementation((id, status) =>
        Promise.resolve({ id, status } as any)
      );
      mockSMSService.sendSMS.mockResolvedValue();

      // Act
      await useCase.execute(smsData);

      // Assert
      expect(mockSMSService.sendSMS).toHaveBeenCalledWith({
        to: '+1234567890',
        body: expect.stringContaining('10:00 AM'),
      });
      expect(mockNotificationRepository.updateStatus).toHaveBeenCalledWith(
        expect.any(String),
        NotificationStatus.SENT
      );
    });

    it('should send push notification successfully', async () => {
      // Arrange
      const pushData = {
        type: NotificationType.PUSH,
        template: NotificationTemplate.PAYMENT_RECEIVED,
        recipient: 'device_token_123',
        data: { amount: '150.00' },
        metadata: { userId: 'user_123' },
      };

      mockNotificationRepository.create.mockImplementation(notification =>
        Promise.resolve(notification)
      );
      mockNotificationRepository.updateStatus.mockImplementation((id, status) =>
        Promise.resolve({ id, status } as any)
      );
      mockPushService.sendPush.mockResolvedValue();

      // Act
      await useCase.execute(pushData);

      // Assert
      expect(mockPushService.sendPush).toHaveBeenCalledWith({
        token: 'device_token_123',
        title: 'Payment Received',
        body: expect.stringContaining('150.00'),
        data: pushData.metadata,
      });
    });

    it('should throw InvalidRecipientError for empty recipient', async () => {
      // Arrange
      const invalidData = {
        ...validEmailData,
        recipient: '',
      };

      // Act & Assert
      await expect(useCase.execute(invalidData)).rejects.toThrow(InvalidRecipientError);
      expect(mockNotificationRepository.create).not.toHaveBeenCalled();
    });

    it('should update status to FAILED when sending fails', async () => {
      // Arrange
      mockNotificationRepository.create.mockImplementation(notification =>
        Promise.resolve(notification)
      );
      mockNotificationRepository.updateStatus.mockImplementation((id, status) =>
        Promise.resolve({ id, status } as any)
      );
      mockEmailService.sendEmail.mockRejectedValue(new Error('Email service error'));

      // Act & Assert
      await expect(useCase.execute(validEmailData)).rejects.toThrow(NotificationSendError);
      expect(mockNotificationRepository.updateStatus).toHaveBeenCalledWith(
        expect.any(String),
        NotificationStatus.FAILED,
        expect.any(String)
      );
    });

    it('should render template with data correctly', async () => {
      // Arrange
      mockNotificationRepository.create.mockImplementation(notification =>
        Promise.resolve(notification)
      );
      mockNotificationRepository.updateStatus.mockImplementation((id, status) =>
        Promise.resolve({ id, status } as any)
      );
      mockEmailService.sendEmail.mockResolvedValue();

      // Act
      await useCase.execute(validEmailData);

      // Assert
      const createCall = mockNotificationRepository.create.mock.calls[0][0];
      expect(createCall.body).toContain('2025-01-20');
      expect(createCall.body).toContain('10:00 AM');
    });
  });
});
