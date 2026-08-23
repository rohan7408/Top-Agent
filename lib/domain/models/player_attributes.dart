class PlayerAttributes {
  const PlayerAttributes({
    required this.finishing,
    required this.passing,
    required this.dribbling,
    required this.tackling,
    required this.firstTouch,
    required this.goalkeeping,
    required this.decisions,
    required this.composure,
    required this.anticipation,
    required this.positioning,
    required this.vision,
    required this.workRate,
    required this.pace,
    required this.acceleration,
    required this.agility,
    required this.stamina,
    required this.strength,
    required this.jumping,
  });

  factory PlayerAttributes.balanced(int rating) {
    final safeRating = rating.clamp(1, 99);
    return PlayerAttributes(
      finishing: safeRating,
      passing: safeRating,
      dribbling: safeRating,
      tackling: safeRating,
      firstTouch: safeRating,
      goalkeeping: safeRating,
      decisions: safeRating,
      composure: safeRating,
      anticipation: safeRating,
      positioning: safeRating,
      vision: safeRating,
      workRate: safeRating,
      pace: safeRating,
      acceleration: safeRating,
      agility: safeRating,
      stamina: safeRating,
      strength: safeRating,
      jumping: safeRating,
    );
  }

  final int finishing;
  final int passing;
  final int dribbling;
  final int tackling;
  final int firstTouch;
  final int goalkeeping;

  final int decisions;
  final int composure;
  final int anticipation;
  final int positioning;
  final int vision;
  final int workRate;

  final int pace;
  final int acceleration;
  final int agility;
  final int stamina;
  final int strength;
  final int jumping;

  int get attacking => _roundedAverage([
        finishing,
        dribbling,
        firstTouch,
        composure,
        anticipation,
        positioning,
      ]);

  int get defending => _roundedAverage([
        tackling,
        positioning,
        anticipation,
        workRate,
        strength,
        jumping,
      ]);

  int get technical => _roundedAverage([
        passing,
        dribbling,
        firstTouch,
        finishing,
        vision,
      ]);

  int get mental => _roundedAverage([
        decisions,
        composure,
        anticipation,
        positioning,
        vision,
        workRate,
      ]);

  int get physical => _roundedAverage([
        agility,
        stamina,
        strength,
        jumping,
      ]);

  int get speed => _roundedAverage([pace, acceleration, agility]);

  static int _roundedAverage(List<int> values) =>
      (values.reduce((first, second) => first + second) / values.length)
          .round();

  PlayerAttributes copyWith({
    int? finishing,
    int? passing,
    int? dribbling,
    int? tackling,
    int? firstTouch,
    int? goalkeeping,
    int? decisions,
    int? composure,
    int? anticipation,
    int? positioning,
    int? vision,
    int? workRate,
    int? pace,
    int? acceleration,
    int? agility,
    int? stamina,
    int? strength,
    int? jumping,
  }) {
    int safe(int value) => value.clamp(1, 99);
    return PlayerAttributes(
      finishing: safe(finishing ?? this.finishing),
      passing: safe(passing ?? this.passing),
      dribbling: safe(dribbling ?? this.dribbling),
      tackling: safe(tackling ?? this.tackling),
      firstTouch: safe(firstTouch ?? this.firstTouch),
      goalkeeping: safe(goalkeeping ?? this.goalkeeping),
      decisions: safe(decisions ?? this.decisions),
      composure: safe(composure ?? this.composure),
      anticipation: safe(anticipation ?? this.anticipation),
      positioning: safe(positioning ?? this.positioning),
      vision: safe(vision ?? this.vision),
      workRate: safe(workRate ?? this.workRate),
      pace: safe(pace ?? this.pace),
      acceleration: safe(acceleration ?? this.acceleration),
      agility: safe(agility ?? this.agility),
      stamina: safe(stamina ?? this.stamina),
      strength: safe(strength ?? this.strength),
      jumping: safe(jumping ?? this.jumping),
    );
  }

  PlayerAttributes evolve({
    required int technicalDelta,
    required int mentalDelta,
    required int physicalDelta,
  }) {
    int adjusted(int value, int delta) => (value + delta).clamp(1, 99);

    return PlayerAttributes(
      finishing: adjusted(finishing, technicalDelta),
      passing: adjusted(passing, technicalDelta),
      dribbling: adjusted(dribbling, technicalDelta),
      tackling: adjusted(tackling, technicalDelta),
      firstTouch: adjusted(firstTouch, technicalDelta),
      goalkeeping: adjusted(goalkeeping, technicalDelta),
      decisions: adjusted(decisions, mentalDelta),
      composure: adjusted(composure, mentalDelta),
      anticipation: adjusted(anticipation, mentalDelta),
      positioning: adjusted(positioning, mentalDelta),
      vision: adjusted(vision, mentalDelta),
      workRate: adjusted(workRate, mentalDelta),
      pace: adjusted(pace, physicalDelta),
      acceleration: adjusted(acceleration, physicalDelta),
      agility: adjusted(agility, physicalDelta),
      stamina: adjusted(stamina, physicalDelta),
      strength: adjusted(strength, physicalDelta),
      jumping: adjusted(jumping, physicalDelta),
    );
  }

  Map<String, Object> toJson() => {
        'finishing': finishing,
        'passing': passing,
        'dribbling': dribbling,
        'tackling': tackling,
        'firstTouch': firstTouch,
        'goalkeeping': goalkeeping,
        'decisions': decisions,
        'composure': composure,
        'anticipation': anticipation,
        'positioning': positioning,
        'vision': vision,
        'workRate': workRate,
        'pace': pace,
        'acceleration': acceleration,
        'agility': agility,
        'stamina': stamina,
        'strength': strength,
        'jumping': jumping,
      };

  factory PlayerAttributes.fromJson(Map<String, Object?> json) {
    return PlayerAttributes(
      finishing: json['finishing']! as int,
      passing: json['passing']! as int,
      dribbling: json['dribbling']! as int,
      tackling: json['tackling']! as int,
      firstTouch: json['firstTouch']! as int,
      goalkeeping: json['goalkeeping']! as int,
      decisions: json['decisions']! as int,
      composure: json['composure']! as int,
      anticipation: json['anticipation']! as int,
      positioning: json['positioning']! as int,
      vision: json['vision']! as int,
      workRate: json['workRate']! as int,
      pace: json['pace']! as int,
      acceleration: json['acceleration']! as int,
      agility: json['agility']! as int,
      stamina: json['stamina']! as int,
      strength: json['strength']! as int,
      jumping: json['jumping']! as int,
    );
  }
}
