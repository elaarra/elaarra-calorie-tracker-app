class User {
  final String id;
  final String email;
  final String? displayName;
  final double height;
  final double weight;
  final int age;
  final String gender;
  final String goal;
  final int dailyCalorieTarget;
  final bool isPremium;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.displayName,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
    required this.goal,
    required this.dailyCalorieTarget,
    this.isPremium = false,
    required this.createdAt,
  });

  double calculateBMI() {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'goal': goal,
      'dailyCalorieTarget': dailyCalorieTarget,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'other',
      goal: json['goal'] ?? 'Maintain Weight',
      dailyCalorieTarget: json['dailyCalorieTarget'] ?? 2000,
      isPremium: json['isPremium'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
