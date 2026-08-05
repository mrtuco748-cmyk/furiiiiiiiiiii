class Task {
  final int? id;
  final String title;
  final int priority; // 0=baja, 1=normal, 2=urgente
  final int column;   // 0=urgente, 1=hoy, 2=semana, 3=completado
  final String? createdBy;
  final String? assignedTo;
  final bool shared;
  final DateTime? dueDate;
  final String? category;
  final int estimatedMinutes;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.priority = 1,
    this.column = 1,
    this.createdBy,
    this.assignedTo,
    this.shared = false,
    this.dueDate,
    this.category,
    this.estimatedMinutes = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'priority': priority,
    'column': column,
    'created_by': createdBy,
    'assigned_to': assignedTo,
    'shared': shared,
    'due_date': dueDate?.toIso8601String(),
    'category': category,
    'estimated_minutes': estimatedMinutes,
    'created_at': createdAt.toIso8601String(),
  };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
    id: m['id'] as int?,
    title: m['title'] as String? ?? '',
    priority: m['priority'] as int? ?? 1,
    column: m['column'] as int? ?? 1,
    createdBy: m['created_by'] as String?,
    assignedTo: m['assigned_to'] as String?,
    shared: m['shared'] as bool? ?? false,
    dueDate: m['due_date'] != null ? DateTime.parse(m['due_date'] as String) : null,
    category: m['category'] as String?,
    estimatedMinutes: m['estimated_minutes'] as int? ?? 0,
    createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
  );

  Task copyWith({int? column, int? priority, String? title, bool? shared, String? assignedTo, String? createdBy}) => Task(
    id: id, title: title ?? this.title, priority: priority ?? this.priority,
    column: column ?? this.column, createdBy: createdBy ?? this.createdBy, assignedTo: assignedTo ?? this.assignedTo,
    shared: shared ?? this.shared, dueDate: dueDate, category: category,
    estimatedMinutes: estimatedMinutes, createdAt: createdAt,
  );
}
