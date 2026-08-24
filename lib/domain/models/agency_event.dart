enum AgencyEventCategory {
  commercial,
  media,
  discipline,
  career,
  welfare,
  agency,
  finance,
}

enum AgencyEventType {
  localAdvertising,
  bootSponsorship,
  paidAppearance,
  televisionInterview,
  charityAppearance,
  socialMediaControversy,
  conflictingSponsors,
  documentaryOffer,
  imageRightsDispute,
  agencySponsorship,
  propertyDamage,
  missedTraining,
  nightclubIncident,
  playingTimeComplaint,
  transferRequest,
  specialistTreatment,
  familyEmergency,
  scoutTravelRequest,
  officeRepair,
  unexpectedTaxBill,
  legalComplaint,
  officeLeaseRenewal,
  dataBreach,
  insuranceRenewal,
  investorApproach,
  reputationConsultant,
  cashFlowCrisis,
}

extension AgencyEventTypeInfo on AgencyEventType {
  AgencyEventCategory get category => switch (this) {
        AgencyEventType.localAdvertising ||
        AgencyEventType.bootSponsorship ||
        AgencyEventType.paidAppearance ||
        AgencyEventType.conflictingSponsors ||
        AgencyEventType.imageRightsDispute ||
        AgencyEventType.agencySponsorship =>
          AgencyEventCategory.commercial,
        AgencyEventType.televisionInterview ||
        AgencyEventType.charityAppearance ||
        AgencyEventType.socialMediaControversy ||
        AgencyEventType.documentaryOffer =>
          AgencyEventCategory.media,
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
        AgencyEventType.officeRepair ||
        AgencyEventType.legalComplaint ||
        AgencyEventType.dataBreach ||
        AgencyEventType.reputationConsultant =>
          AgencyEventCategory.agency,
        AgencyEventType.unexpectedTaxBill ||
        AgencyEventType.officeLeaseRenewal ||
        AgencyEventType.insuranceRenewal ||
        AgencyEventType.investorApproach ||
        AgencyEventType.cashFlowCrisis =>
          AgencyEventCategory.finance,
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
    this.trustImpact = 0,
    this.clubRelationshipImpact = 0,
    this.successChance = 1,
    this.failureMessage,
    this.failureMoneyImpact = 0,
    this.failureReputationImpact = 0,
    this.failureFatigueImpact = 0,
    this.failureTrustImpact = 0,
    this.failureClubRelationshipImpact = 0,
  });

  final String id;
  final String label;
  final String detail;
  final String successMessage;
  final double moneyImpact;
  final int reputationImpact;
  final double fatigueImpact;
  final int trustImpact;
  final int clubRelationshipImpact;
  final double successChance;
  final String? failureMessage;
  final double failureMoneyImpact;
  final int failureReputationImpact;
  final double failureFatigueImpact;
  final int failureTrustImpact;
  final int failureClubRelationshipImpact;

  bool get isUncertain => successChance < 1;

  String get riskLabel {
    if (!isUncertain) return 'Certain';
    if (successChance >= 0.70) return 'Low risk';
    if (successChance >= 0.50) return 'Medium risk';
    return 'High risk';
  }

  AgencyEventChoice copyWith({
    double? successChance,
    int? trustImpact,
    int? clubRelationshipImpact,
    int? failureTrustImpact,
    int? failureClubRelationshipImpact,
  }) =>
      AgencyEventChoice(
        id: id,
        label: label,
        detail: detail,
        successMessage: successMessage,
        moneyImpact: moneyImpact,
        reputationImpact: reputationImpact,
        fatigueImpact: fatigueImpact,
        trustImpact: trustImpact ?? this.trustImpact,
        clubRelationshipImpact:
            clubRelationshipImpact ?? this.clubRelationshipImpact,
        successChance: successChance ?? this.successChance,
        failureMessage: failureMessage,
        failureMoneyImpact: failureMoneyImpact,
        failureReputationImpact: failureReputationImpact,
        failureFatigueImpact: failureFatigueImpact,
        failureTrustImpact: failureTrustImpact ?? this.failureTrustImpact,
        failureClubRelationshipImpact:
            failureClubRelationshipImpact ?? this.failureClubRelationshipImpact,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'detail': detail,
        'successMessage': successMessage,
        'moneyImpact': moneyImpact,
        'reputationImpact': reputationImpact,
        'fatigueImpact': fatigueImpact,
        'trustImpact': trustImpact,
        'clubRelationshipImpact': clubRelationshipImpact,
        'successChance': successChance,
        'failureMessage': failureMessage,
        'failureMoneyImpact': failureMoneyImpact,
        'failureReputationImpact': failureReputationImpact,
        'failureFatigueImpact': failureFatigueImpact,
        'failureTrustImpact': failureTrustImpact,
        'failureClubRelationshipImpact': failureClubRelationshipImpact,
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
        trustImpact: (json['trustImpact'] as int?) ?? 0,
        clubRelationshipImpact: (json['clubRelationshipImpact'] as int?) ?? 0,
        successChance: ((json['successChance'] as num?) ?? 1).toDouble(),
        failureMessage: json['failureMessage'] as String?,
        failureMoneyImpact:
            ((json['failureMoneyImpact'] as num?) ?? 0).toDouble(),
        failureReputationImpact: (json['failureReputationImpact'] as int?) ?? 0,
        failureFatigueImpact:
            ((json['failureFatigueImpact'] as num?) ?? 0).toDouble(),
        failureTrustImpact: (json['failureTrustImpact'] as int?) ?? 0,
        failureClubRelationshipImpact:
            (json['failureClubRelationshipImpact'] as int?) ?? 0,
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
    this.resolvedTrustImpact = 0,
    this.resolvedClubRelationshipImpact = 0,
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
  final int resolvedTrustImpact;
  final int resolvedClubRelationshipImpact;
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
    int? resolvedTrustImpact,
    int? resolvedClubRelationshipImpact,
    bool? resolvedSucceeded,
    List<AgencyEventChoice>? choices,
  }) =>
      AgencyEvent(
        id: id,
        type: type,
        title: title,
        body: body,
        season: season,
        week: week,
        expiresAbsoluteWeek: expiresAbsoluteWeek,
        choices: choices ?? this.choices,
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
        resolvedTrustImpact: resolvedTrustImpact ?? this.resolvedTrustImpact,
        resolvedClubRelationshipImpact: resolvedClubRelationshipImpact ??
            this.resolvedClubRelationshipImpact,
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
        'resolvedTrustImpact': resolvedTrustImpact,
        'resolvedClubRelationshipImpact': resolvedClubRelationshipImpact,
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
        resolvedTrustImpact: (json['resolvedTrustImpact'] as int?) ?? 0,
        resolvedClubRelationshipImpact:
            (json['resolvedClubRelationshipImpact'] as int?) ?? 0,
        resolvedSucceeded: json['resolvedSucceeded'] as bool?,
      );
}
