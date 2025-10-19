import sgMail from '@sendgrid/mail';
import { IEmailService } from '../../application/ports/IEmailService';
import { SendEmailData } from '../../domain/entities/Notification';
import { NotificationSendError } from '../../domain/exceptions';

export class SendGridService implements IEmailService {
  constructor(
    private apiKey: string,
    private fromEmail: string,
    private fromName: string
  ) {
    sgMail.setApiKey(this.apiKey);
  }

  async sendEmail(data: SendEmailData): Promise<void> {
    try {
      await sgMail.send({
        to: data.to,
        from: {
          email: this.fromEmail,
          name: this.fromName,
        },
        subject: data.subject,
        html: data.html,
        text: data.text || this.htmlToText(data.html),
      });
    } catch (error) {
      throw new NotificationSendError(`SendGrid error: ${error}`);
    }
  }

  private htmlToText(html: string): string {
    // Simple HTML to text conversion - strip tags
    return html.replace(/<[^>]*>/g, '');
  }
}
