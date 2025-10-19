/// Appointment status enum
enum AppointmentStatus {
  pending('pending', 'Pendiente'),
  confirmed('confirmed', 'Confirmada'),
  inProgress('in_progress', 'En Progreso'),
  completed('completed', 'Completada'),
  cancelled('cancelled', 'Cancelada'),
  noShow('no_show', 'No Asistió');

  final String value;
  final String displayName;

  const AppointmentStatus(this.value, this.displayName);

  static AppointmentStatus fromValue(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppointmentStatus.pending,
    );
  }

  bool get isActive => this == confirmed || this == inProgress;
  bool get canCancel => this == pending || this == confirmed;
  bool get isFinished => this == completed || this == cancelled || this == noShow;
}
