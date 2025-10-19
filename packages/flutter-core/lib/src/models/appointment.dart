import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../enums/appointment_status.dart';

part 'appointment.g.dart';

/// Appointment model
@JsonSerializable()
class Appointment extends Equatable {
  final String id;
  final String tenantId;
  final String patientId;
  final String professionalId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final String? cancellationReason;
  final String? meetingUrl;
  final double? fee;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Appointment({
    required this.id,
    required this.tenantId,
    required this.patientId,
    required this.professionalId,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.status = AppointmentStatus.pending,
    this.reason,
    this.notes,
    this.cancellationReason,
    this.meetingUrl,
    this.fee,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get end time of appointment
  DateTime get endTime =>
      scheduledAt.add(Duration(minutes: durationMinutes));

  /// Check if appointment is upcoming
  bool get isUpcoming =>
      status.isActive && scheduledAt.isAfter(DateTime.now());

  /// Check if appointment is past
  bool get isPast => scheduledAt.isBefore(DateTime.now());

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);

  @override
  List<Object?> get props => [
        id,
        tenantId,
        patientId,
        professionalId,
        scheduledAt,
        durationMinutes,
        status,
        reason,
        notes,
        cancellationReason,
        meetingUrl,
        fee,
        createdAt,
        updatedAt,
      ];

  Appointment copyWith({
    String? id,
    String? tenantId,
    String? patientId,
    String? professionalId,
    DateTime? scheduledAt,
    int? durationMinutes,
    AppointmentStatus? status,
    String? reason,
    String? notes,
    String? cancellationReason,
    String? meetingUrl,
    double? fee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      patientId: patientId ?? this.patientId,
      professionalId: professionalId ?? this.professionalId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      fee: fee ?? this.fee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
