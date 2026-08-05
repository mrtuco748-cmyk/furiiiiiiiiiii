class ClassType {
  final int? id;
  final String name;
  final int color;

  ClassType({this.id, required this.name, required this.color});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'color': color,
  };

  factory ClassType.fromMap(Map<String, dynamic> map) => ClassType(
    id: map['id'] as int?,
    name: map['name'] as String,
    color: map['color'] as int,
  );
}
