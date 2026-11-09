class UserDailyQuest {
  final int? id;
  final int userId;
  final String questDate; // 'YYYY-MM-DD'
  final bool loginClaimed;
  final int orderSpinsEarned; // Tối đa 2
  final String createdAt;

  static const int maxOrderSpinsPerDay = 2;

  UserDailyQuest({
    this.id,
    required this.userId,
    required this.questDate,
    this.loginClaimed = false,
    this.orderSpinsEarned = 0,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get canEarnFromOrder => orderSpinsEarned < maxOrderSpinsPerDay;
  bool get canClaimLogin => !loginClaimed;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'quest_date': questDate,
      'login_claimed': loginClaimed ? 1 : 0,
      'order_spins_earned': orderSpinsEarned,
      'created_at': createdAt,
    };
  }

  factory UserDailyQuest.fromMap(Map<String, dynamic> map) {
    return UserDailyQuest(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      questDate: map['quest_date'] as String,
      loginClaimed: (map['login_claimed'] as int?) == 1,
      orderSpinsEarned: (map['order_spins_earned'] as int?) ?? 0,
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  UserDailyQuest copyWith({
    int? id,
    int? userId,
    String? questDate,
    bool? loginClaimed,
    int? orderSpinsEarned,
    String? createdAt,
  }) {
    return UserDailyQuest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questDate: questDate ?? this.questDate,
      loginClaimed: loginClaimed ?? this.loginClaimed,
      orderSpinsEarned: orderSpinsEarned ?? this.orderSpinsEarned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

