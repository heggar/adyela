import * as admin from 'firebase-admin';
import { IPushService } from '../../application/ports/IPushService';
import { SendPushData } from '../../domain/entities/Notification';
import { NotificationSendError } from '../../domain/exceptions';

export class FirebaseService implements IPushService {
  constructor(projectId: string, clientEmail: string, privateKey: string) {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
    }
  }

  async sendPush(data: SendPushData): Promise<void> {
    try {
      await admin.messaging().send({
        token: data.token,
        notification: {
          title: data.title,
          body: data.body,
        },
        data: data.data || {},
      });
    } catch (error) {
      throw new NotificationSendError(`Firebase error: ${error}`);
    }
  }
}
