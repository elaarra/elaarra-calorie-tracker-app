class AppConstants {
  static const List<String> healthGoals = [
    'Lose Weight',
    'Gain Muscle',
    'Maintain Weight',
    'Get Healthier',
  ];

  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  static const double minHeight = 120;
  static const double maxHeight = 250;
  static const double minWeight = 30;
  static const double maxWeight = 300;
  static const int minAge = 13;
  static const int maxAge = 120;
}

class ErrorMessages {
  static const String heightError = 'Please enter a valid height (120-250 cm)';
  static const String weightError = 'Please enter a valid weight (30-300 kg)';
  static const String ageError = 'Please enter a valid age (13-120)';
}
