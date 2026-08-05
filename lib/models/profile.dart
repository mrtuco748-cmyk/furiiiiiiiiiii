class Profile {
  final String id;
  final String name;
  final String? partnerId;
  final String? coupleCode;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.name,
    this.partnerId,
    this.coupleCode,
    this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        name: m['name'] as String,
        partnerId: m['partner_id'] as String?,
        coupleCode: m['couple_code'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'partner_id': partnerId,
        'couple_code': coupleCode,
      };
}
