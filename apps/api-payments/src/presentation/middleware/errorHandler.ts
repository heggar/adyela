import { Request, Response, NextFunction } from 'express';
import {
  PaymentNotFoundException,
  InvalidPaymentAmountError,
  PaymentProcessingError,
} from '../../domain/exceptions';

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public isOperational = true
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export const errorHandler = (err: Error, req: Request, res: Response, _next: NextFunction) => {
  // Handle known domain exceptions
  if (err instanceof PaymentNotFoundException) {
    return res.status(404).json({
      error: 'Not Found',
      message: err.message,
    });
  }

  if (err instanceof InvalidPaymentAmountError) {
    return res.status(400).json({
      error: 'Bad Request',
      message: err.message,
    });
  }

  if (err instanceof PaymentProcessingError) {
    return res.status(422).json({
      error: 'Payment Processing Error',
      message: err.message,
    });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: 'Application Error',
      message: err.message,
    });
  }

  // Handle validation errors (from Zod)
  if (err.name === 'ZodError') {
    return res.status(400).json({
      error: 'Validation Error',
      message: 'Invalid request data',
      details: err,
    });
  }

  // Log unexpected errors
  console.error('Unexpected error:', err);

  // Default error response
  return res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'An unexpected error occurred' : err.message,
  });
};

export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    void Promise.resolve(fn(req, res, next)).catch(next);
  };
};
