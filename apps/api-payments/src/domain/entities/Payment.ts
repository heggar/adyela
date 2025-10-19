import { PaymentStatus, Currency } from '../../config';

export interface Payment {
  id: string;
  appointmentId: string;
  patientId: string;
  professionalId: string;
  amount: number;
  currency: Currency;
  status: PaymentStatus;
  stripePaymentIntentId: string | null;
  stripeClientSecret: string | null;
  metadata: Record<string, string>;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreatePaymentData {
  appointmentId: string;
  patientId: string;
  professionalId: string;
  amount: number;
  currency: Currency;
  metadata?: Record<string, string>;
}
