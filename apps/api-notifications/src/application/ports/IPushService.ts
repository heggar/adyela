import { SendPushData } from '../../domain/entities/Notification';

export interface IPushService {
  sendPush(data: SendPushData): Promise<void>;
}
