import { Twilio } from 'twilio';
import { ISMSService } from '../../application/ports/ISMSService';
import { SendSMSData } from '../../domain/entities/Notification';
import { NotificationSendError } from '../../domain/exceptions';

export class TwilioService implements ISMSService {
  private client: Twilio;

  constructor(
    private accountSid: string,
    private authToken: string,
    private phoneNumber: string
  ) {
    this.client = new Twilio(accountSid, authToken);
  }

  async sendSMS(data: SendSMSData): Promise<void> {
    try {
      await this.client.messages.create({
        from: this.phoneNumber,
        to: data.to,
        body: data.body,
      });
    } catch (error) {
      throw new NotificationSendError(`Twilio error: ${error}`);
    }
  }
}
