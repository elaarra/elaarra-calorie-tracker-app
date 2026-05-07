class Goal {
  final String id;
  final String userId;
  final String goalType;
  final double targetWeight;
  final double startingWeight;
  final DateTime targetDate;
  final DateTime createdAt;
  final bool isActive;

  Goal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetWeight,
    required this.startingWeight,
    required this.targetDate,
    required this.createdAt,
    this.isActive = true,
  });

  double getTargetChange() {
    return (targetWeight - startingWeight).abs();
  }

  int getDaysRemaining() {
    final today = DateTime.now();
    return targetDate.difference(today).inDays;
  }

  double getProgressPercentage(double currentWeight) {
    final totalChange = getTargetChange();
    if (totalChange == 0) return 100;
    final actualChange = (startingWeight - currentWeight).abs();
    return (actualChange / totalChange) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'goalType': goalType,
      'targetWeight': targetWeight,
      'startingWeight': startingWeight,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      goalType: json['goalType'] ?? 'Maintain Weight',
      targetWeight: (json['targetWeight'] ?? 0).toDouble(),
      startingWeight: (json['startingWeight'] ?? 0).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
    );
  }
}
