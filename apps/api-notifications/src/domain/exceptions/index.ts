export class NotificationNotFoundException extends Error {
  constructor(id: string) {
    super(`Notification with ID ${id} not found`);
    this.name = 'NotificationNotFoundException';
  }
}

export class InvalidRecipientError extends Error {
  constructor(recipient: string) {
    super(`Invalid recipient: ${recipient}`);
    this.name = 'InvalidRecipientError';
  }
}

export class NotificationSendError extends Error {
  constructor(message: string) {
    super(`Failed to send notification: ${message}`);
    this.name = 'NotificationSendError';
  }
}

export class TemplateNotFoundError extends Error {
  constructor(template: string) {
    super(`Template ${template} not found`);
    this.name = 'TemplateNotFoundError';
  }
}

export class InvalidTemplateDataError extends Error {
  constructor(message: string) {
    super(`Invalid template data: ${message}`);
    this.name = 'InvalidTemplateDataError';
  }
}
