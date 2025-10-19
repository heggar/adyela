import { SendGridService } from '../../src/infrastructure/email/SendGridService';
import sgMail from '@sendgrid/mail';
import { NotificationSendError } from '../../src/domain/exceptions';

jest.mock('@sendgrid/mail');

describe('SendGridService', () => {
  let sendGridService: SendGridService;
  const mockApiKey = 'SG.test_key_123';
  const mockFromEmail = 'noreply@adyela.com';
  const mockFromName = 'Adyela Healthcare';

  beforeEach(() => {
    sendGridService = new SendGridService(mockApiKey, mockFromEmail, mockFromName);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('sendEmail', () => {
    it('should send email successfully', async () => {
      // Arrange
      const emailData = {
        to: 'patient@example.com',
        subject: 'Appointment Confirmation',
        html: '<p>Your appointment has been confirmed.</p>',
      };

      (sgMail.send as jest.Mock).mockResolvedValue([{}, {}]);

      // Act
      await sendGridService.sendEmail(emailData);

      // Assert
      expect(sgMail.setApiKey).toHaveBeenCalledWith(mockApiKey);
      expect(sgMail.send).toHaveBeenCalledWith({
        to: emailData.to,
        from: {
          email: mockFromEmail,
          name: mockFromName,
        },
        subject: emailData.subject,
        html: emailData.html,
        text: 'Your appointment has been confirmed.',
      });
    });

    it('should convert HTML to plain text when text not provided', async () => {
      // Arrange
      const emailData = {
        to: 'patient@example.com',
        subject: 'Test',
        html: '<h1>Hello</h1><p>World</p>',
      };

      (sgMail.send as jest.Mock).mockResolvedValue([{}, {}]);

      // Act
      await sendGridService.sendEmail(emailData);

      // Assert
      expect(sgMail.send).toHaveBeenCalledWith(
        expect.objectContaining({
          text: 'HelloWorld',
        })
      );
    });

    it('should use provided text when available', async () => {
      // Arrange
      const emailData = {
        to: 'patient@example.com',
        subject: 'Test',
        html: '<p>HTML content</p>',
        text: 'Plain text content',
      };

      (sgMail.send as jest.Mock).mockResolvedValue([{}, {}]);

      // Act
      await sendGridService.sendEmail(emailData);

      // Assert
      expect(sgMail.send).toHaveBeenCalledWith(
        expect.objectContaining({
          text: 'Plain text content',
        })
      );
    });

    it('should throw NotificationSendError on failure', async () => {
      // Arrange
      const emailData = {
        to: 'invalid-email',
        subject: 'Test',
        html: '<p>Test</p>',
      };

      (sgMail.send as jest.Mock).mockRejectedValue(new Error('Invalid email address'));

      // Act & Assert
      await expect(sendGridService.sendEmail(emailData)).rejects.toThrow(NotificationSendError);
    });
  });
});
