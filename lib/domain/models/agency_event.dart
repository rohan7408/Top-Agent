enum AgencyEventCategory { commercial, discipline, career, welfare, agency }

enum AgencyEventType {
  localAdvertising,
  bootSponsorship,
  paidAppearance,
  propertyDamage,
  missedTraining,
  nightclubIncident,
  playingTimeComplaint,
  transferRequest,
  specialistTreatment,
  familyEmergency,
  scoutTravelRequest,
  officeRepair,
}

extension AgencyEventTypeInfo on AgencyEventType {
  AgencyEventCategory get category => switch (this) {
        AgencyEventType.localAdvertising ||
        AgencyEventType.bootSponsorship ||
        AgencyEventType.paidAppearance =>
          AgencyEventCategory.commercial,
        AgencyEventType.propertyDamage ||
        AgencyEventType.missedTraining ||
        AgencyEventType.nightclubIncident =>
          AgencyEventCategory.discipline,
        AgencyEventType.playingTimeComplaint ||
        AgencyEventType.transferRequest =>
          AgencyEventCategory.career,
        AgencyEventType.specialistTreatment ||
        AgencyEventType.familyEmergency =>
          AgencyEventCategory.welfare,
        AgencyEventType.scoutTravelRequest ||
        AgencyEventType.officeRepair =>
          AgencyEventCategory.agency,
      };
}

enum AgencyEventStatus { pending, resolved, expired }

enum AgencyEventOutcome { pending, succeeded, failed, recorded, expired }

class AgencyEventChoice {
  const AgencyEventChoice({
    required this.id,
    required this.label,
    required this.detail,
    required this.successMessage,
    this.moneyImpact = 0,
    this.reputationImpact = 0,
    this.fatigueImpact = 0,
    this.successChance = 1,
    this.failureMessage,
    this.failureMoneyImpact = 0,
    this.failureReputationImpact = 0,
    this.failureFatigueImpact = 0,
  });

  final String id;
  final String label;
  final String detail;
  final String successMessage;
  final double moneyImpact;
  final int reputationImpact;
  final double fatigueImpact;
  final double successChance;
  final String? failureMessage;
  final double failureMoneyImpact;
  final int failureReputationImpact;
  final double failureFatigueImpact;

  bool get isUncertain => successChance < 1;

  String get riskLabel {
    if (!isUncertain) return 'Certain';
    if (successChance >= 0.70) return 'Low risk';
    if (successChance >= 0.50) return 'Medium risk';
    return 'High risk';
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'detail': detail,
        'successMessage': successMessage,
        'moneyImpact': moneyImpact,
        'reputationImpact': reputationImpact,
        'fatigueImpact': fatigueImpact,
        'successChance': successChance,
        'failureMessage': failureMessage,
        'failureMoneyImpact': failureMoneyImpact,
        'failureReputationImpact': failureReputationImpact,
        'failureFatigueImpact': failureFatigueImpact,
      };

  factory AgencyEventChoice.fromJson(Map<String, Object?> json) =>
      AgencyEventChoice(
        id: json['id']! as String,
        label: json['label']! as String,
        detail: json['detail']! as String,
        successMessage: json['successMessage']! as String,
        moneyImpact: ((json['moneyImpact'] as num?) ?? 0).toDouble(),
        reputationImpact: (json['reputationImpact'] as int?) ?? 0,
        fatigueImpact: ((json['fatigueImpact'] as num?) ?? 0).toDouble(),
        successChance: ((json['successChance'] as num?) ?? 1).toDouble(),
        failureMessage: json['failureMessage'] as String?,
        failureMoneyImpact:
            ((json['failureMoneyImpact'] as num?) ?? 0).toDouble(),
        failureReputationImpact: (json['failureReputationImpact'] as int?) ?? 0,
        failureFatigueImpact:
            ((json['failureFatigueImpact'] as num?) ?? 0).toDouble(),
      );
}

