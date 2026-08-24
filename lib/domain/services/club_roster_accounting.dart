import '../models/club.dart';
import '../models/player.dart';

class ClubRosterAccounting {
  const ClubRosterAccounting();

  Club synchronize(Club club, Iterable<Player> players) {
    final roster = players
        .where((player) => player.clubId == club.id && !player.isRetired)
        .toList(growable: false);
    return club.copyWith(
      squadValue: roster.fold<double>(
        0,
        (total, player) => total + player.value,
      ),
      totalSalary: roster.fold<double>(
        0,
        (total, player) => total + player.salary,
      ),
      playerIds: roster.map((player) => player.id).toList(growable: false),
    );
  }
}
