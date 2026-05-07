class Meal {
  final String id;
  final String userId;
  final String name;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String mealType;
  final String? imageUrl;
  final String? photoSource;
  final DateTime loggedAt;
  final bool isFavorite;

  Meal({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.mealType,
    this.imageUrl,
    this.photoSource = 'manual',
    required this.loggedAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'mealType': mealType,
      'imageUrl': imageUrl,
      'photoSource': photoSource,
      'loggedAt': loggedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      calories: json['calories'] ?? 0,
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      mealType: json['mealType'] ?? 'Snack',
      imageUrl: json['imageUrl'],
      photoSource: json['photoSource'] ?? 'manual',
      loggedAt: DateTime.parse(json['loggedAt'] ?? DateTime.now().toIso8601String()),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
