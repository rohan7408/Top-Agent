import 'dart:math';

import '../models/club.dart';
import '../models/club_manager.dart';
import '../models/league.dart';
import '../models/player.dart';
import 'game_balance.dart';
import 'player_attribute_generator.dart';

class FootballWorldSeed {
  const FootballWorldSeed({
    required this.leagues,
    required this.clubs,
    required this.players,
    required this.managers,
  });

  final List<League> leagues;
  final List<Club> clubs;
  final List<Player> players;
  final List<ClubManager> managers;
}

class FootballWorldFactory {
  const FootballWorldFactory({
    this.attributeGenerator = const PlayerAttributeGenerator(),
    this.balance = const GameBalance(),
  });

  final PlayerAttributeGenerator attributeGenerator;
  final GameBalance balance;

  static const premierLeagueId = 'league-premier';
  static const squadSize = 18;

  static const _clubNames = [
    'Northbridge FC',
    'Kingsport Athletic',
    'Rivergate City',
    'Westhaven United',
    'Eastborough FC',
    'Redwick Rovers',
    'Ashford Town',
    'Millchester City',
    'Southbank FC',
    'Crownfield Athletic',
    'Beacon United',
    'Hartmere FC',
    'Stonewall City',
    'Lakeside Rovers',
    'Oakmont Town',
    'Greycastle FC',
    'Portminster',
    'Highland Athletic',
    'Wellington Park',
    'Elmstead United',
  ];

  static const _firstNames = [
    'James',
    'Daniel',
    'Oliver',
    'Samuel',
    'Lucas',
    'Adam',
    'Felix',
    'Marco',
    'David',
    'Andre',
    'Victor',
    'Elias',
    'Hugo',
    'Ivan',
    'Owen',
    'Kai',
    'Ben',
    'Max',
  ];

  static const _lastNames = [
    'Carter',
    'Mendes',
    'Anders',
    'Okafor',
    'Marin',
    'Clarke',
    'Reyes',
    'Hansen',
    'Costa',
    'Bauer',
    'Morgan',
    'Pereira',
    'Miller',
    'Said',
    'Ward',
    'Nielsen',
    'Grant',
    'Torres',
  ];

  static const _managerFirstNames = [
    'Thomas',
    'Rafael',
    'Dario',
    'Martin',
    'Bruno',
    'Erik',
    'Paolo',
    'Graham',
  ];

  static const _managerLastNames = [
    'Mercer',
    'Silva',
    'Varga',
    'Cole',
    'Navarro',
    'Lind',
    'Moretti',
    'Price',
  ];

  FootballWorldSeed createPremierLeague({required int seed}) {
    final random = Random(seed);
    final clubs = <Club>[];
    final players = <Player>[];
    final managers = <ClubManager>[];

    for (var clubIndex = 0; clubIndex < _clubNames.length; clubIndex++) {
      final clubId = 'club-premier-${clubIndex + 1}';
      final playerIds = <String>[];
      var squadValue = 0.0;
      var totalSalary = 0.0;
      final clubStrength = 78 - (clubIndex ~/ 3) + random.nextInt(5);

      for (var squadIndex = 0; squadIndex < squadSize; squadIndex++) {
        final playerId = '$clubId-player-${squadIndex + 1}';
        final age = 19 + random.nextInt(15);
        final targetAbility =
            (clubStrength - 10 + random.nextInt(17)).clamp(45, 90);
        final position = _positionForSquadIndex(squadIndex);
        final attributes = attributeGenerator.generate(
          ability: targetAbility,
          position: position,
          random: random,
        );
        final body = attributeGenerator.generateBody(
          position: position,
          random: random,
        );
        final ability = Player.calculateOverall(position, attributes);
        final potential = min(
          99,
          max(ability, targetAbility + random.nextInt(max(2, 32 - age))),
        );
        final value = balance.playerMarketValue(
          ability: ability,
          potential: potential,
          age: age,
          position: position,
        );
        final salary = balance.weeklyWage(
          ability: ability,
          potential: potential,
          age: age,
          marketMultiplier: 0.92 + (random.nextDouble() * 0.16),
        );
        final nameIndex = (clubIndex * squadSize) + squadIndex;

        players.add(
          Player(
            id: playerId,
            name:
                '${_firstNames[(nameIndex + random.nextInt(_firstNames.length)) % _firstNames.length]} ${_lastNames[(nameIndex * 3 + random.nextInt(_lastNames.length)) % _lastNames.length]}',
            age: age,
            heightCm: body.heightCm,
            weightKg: body.weightKg,
            position: position,
            potential: potential,
            attributes: attributes,
            value: value.roundToDouble(),
            clubId: clubId,
            salary: salary.roundToDouble(),
            contractEndSeason: 2 + random.nextInt(5),
            isRecruited: false,
          ),
        );
        playerIds.add(playerId);
        squadValue += value;
        totalSalary += salary;
      }

      final budgetMultiplier = 0.16 + (random.nextDouble() * 0.12);
      clubs.add(
        Club(
          id: clubId,
          name: _clubNames[clubIndex],
          leagueId: premierLeagueId,
          clubValue:
              (squadValue * (1.6 + random.nextDouble() * 0.7)).roundToDouble(),
          squadValue: squadValue.roundToDouble(),
          totalSalary: totalSalary.roundToDouble(),
          budget: (squadValue * budgetMultiplier).roundToDouble(),
          balance:
              (squadValue * (0.8 + random.nextDouble() * 0.5)).roundToDouble(),
          playerIds: playerIds,
        ),
      );
      managers.add(
        ClubManager(
          id: 'manager-$clubId',
          clubId: clubId,
          name:
              '${_managerFirstNames[clubIndex % _managerFirstNames.length]} ${_managerLastNames[(clubIndex * 3) % _managerLastNames.length]}',
          age: 37 + random.nextInt(25),
          ability: (clubStrength - 4 + random.nextInt(9)).clamp(45, 92),
          youthDevelopment: 48 + random.nextInt(43),
          transferNegotiation: 48 + random.nextInt(43),
          tacticalStyle:
              TacticalStyle.values[random.nextInt(TacticalStyle.values.length)],
          contractEndSeason: 2 + random.nextInt(4),
          rotation: 48 + random.nextInt(43),
        ),
      );
    }

    final league = League(
      id: premierLeagueId,
      name: 'Premier League',
      country: 'England',
      clubIds: clubs.map((club) => club.id).toList(growable: false),
      positionPrizeMoney: List.generate(
        clubs.length,
        (index) => 100000000 - (index * 4500000),
      ),
    );

    return FootballWorldSeed(
      leagues: [league],
      clubs: clubs,
      players: players,
      managers: managers,
    );
  }

  static PlayerPosition _positionForSquadIndex(int index) {
    if (index < 2) return PlayerPosition.goalkeeper;
    if (index < 8) return PlayerPosition.defender;
    if (index < 14) return PlayerPosition.midfielder;
    return PlayerPosition.forward;
  }
}
