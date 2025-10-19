/// Medical specialties supported by the platform
enum Specialty {
  generalMedicine('general_medicine', 'Medicina General'),
  physiotherapy('physiotherapy', 'Fisioterapia'),
  psychology('psychology', 'Psicología'),
  dentistry('dentistry', 'Odontología'),
  nutrition('nutrition', 'Nutrición'),
  pediatrics('pediatrics', 'Pediatría'),
  cardiology('cardiology', 'Cardiología'),
  dermatology('dermatology', 'Dermatología');

  final String value;
  final String displayName;

  const Specialty(this.value, this.displayName);

  static Specialty fromValue(String value) {
    return Specialty.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Specialty.generalMedicine,
    );
  }
}
