class Transaction {
  final int? id;
  final String userId;
  final String type; // 'income' | 'expense'
  final String category;
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    DateTime? date,
    DateTime? createdAt,
  }) : date = date ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId, 'type': type, 'category': category,
    'amount': amount, 'description': description,
    'date': date.toIso8601String(), 'created_at': createdAt.toIso8601String(),
  };

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
    id: m['id'] as int?,
    userId: m['user_id'] as String? ?? '',
    type: m['type'] as String? ?? 'expense',
    category: m['category'] as String? ?? 'other',
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    description: m['description'] as String?,
    date: m['date'] != null ? DateTime.parse(m['date'] as String) : DateTime.now(),
    createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
  );
}

class CategorySummary {
  final String category;
  final double total;
  final String icon;
  CategorySummary({required this.category, required this.total, required this.icon});
}
