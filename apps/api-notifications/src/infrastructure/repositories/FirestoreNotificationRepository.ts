import { Firestore } from '@google-cloud/firestore';
import { Notification } from '../../domain/entities/Notification';
import { INotificationRepository } from '../../application/ports/INotificationRepository';
import { NotificationNotFoundException } from '../../domain/exceptions';
import { NotificationStatus } from '../../config';

export class FirestoreNotificationRepository implements INotificationRepository {
  private db: Firestore;
  private collectionName = 'notifications';

  constructor(firestore: Firestore) {
    this.db = firestore;
  }

  async create(notification: Notification): Promise<Notification> {
    const docRef = this.db.collection(this.collectionName).doc(notification.id);
    await docRef.set({
      ...notification,
      createdAt: notification.createdAt.toISOString(),
      updatedAt: notification.updatedAt.toISOString(),
      sentAt: notification.sentAt?.toISOString(),
      deliveredAt: notification.deliveredAt?.toISOString(),
    });
    return notification;
  }

  async findById(id: string): Promise<Notification> {
    const docRef = this.db.collection(this.collectionName).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new NotificationNotFoundException(id);
    }

    const data = doc.data()!;
    return this.mapToNotification(data);
  }

  async findByRecipient(recipient: string, limit: number = 50): Promise<Notification[]> {
    const snapshot = await this.db
      .collection(this.collectionName)
      .where('recipient', '==', recipient)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map(doc => this.mapToNotification(doc.data()));
  }

  async update(notification: Notification): Promise<Notification> {
    const docRef = this.db.collection(this.collectionName).doc(notification.id);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new NotificationNotFoundException(notification.id);
    }

    const updatedNotification = {
      ...notification,
      updatedAt: new Date(),
    };

    await docRef.update({
      ...updatedNotification,
      createdAt: updatedNotification.createdAt.toISOString(),
      updatedAt: updatedNotification.updatedAt.toISOString(),
      sentAt: updatedNotification.sentAt?.toISOString(),
      deliveredAt: updatedNotification.deliveredAt?.toISOString(),
    });

    return updatedNotification;
  }

  async updateStatus(
    id: string,
    status: NotificationStatus,
    failureReason?: string
  ): Promise<Notification> {
    const notification = await this.findById(id);
    notification.status = status;
    notification.updatedAt = new Date();

    if (status === NotificationStatus.SENT) {
      notification.sentAt = new Date();
    } else if (status === NotificationStatus.DELIVERED) {
      notification.deliveredAt = new Date();
    } else if (status === NotificationStatus.FAILED && failureReason) {
      notification.failureReason = failureReason;
    }

    return await this.update(notification);
  }

  private mapToNotification(data: any): Notification {
    return {
      ...data,
      createdAt: new Date(data.createdAt),
      updatedAt: new Date(data.updatedAt),
      sentAt: data.sentAt ? new Date(data.sentAt) : undefined,
      deliveredAt: data.deliveredAt ? new Date(data.deliveredAt) : undefined,
    } as Notification;
  }
}
