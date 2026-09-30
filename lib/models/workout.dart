class Workout {
  final int id;
  final String title;
  final String code; 
  final int durationMinutes; 
  final int caloriesBurned; 
  final int intensity; 
  final int hallId; 
  final int trainerId; 
  final int capacityTotal; 
  final int capacityAvailable; 
  final DateTime? deletedAt; 

  const Workout({
    required this.id,
    required this.title,
    required this.code,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.intensity,
    required this.hallId,
    required this.trainerId,
    required this.capacityTotal,
    required this.capacityAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Workout copyWith({
    String? title,
    String? code,
    int? durationMinutes,
    int? caloriesBurned,
    int? intensity,
    int? hallId,
    int? trainerId,
    int? capacityTotal,
    int? capacityAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Workout(
      id: id,
      title: title ?? this.title,
      code: code ?? this.code,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      intensity: intensity ?? this.intensity,
      hallId: hallId ?? this.hallId,
      trainerId: trainerId ?? this.trainerId,
      capacityTotal: capacityTotal ?? this.capacityTotal,
      capacityAvailable: capacityAvailable ?? this.capacityAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}