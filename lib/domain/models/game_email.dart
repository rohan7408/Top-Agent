enum GameEmailType { transfer, contract, finance, world }

class GameEmail {
  const GameEmail({
    required this.id,
    required this.type,
    required this.subject,
    required this.body,
    required this.season,
    required this.week,
    this.isRead = false,
    this.playerId,
    this.clubId,
  });

  final String id;
  final GameEmailType type;
  final String subject;
  final String body;
  final int season;
  final int week;
  final bool isRead;
  final String? playerId;
  final String? clubId;

  GameEmail copyWith({bool? isRead}) => GameEmail(
        id: id,
        type: type,
        subject: subject,
        body: body,
        season: season,
        week: week,
        isRead: isRead ?? this.isRead,
        playerId: playerId,
        clubId: clubId,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'subject': subject,
        'body': body,
        'season': season,
        'week': week,
        'isRead': isRead,
        'playerId': playerId,
        'clubId': clubId,
      };

  factory GameEmail.fromJson(Map<String, Object?> json) => GameEmail(
        id: json['id']! as String,
        type: GameEmailType.values.byName(json['type']! as String),
        subject: json['subject']! as String,
        body: json['body']! as String,
        season: json['season']! as int,
        week: json['week']! as int,
        isRead: (json['isRead'] as bool?) ?? false,
        playerId: json['playerId'] as String?,
        clubId: json['clubId'] as String?,
      );
}
