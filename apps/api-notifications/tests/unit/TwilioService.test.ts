import { TwilioService } from '../../src/infrastructure/sms/TwilioService';
import { Twilio } from 'twilio';
import { NotificationSendError } from '../../src/domain/exceptions';

jest.mock('twilio');

describe('TwilioService', () => {
  let twilioService: TwilioService;
  let mockClient: any;

  const mockAccountSid = 'AC123456789';
  const mockAuthToken = 'auth_token_123';
  const mockPhoneNumber = '+1234567890';

  beforeEach(() => {
    mockClient = {
      messages: {
        create: jest.fn(),
      },
    };

    (Twilio as jest.MockedClass<typeof Twilio>).mockImplementation(() => mockClient);

    twilioService = new TwilioService(mockAccountSid, mockAuthToken, mockPhoneNumber);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('sendSMS', () => {
    it('should send SMS successfully', async () => {
      // Arrange
      const smsData = {
        to: '+1987654321',
        body: 'Your appointment has been confirmed.',
      };

      mockClient.messages.create.mockResolvedValue({ sid: 'SM123' });

      // Act
      await twilioService.sendSMS(smsData);

      // Assert
      expect(mockClient.messages.create).toHaveBeenCalledWith({
        from: mockPhoneNumber,
        to: smsData.to,
        body: smsData.body,
      });
    });

    it('should throw NotificationSendError on failure', async () => {
      // Arrange
      const smsData = {
        to: 'invalid-phone',
        body: 'Test message',
      };

      mockClient.messages.create.mockRejectedValue(new Error('Invalid phone number'));

      // Act & Assert
      await expect(twilioService.sendSMS(smsData)).rejects.toThrow(NotificationSendError);
    });
  });
});
