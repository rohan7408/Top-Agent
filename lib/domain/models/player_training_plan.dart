enum TrainingFocus {
  balanced,
  attacking,
  defending,
  technical,
  mental,
  physical,
  speed,
}

extension TrainingFocusDetails on TrainingFocus {
  String get label => switch (this) {
        TrainingFocus.balanced => 'Balanced',
        TrainingFocus.attacking => 'Attacking',
        TrainingFocus.defending => 'Defending',
        TrainingFocus.technical => 'Technical',
        TrainingFocus.mental => 'Mental',
        TrainingFocus.physical => 'Physical',
        TrainingFocus.speed => 'Speed',
      };

  String get description => switch (this) {
        TrainingFocus.balanced => 'Targets the weakest headline rating',
        TrainingFocus.attacking => 'Finishing and attacking movement',
        TrainingFocus.defending => 'Tackling, positioning and strength',
        TrainingFocus.technical => 'Passing, touch and ball control',
        TrainingFocus.mental => 'Decisions, vision and composure',
        TrainingFocus.physical => 'Stamina, strength and jumping',
        TrainingFocus.speed => 'Pace, acceleration and agility',
      };
}

enum TrainingIntensity { light, normal, intense }

extension TrainingIntensityDetails on TrainingIntensity {
  String get label => switch (this) {
        TrainingIntensity.light => 'Light',
        TrainingIntensity.normal => 'Normal',
        TrainingIntensity.intense => 'Intense',
      };

  String get effectLabel => switch (this) {
        TrainingIntensity.light => '75% progress · +1 fatigue',
        TrainingIntensity.normal => '100% progress · +3 fatigue',
        TrainingIntensity.intense => '135% progress · +7 fatigue',
      };

  double get progressMultiplier => switch (this) {
        TrainingIntensity.light => 0.75,
        TrainingIntensity.normal => 1,
        TrainingIntensity.intense => 1.35,
      };

  double get fatigueLoad => switch (this) {
        TrainingIntensity.light => 1,
        TrainingIntensity.normal => 3,
        TrainingIntensity.intense => 7,
      };
}

class PlayerTrainingPlan {
  const PlayerTrainingPlan({
    required this.playerId,
    this.focus = TrainingFocus.balanced,
    this.intensity = TrainingIntensity.normal,
    this.progress = 0,
  });

  final String playerId;
  final TrainingFocus focus;
  final TrainingIntensity intensity;
  final int progress;

  PlayerTrainingPlan copyWith({
    TrainingFocus? focus,
    TrainingIntensity? intensity,
    int? progress,
  }) {
    return PlayerTrainingPlan(
      playerId: playerId,
      focus: focus ?? this.focus,
      intensity: intensity ?? this.intensity,
      progress: progress ?? this.progress,
    );
  }

  Map<String, Object> toJson() => {
        'playerId': playerId,
        'focus': focus.name,
        'intensity': intensity.name,
        'progress': progress,
      };

  factory PlayerTrainingPlan.fromJson(Map<String, Object?> json) {
    return PlayerTrainingPlan(
      playerId: json['playerId']! as String,
      focus: TrainingFocus.values.byName(json['focus']! as String),
      intensity: TrainingIntensity.values.byName(json['intensity']! as String),
      progress: (json['progress'] as int?) ?? 0,
    );
  }
}
