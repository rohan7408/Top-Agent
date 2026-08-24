class PlayerPersonality {
  const PlayerPersonality({
    this.professionalism = 50,
    this.discipline = 50,
    this.ambition = 50,
    this.mediaAppeal = 50,
  });

  final int professionalism;
  final int discipline;
  final int ambition;
  final int mediaAppeal;

  Map<String, Object> toJson() => {
        'professionalism': professionalism,
        'discipline': discipline,
        'ambition': ambition,
        'mediaAppeal': mediaAppeal,
      };

  factory PlayerPersonality.fromJson(Map<String, Object?> json) =>
      PlayerPersonality(
        professionalism: _rating(json['professionalism']),
        discipline: _rating(json['discipline']),
        ambition: _rating(json['ambition']),
        mediaAppeal: _rating(json['mediaAppeal']),
      );

  static int _rating(Object? value) => ((value as int?) ?? 50).clamp(1, 100);
}
