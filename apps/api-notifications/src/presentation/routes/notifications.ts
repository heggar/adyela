import { Router, Response } from 'express';
import { z } from 'zod';
import { SendNotificationUseCase } from '../../application/use-cases/SendNotification';
import { INotificationRepository } from '../../application/ports/INotificationRepository';
import { IEmailService } from '../../application/ports/IEmailService';
import { ISMSService } from '../../application/ports/ISMSService';
import { IPushService } from '../../application/ports/IPushService';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { asyncHandler } from '../middleware/errorHandler';
import { NotificationType, NotificationTemplate } from '../../config';

// Request validation schemas
const SendNotificationSchema = z.object({
  type: z.nativeEnum(NotificationType),
  template: z.nativeEnum(NotificationTemplate),
  recipient: z.string().min(1),
  subject: z.string().optional(),
  data: z.record(z.unknown()).optional(),
  metadata: z.record(z.string()).optional(),
});

export const createNotificationRoutes = (
  notificationRepository: INotificationRepository,
  emailService: IEmailService,
  smsService: ISMSService,
  pushService: IPushService
): Router => {
  const router = Router();

  // Send notification
  router.post(
    '/send',
    authenticateToken,
    asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
      const validatedData = SendNotificationSchema.parse(req.body);

      const useCase = new SendNotificationUseCase(
        notificationRepository,
        emailService,
        smsService,
        pushService
      );

      const notification = await useCase.execute(validatedData);

      return res.status(201).json({
        success: true,
        data: {
          id: notification.id,
          type: notification.type,
          template: notification.template,
          recipient: notification.recipient,
          status: notification.status,
          sentAt: notification.sentAt,
        },
      });
    })
  );

  // Get notification by ID
  router.get(
    '/:id',
    authenticateToken,
    asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
      const { id } = req.params;
      const notification = await notificationRepository.findById(id);

      return res.json({
        success: true,
        data: {
          id: notification.id,
          type: notification.type,
          template: notification.template,
          recipient: notification.recipient,
          subject: notification.subject,
          status: notification.status,
          sentAt: notification.sentAt,
          deliveredAt: notification.deliveredAt,
          failureReason: notification.failureReason,
          createdAt: notification.createdAt,
          updatedAt: notification.updatedAt,
        },
      });
    })
  );

  // Get notifications by recipient
  router.get(
    '/recipient/:recipient',
    authenticateToken,
    asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
      const { recipient } = req.params;
      const limit = parseInt(req.query.limit as string) || 50;

      const notifications = await notificationRepository.findByRecipient(recipient, limit);

      return res.json({
        success: true,
        data: notifications.map(n => ({
          id: n.id,
          type: n.type,
          template: n.template,
          status: n.status,
          sentAt: n.sentAt,
          createdAt: n.createdAt,
        })),
      });
    })
  );

  return router;
};
