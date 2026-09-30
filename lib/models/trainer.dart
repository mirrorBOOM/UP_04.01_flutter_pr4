class Trainer {
  final int id;
  final String fullName;
  final String specialization;
  final int experienceYears;
  final String category; 
  final DateTime? deletedAt;

  const Trainer({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.experienceYears,
    required this.category,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Trainer copyWith({
    String? fullName,
    String? specialization,
    int? experienceYears,
    String? category,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Trainer(
      id: id,
      fullName: fullName ?? this.fullName,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
      category: category ?? this.category,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}