import { NotificationType, NotificationStatus, NotificationTemplate } from '../../config';

export interface Notification {
  id: string;
  type: NotificationType;
  template: NotificationTemplate;
  recipient: string; // email, phone number, or device token
  subject?: string; // for emails
  body: string;
  data?: Record<string, unknown>; // template variables
  status: NotificationStatus;
  sentAt?: Date;
  deliveredAt?: Date;
  failureReason?: string;
  metadata: Record<string, string>;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateNotificationData {
  type: NotificationType;
  template: NotificationTemplate;
  recipient: string;
  subject?: string;
  data?: Record<string, unknown>;
  metadata?: Record<string, string>;
}

export interface SendEmailData {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export interface SendSMSData {
  to: string;
  body: string;
}

export interface SendPushData {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}
