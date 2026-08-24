import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/talent_generator.dart';
import 'package:football_agent/domain/services/transfer_valuation_service.dart';
import 'package:football_agent/simulation/engines/offer_engine.dart';

void main() {
  const factory = GameFactory();
  const valuationService = TransferValuationService();

  test('important wonderkid receives a meaningful reservation-price premium',
      () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final club = base.clubs.first;
    final original = base.playersForClub(club.id).reduce(
          (best, player) => player.ability > best.ability ? player : best,
        );
    final star = original.copyWith(
      age: 19,
      potential: 96,
      value: 50000000,
      contractEndSeason: 5,
    );
    final game = base.copyWith(
      players: [
        for (final player in base.players)
          if (player.id == star.id) star else player,
      ],
    );

    final valuation = valuationService.valueForSeller(game, star);

    expect(valuation.importance, greaterThan(0.55));
    expect(valuation.wonderkidValue, greaterThan(0.65));
    expect(valuation.askingPrice, greaterThan(70000000));
  });

  test('sale chance rises with price but never hard-blocks an important player',
      () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final player = base.playersForClub(base.clubs.first.id).first;
    final valuation = valuationService.valueForSeller(base, player);
    final lowOffer = valuationService.saleProbability(
      valuation: valuation,
      offer: valuation.askingPrice * 0.65,
      isTransferListed: false,
    );
    final strongOffer = valuationService.saleProbability(
      valuation: valuation,
      offer: valuation.askingPrice * 1.15,
      isTransferListed: false,
    );

    expect(lowOffer, greaterThan(0));
    expect(strongOffer, greaterThan(lowOffer));
    expect(strongOffer, lessThan(1));
  });

  test('ambitious sellers ask more without making a player unsellable', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final player = base.playersForClub(base.clubs.first.id).reduce(
          (best, candidate) =>
              candidate.ability > best.ability ? candidate : best,
        );
    final relaxed = valuationService.valueForSeller(
      base,
      player,
      sellerAmbition: 0.2,
    );
    final ambitious = valuationService.valueForSeller(
      base,
      player,
      sellerAmbition: 0.95,
    );
    final premiumOfferChance = valuationService.saleProbability(
      valuation: ambitious,
      offer: ambitious.askingPrice * 1.2,
      isTransferListed: false,
    );

    expect(ambitious.askingPrice, greaterThan(relaxed.askingPrice));
    expect(premiumOfferChance, greaterThan(0.5));
    expect(premiumOfferChance, lessThan(1));
  });

  test('weighted destinations spread similar clients across several clubs', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final prospects = const TalentGenerator()
        .generate(
          count: 8,
          reputation: 20,
          seed: 501,
          idPrefix: 'distribution',
        )
        .map(
          (player) => player.copyWith(
            agentId: base.agent.id,
            isRecruited: true,
          ),
        )
        .toList(growable: false);
    var game = base.copyWith(players: [...base.players, ...prospects]);
    final destinations = <String>{};

    for (final player in prospects) {
      final offers = const OfferEngine().generateOffers(
        game: game,
        player: player,
      );
      expect(offers, isNotEmpty);
      destinations.add(offers.first.clubId);
      game = game.copyWith(offers: [...game.offers, ...offers]);
    }

    expect(destinations.length, greaterThanOrEqualTo(3));
  });
}
