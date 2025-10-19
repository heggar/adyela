import { Notification } from '../../domain/entities/Notification';
import { NotificationStatus } from '../../config';

export interface INotificationRepository {
  create(notification: Notification): Promise<Notification>;
  findById(id: string): Promise<Notification>;
  findByRecipient(recipient: string, limit?: number): Promise<Notification[]>;
  update(notification: Notification): Promise<Notification>;
  updateStatus(
    id: string,
    status: NotificationStatus,
    failureReason?: string
  ): Promise<Notification>;
}