class AgencyEvent {
  const AgencyEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.season,
    required this.week,
    required this.expiresAbsoluteWeek,
    required this.choices,
    this.playerId,
    this.clubId,
    this.scoutId,
    this.status = AgencyEventStatus.pending,
    this.resolvedChoiceId,
    this.outcomeSummary,
    this.resolvedSeason,
    this.resolvedWeek,
    this.resolvedMoneyImpact = 0,
    this.resolvedReputationImpact = 0,
    this.resolvedFatigueImpact = 0,
    this.resolvedSucceeded,
  });

  final String id;
  final AgencyEventType type;
  final String title;
  final String body;
  final int season;
  final int week;
  final int expiresAbsoluteWeek;
  final List<AgencyEventChoice> choices;
  final String? playerId;
  final String? clubId;
  final String? scoutId;
  final AgencyEventStatus status;
  final String? resolvedChoiceId;
  final String? outcomeSummary;
  final int? resolvedSeason;
  final int? resolvedWeek;
  final double resolvedMoneyImpact;
  final int resolvedReputationImpact;
  final double resolvedFatigueImpact;
  final bool? resolvedSucceeded;

  AgencyEventCategory get category => type.category;
  int get absoluteWeek => ((season - 1) * 50) + week;

  AgencyEventOutcome get outcome {
    if (status == AgencyEventStatus.pending) return AgencyEventOutcome.pending;
    if (status == AgencyEventStatus.expired) return AgencyEventOutcome.expired;
    final choice = choices
        .where((candidate) => candidate.id == resolvedChoiceId)
        .firstOrNull;
    if (choice == null || !choice.isUncertain) {
      return AgencyEventOutcome.recorded;
    }
    if (resolvedSucceeded != null) {
      return resolvedSucceeded!
          ? AgencyEventOutcome.succeeded
          : AgencyEventOutcome.failed;
    }
    final failure = choice.failureMessage;
    if (failure != null && (outcomeSummary ?? '').startsWith(failure)) {
      return AgencyEventOutcome.failed;
    }
    return AgencyEventOutcome.succeeded;
  }

  AgencyEvent copyWith({
    AgencyEventStatus? status,
    String? resolvedChoiceId,
    String? outcomeSummary,
    int? resolvedSeason,
    int? resolvedWeek,
    double? resolvedMoneyImpact,
    int? resolvedReputationImpact,
    double? resolvedFatigueImpact,
    bool? resolvedSucceeded,
  }) =>
      AgencyEvent(
        id: id,
        type: type,
        title: title,
        body: body,
        season: season,
        week: week,
        expiresAbsoluteWeek: expiresAbsoluteWeek,
        choices: choices,
        playerId: playerId,
        clubId: clubId,
        scoutId: scoutId,
        status: status ?? this.status,
        resolvedChoiceId: resolvedChoiceId ?? this.resolvedChoiceId,
        outcomeSummary: outcomeSummary ?? this.outcomeSummary,
        resolvedSeason: resolvedSeason ?? this.resolvedSeason,
        resolvedWeek: resolvedWeek ?? this.resolvedWeek,
        resolvedMoneyImpact: resolvedMoneyImpact ?? this.resolvedMoneyImpact,
        resolvedReputationImpact:
            resolvedReputationImpact ?? this.resolvedReputationImpact,
        resolvedFatigueImpact:
            resolvedFatigueImpact ?? this.resolvedFatigueImpact,
        resolvedSucceeded: resolvedSucceeded ?? this.resolvedSucceeded,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'season': season,
        'week': week,
        'expiresAbsoluteWeek': expiresAbsoluteWeek,
        'choices': choices.map((choice) => choice.toJson()).toList(),
        'playerId': playerId,
        'clubId': clubId,
        'scoutId': scoutId,
        'status': status.name,
        'resolvedChoiceId': resolvedChoiceId,
        'outcomeSummary': outcomeSummary,
        'resolvedSeason': resolvedSeason,
        'resolvedWeek': resolvedWeek,
        'resolvedMoneyImpact': resolvedMoneyImpact,
        'resolvedReputationImpact': resolvedReputationImpact,
        'resolvedFatigueImpact': resolvedFatigueImpact,
        'resolvedSucceeded': resolvedSucceeded,
      };

  factory AgencyEvent.fromJson(Map<String, Object?> json) => AgencyEvent(
        id: json['id']! as String,
        type: AgencyEventType.values.byName(json['type']! as String),
        title: json['title']! as String,
        body: json['body']! as String,
        season: json['season']! as int,
        week: json['week']! as int,
        expiresAbsoluteWeek: json['expiresAbsoluteWeek']! as int,
        choices: (json['choices']! as List<Object?>)
            .map((item) => AgencyEventChoice.fromJson(
                  (item! as Map).cast<String, Object?>(),
                ))
            .toList(growable: false),
        playerId: json['playerId'] as String?,
        clubId: json['clubId'] as String?,
        scoutId: json['scoutId'] as String?,
        status: AgencyEventStatus.values.byName(
          (json['status'] as String?) ?? AgencyEventStatus.pending.name,
        ),
        resolvedChoiceId: json['resolvedChoiceId'] as String?,
        outcomeSummary: json['outcomeSummary'] as String?,
        resolvedSeason: json['resolvedSeason'] as int?,
        resolvedWeek: json['resolvedWeek'] as int?,
        resolvedMoneyImpact:
            ((json['resolvedMoneyImpact'] as num?) ?? 0).toDouble(),
        resolvedReputationImpact:
            (json['resolvedReputationImpact'] as int?) ?? 0,
        resolvedFatigueImpact:
            ((json['resolvedFatigueImpact'] as num?) ?? 0).toDouble(),
        resolvedSucceeded: json['resolvedSucceeded'] as bool?,
      );
}
