import { Payment } from '../../domain/entities/Payment';

export interface IPaymentRepository {
  create(payment: Payment): Promise<Payment>;
  findById(id: string): Promise<Payment | null>;
  update(payment: Payment): Promise<Payment>;
  findByAppointmentId(appointmentId: string): Promise<Payment | null>;
}
