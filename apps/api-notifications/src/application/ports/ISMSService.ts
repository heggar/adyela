import { SendSMSData } from '../../domain/entities/Notification';

export interface ISMSService {
  sendSMS(data: SendSMSData): Promise<void>;
}
