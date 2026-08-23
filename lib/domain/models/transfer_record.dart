class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.playerId,
    required this.fromClubId,
    required this.toClubId,
    required this.fee,
    required this.season,
    required this.week,
  });

  final String id;
  final String playerId;
  final String fromClubId;
  final String toClubId;
  final double fee;
  final int season;
  final int week;

  Map<String, Object> toJson() => {
        'id': id,
        'playerId': playerId,
        'fromClubId': fromClubId,
        'toClubId': toClubId,
        'fee': fee,
        'season': season,
        'week': week,
      };

  factory TransferRecord.fromJson(Map<String, Object?> json) => TransferRecord(
        id: json['id']! as String,
        playerId: json['playerId']! as String,
        fromClubId: json['fromClubId']! as String,
        toClubId: json['toClubId']! as String,
        fee: (json['fee']! as num).toDouble(),
        season: json['season']! as int,
        week: json['week']! as int,
      );
}
