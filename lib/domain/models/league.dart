class League {
  League({
    required this.id,
    required this.name,
    required this.country,
    List<String> clubIds = const [],
    List<double> positionPrizeMoney = const [],
  })  : clubIds = List.unmodifiable(clubIds),
        positionPrizeMoney = List.unmodifiable(positionPrizeMoney);

  final String id;
  final String name;
  final String country;
  final List<String> clubIds;
  final List<double> positionPrizeMoney;

  double prizeMoneyForPosition(int position) {
    final index = position - 1;
    if (index < 0 || index >= positionPrizeMoney.length) return 0;
    return positionPrizeMoney[index];
  }

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'clubIds': clubIds,
        'positionPrizeMoney': positionPrizeMoney,
      };

  factory League.fromJson(Map<String, Object?> json) {
    return League(
      id: json['id']! as String,
      name: json['name']! as String,
      country: json['country']! as String,
      clubIds: (json['clubIds']! as List<Object?>).cast<String>(),
      positionPrizeMoney:
          ((json['positionPrizeMoney'] as List<Object?>?) ?? const [])
              .map((value) => (value! as num).toDouble())
              .toList(),
    );
  }
}
