import { Firestore } from '@google-cloud/firestore';
import { Payment } from '../../domain/entities/Payment';
import { IPaymentRepository } from '../../application/ports/IPaymentRepository';
import { PaymentNotFoundException } from '../../domain/exceptions';
import { PaymentStatus } from '../../config';

export class FirestorePaymentRepository implements IPaymentRepository {
  private db: Firestore;
  private collectionName = 'payments';

  constructor(firestore: Firestore) {
    this.db = firestore;
  }

  async create(payment: Payment): Promise<Payment> {
    const docRef = this.db.collection(this.collectionName).doc(payment.id);
    await docRef.set({
      ...payment,
      createdAt: payment.createdAt.toISOString(),
      updatedAt: payment.updatedAt.toISOString(),
    });
    return payment;
  }

  async findById(id: string): Promise<Payment> {
    const docRef = this.db.collection(this.collectionName).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new PaymentNotFoundException(id);
    }

    const data = doc.data()!;
    return {
      ...data,
      createdAt: new Date(data.createdAt),
      updatedAt: new Date(data.updatedAt),
    } as Payment;
  }

  async findByAppointmentId(appointmentId: string): Promise<Payment | null> {
    const snapshot = await this.db
      .collection(this.collectionName)
      .where('appointmentId', '==', appointmentId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return null;
    }

    const doc = snapshot.docs[0];
    const data = doc.data();
    return {
      ...data,
      createdAt: new Date(data.createdAt),
      updatedAt: new Date(data.updatedAt),
    } as Payment;
  }

  async findByStripePaymentIntentId(stripePaymentIntentId: string): Promise<Payment | null> {
    const snapshot = await this.db
      .collection(this.collectionName)
      .where('stripePaymentIntentId', '==', stripePaymentIntentId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return null;
    }

    const doc = snapshot.docs[0];
    const data = doc.data();
    return {
      ...data,
      createdAt: new Date(data.createdAt),
      updatedAt: new Date(data.updatedAt),
    } as Payment;
  }

  async update(payment: Payment): Promise<Payment> {
    const docRef = this.db.collection(this.collectionName).doc(payment.id);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new PaymentNotFoundException(payment.id);
    }

    const updatedPayment = {
      ...payment,
      updatedAt: new Date(),
    };

    await docRef.update({
      ...updatedPayment,
      createdAt: updatedPayment.createdAt.toISOString(),
      updatedAt: updatedPayment.updatedAt.toISOString(),
    });

    return updatedPayment;
  }

  async updateStatus(id: string, status: PaymentStatus): Promise<Payment> {
    const payment = await this.findById(id);
    payment.status = status;
    payment.updatedAt = new Date();
    return await this.update(payment);
  }
}
