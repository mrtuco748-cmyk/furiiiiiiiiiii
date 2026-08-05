class MenuPlan {
  final int? id;
  final String name;
  final DateTime date;
  final String mealType;
  final int? recipeId;
  final String? recipeName;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuPlan({
    this.id,
    required this.name,
    required this.date,
    required this.mealType,
    this.recipeId,
    this.recipeName,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'mealType': mealType,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MenuPlan.fromMap(Map<String, dynamic> map) {
    return MenuPlan(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      mealType: map['mealType'] as String,
      recipeId: map['recipeId'] as int?,
      recipeName: map['recipeName'] as String?,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  MenuPlan copyWith({
    int? id,
    String? name,
    DateTime? date,
    String? mealType,
    int? recipeId,
    String? recipeName,
    String? notes,
    DateTime? updatedAt,
  }) {
    return MenuPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
