class ClubAgencyRelationship {
  const ClubAgencyRelationship({required this.clubId, this.score = 0});

  final String clubId;
  final int score;

  ClubAgencyRelationship adjust(int change) => ClubAgencyRelationship(
        clubId: clubId,
        score: (score + change).clamp(-100, 100),
      );

  Map<String, Object> toJson() => {'clubId': clubId, 'score': score};

  factory ClubAgencyRelationship.fromJson(Map<String, Object?> json) =>
      ClubAgencyRelationship(
        clubId: json['clubId']! as String,
        score: ((json['score'] as int?) ?? 0).clamp(-100, 100),
      );
}
