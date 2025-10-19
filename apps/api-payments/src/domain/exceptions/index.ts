export class DomainException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'DomainException';
  }
}

export class PaymentNotFoundException extends DomainException {
  constructor(paymentId: string) {
    super(`Payment ${paymentId} not found`);
    this.name = 'PaymentNotFoundException';
  }
}

export class InvalidPaymentAmountError extends DomainException {
  constructor(amount: number) {
    super(`Invalid payment amount: ${amount}`);
    this.name = 'InvalidPaymentAmountError';
  }
}

export class PaymentProcessingError extends DomainException {
  constructor(message: string) {
    super(message);
    this.name = 'PaymentProcessingError';
  }
}
