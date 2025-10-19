import { Notification, CreateNotificationData } from '../../domain/entities/Notification';
import { NotificationType, NotificationStatus } from '../../config';
import { INotificationRepository } from '../ports/INotificationRepository';
import { IEmailService } from '../ports/IEmailService';
import { ISMSService } from '../ports/ISMSService';
import { IPushService } from '../ports/IPushService';
import { InvalidRecipientError, NotificationSendError } from '../../domain/exceptions';

export class SendNotificationUseCase {
  constructor(
    private notificationRepository: INotificationRepository,
    private emailService: IEmailService,
    private smsService: ISMSService,
    private pushService: IPushService
  ) {}

  async execute(data: CreateNotificationData): Promise<Notification> {
    // Validate recipient
    if (!data.recipient || data.recipient.trim() === '') {
      throw new InvalidRecipientError(data.recipient);
    }

    // Create notification record
    const notification: Notification = {
      id: crypto.randomUUID(),
      type: data.type,
      template: data.template,
      recipient: data.recipient,
      subject: data.subject,
      body: this.renderTemplate(data.template, data.data || {}),
      data: data.data,
      status: NotificationStatus.PENDING,
      metadata: data.metadata || {},
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // Save to repository
    const createdNotification = await this.notificationRepository.create(notification);

    // Send notification based on type
    try {
      switch (data.type) {
        case NotificationType.EMAIL:
          await this.emailService.sendEmail({
            to: data.recipient,
            subject: data.subject || this.getDefaultSubject(data.template),
            html: notification.body,
          });
          break;

        case NotificationType.SMS:
          await this.smsService.sendSMS({
            to: data.recipient,
            body: notification.body,
          });
          break;

        case NotificationType.PUSH:
          await this.pushService.sendPush({
            token: data.recipient,
            title: data.subject || this.getDefaultSubject(data.template),
            body: notification.body,
            data: data.metadata,
          });
          break;

        default:
          throw new NotificationSendError(`Unsupported notification type: ${data.type}`);
      }

      // Update status to sent
      return await this.notificationRepository.updateStatus(
        createdNotification.id,
        NotificationStatus.SENT
      );
    } catch (error) {
      // Update status to failed
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      await this.notificationRepository.updateStatus(
        createdNotification.id,
        NotificationStatus.FAILED,
        errorMessage
      );
      throw new NotificationSendError(errorMessage);
    }
  }

  private renderTemplate(template: string, data: Record<string, unknown>): string {
    // Simple template rendering - replace {{variable}} with data values
    let rendered = this.getTemplateBody(template);

    for (const [key, value] of Object.entries(data)) {
      const placeholder = `{{${key}}}`;
      rendered = rendered.replace(new RegExp(placeholder, 'g'), String(value));
    }

    return rendered;
  }

  private getTemplateBody(template: string): string {
    // Template bodies - in production, these would come from a database or template engine
    const templates: Record<string, string> = {
      appointment_created: 'Your appointment has been created for {{date}} at {{time}}.',
      appointment_confirmed: 'Your appointment on {{date}} at {{time}} has been confirmed.',
      appointment_cancelled: 'Your appointment on {{date}} at {{time}} has been cancelled.',
      appointment_reminder: 'Reminder: You have an appointment tomorrow at {{time}}.',
      payment_received: 'We have received your payment of {{amount}}. Thank you!',
      payment_failed: 'Your payment of {{amount}} has failed. Please update your payment method.',
      professional_approved: 'Congratulations! Your professional account has been approved.',
      professional_rejected:
        'Unfortunately, your professional account application was not approved. Reason: {{reason}}',
      welcome_email: 'Welcome to Adyela, {{name}}! We are glad to have you.',
    };

    return templates[template] || 'Notification from Adyela Healthcare.';
  }

  private getDefaultSubject(template: string): string {
    const subjects: Record<string, string> = {
      appointment_created: 'Appointment Created',
      appointment_confirmed: 'Appointment Confirmed',
      appointment_cancelled: 'Appointment Cancelled',
      appointment_reminder: 'Appointment Reminder',
      payment_received: 'Payment Received',
      payment_failed: 'Payment Failed',
      professional_approved: 'Account Approved',
      professional_rejected: 'Account Application Status',
      welcome_email: 'Welcome to Adyela',
    };

    return subjects[template] || 'Notification';
  }
}
