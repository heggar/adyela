import { SendEmailData } from '../../domain/entities/Notification';

export interface IEmailService {
  sendEmail(data: SendEmailData): Promise<void>;
}
