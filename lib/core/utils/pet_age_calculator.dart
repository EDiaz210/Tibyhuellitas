import 'dart:math';

class PetAgeCalculator {
  /// Calcula la edad humana de un perro basado en su edad en meses
  static String calculateHumanAge(int ageInMonths) {
    double humanAge;
    if (ageInMonths < 12) {
      humanAge = (ageInMonths / 12.0) * 15.0;
    } else {
      double ageInYears = ageInMonths / 12.0;
      humanAge = 16 * log(ageInYears) + 31;
    }
    return humanAge.toStringAsFixed(1);
  }

  /// Retorna el label de edad (ej: "11.3 años humanos")
  static String getAgeLabel(int ageInMonths) {
    if (ageInMonths < 12) {
      return '${(ageInMonths / 12.0).toStringAsFixed(1)} años';
    } else {
      return '${calculateHumanAge(ageInMonths)} años humanos';
    }
  }
}
