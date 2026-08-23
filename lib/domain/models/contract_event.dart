enum ContractEventType { signed, renewed, expired }

class ContractEvent {
  const ContractEvent({
    required this.id,
    required this.type,
    required this.playerId,
    required this.clubId,
    required this.season,
    required this.week,
    required this.weeklySalary,
    this.previousSalary,
    this.endSeason,
  });

  final String id;
  final ContractEventType type;
  final String playerId;
  final String clubId;
  final int season;
  final int week;
  final double weeklySalary;
  final double? previousSalary;
  final int? endSeason;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'playerId': playerId,
        'clubId': clubId,
        'season': season,
        'week': week,
        'weeklySalary': weeklySalary,
        'previousSalary': previousSalary,
        'endSeason': endSeason,
      };

  factory ContractEvent.fromJson(Map<String, Object?> json) => ContractEvent(
        id: json['id']! as String,
        type: ContractEventType.values.byName(json['type']! as String),
        playerId: json['playerId']! as String,
        clubId: json['clubId']! as String,
        season: json['season']! as int,
        week: json['week']! as int,
        weeklySalary: (json['weeklySalary']! as num).toDouble(),
        previousSalary: (json['previousSalary'] as num?)?.toDouble(),
        endSeason: json['endSeason'] as int?,
      );
}
