import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/friend.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'quest_provider.dart';

class FriendsState {
  const FriendsState({
    this.friends = const [],
    this.incoming = const [],
    this.outgoingIds = const {},
  });

  final List<User> friends;

  /// Кіріс өтінімдер: (өтінім, жіберуші).
  final List<(FriendRequest, User)> incoming;

  /// Жіберілген (pending) өтінімдердің алушы id-лері.
  final Set<String> outgoingIds;
}

/// Достар: іздеу, өтінім, қабылдау — бәрі локальді.
/// Mock қолданушылар жіберілген өтінімді 10 секундтан кейін
/// «қабылдайды» (offline тірілік имитациясы).
class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier(this._ref, this._storage, this._userId)
      : super(const FriendsState()) {
    load();
  }

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;

  Future<void> load() async {
    if (_userId == null) return;
    try {
      final requests = _storage.getAllFriendRequests();
      final now = DateTime.now();

      // Mock қолданушылар ескі pending өтінімдерді авто-қабылдайды.
      for (final r in requests) {
        if (r.fromUserId == _userId &&
            r.status == FriendRequestStatus.pending &&
            r.toUserId.startsWith('u_mock_') &&
            now.difference(r.createdAt).inSeconds > 10) {
          await _storage.saveFriendRequest(
            r.copyWith(status: FriendRequestStatus.accepted),
          );
        }
      }

      final fresh = _storage.getAllFriendRequests();
      final friendIds = <String>{};
      final incoming = <(FriendRequest, User)>[];
      final outgoing = <String>{};

      for (final r in fresh) {
        if (r.status == FriendRequestStatus.accepted) {
          if (r.fromUserId == _userId) friendIds.add(r.toUserId);
          if (r.toUserId == _userId) friendIds.add(r.fromUserId);
        } else if (r.status == FriendRequestStatus.pending) {
          if (r.toUserId == _userId) {
            final from = _storage.getUser(r.fromUserId);
            if (from != null) incoming.add((r, from));
          } else if (r.fromUserId == _userId) {
            outgoing.add(r.toUserId);
          }
        }
      }

      final friends = [
        for (final id in friendIds)
          if (_storage.getUser(id) != null) _storage.getUser(id)!,
      ]..sort((a, b) => b.akylPoints.compareTo(a.akylPoints));

      state = FriendsState(
        friends: friends,
        incoming: incoming,
        outgoingIds: outgoing,
      );
    } catch (_) {
      state = const FriendsState();
    }
  }

  /// QQ-ID бойынша іздеу (өзін таппайды).
  User? searchUser(String qqId) {
    final found = _storage.findUserByQqId(qqId);
    if (found == null || found.id == _userId) return null;
    return found;
  }

  bool isFriend(String userId) => state.friends.any((f) => f.id == userId);

  Future<void> sendFriendRequest(String toUserId) async {
    if (_userId == null || toUserId == _userId) return;
    if (isFriend(toUserId) || state.outgoingIds.contains(toUserId)) return;
    await _storage.saveFriendRequest(FriendRequest(
      id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: _userId,
      toUserId: toUserId,
      createdAt: DateTime.now(),
    ));
    await load();
  }

  Future<void> acceptRequest(String requestId) async {
    final requests = _storage.getAllFriendRequests();
    for (final r in requests) {
      if (r.id == requestId) {
        await _storage.saveFriendRequest(
          r.copyWith(status: FriendRequestStatus.accepted),
        );
        break;
      }
    }
    await load();
    await _ref.read(questProvider.notifier).track(QuestType.addFriend);
    await _ref.read(achievementProvider.notifier).evaluate();
  }

  Future<void> declineRequest(String requestId) async {
    final requests = _storage.getAllFriendRequests();
    for (final r in requests) {
      if (r.id == requestId) {
        await _storage.saveFriendRequest(
          r.copyWith(status: FriendRequestStatus.declined),
        );
        break;
      }
    }
    await load();
  }
}

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return FriendsNotifier(ref, ref.watch(storageProvider), userId);
});
