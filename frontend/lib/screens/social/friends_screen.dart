import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/user.dart';
import '../../providers/friends_provider.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/reward_toast.dart';
import '../../widgets/ui/user_photo.dart';

/// Достар экраны: Достарым / Өтінімдер (badge) / Іздеу.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  User? _searchResult;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    // Mock қолданушылар авто-қабылдаған өтінімдерді жаңарту.
    Future.microtask(() => ref.read(friendsProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    final found =
        ref.read(friendsProvider.notifier).searchUser(_searchController.text);
    setState(() {
      _searchResult = found;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.friendsTitle),
          bottom: TabBar(
            labelStyle:
                AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800),
            labelColor: AppColors.eagleBlue,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.eagleBlue,
            tabs: [
              const Tab(text: AppStrings.tabMyFriends),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(AppStrings.tabRequests),
                    if (state.incoming.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sp1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.dangerCoral,
                          borderRadius:
                              BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          '${state.incoming.length}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: AppStrings.tabSearch),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _friendsTab(state),
            _requestsTab(state),
            _searchTab(state),
          ],
        ),
      ),
    );
  }

  // ---- Достарым ----
  Widget _friendsTab(FriendsState state) {
    if (state.friends.isEmpty) {
      return const _EmptyState(
        icon: Icons.group_outlined,
        text: AppStrings.noFriends,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      itemCount: state.friends.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sp3),
      itemBuilder: (context, index) {
        final friend = state.friends[index];
        return _FriendCard(
          user: friend,
          trailing: SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
                backgroundColor: AppColors.dangerCoral,
                textStyle: AppTypography.caption,
              ),
              onPressed: () => context.push('/battle-setup', extra: friend),
              child: const Text(AppStrings.battleBtn),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: .06);
      },
    );
  }

  // ---- Өтінімдер ----
  Widget _requestsTab(FriendsState state) {
    if (state.incoming.isEmpty) {
      return const _EmptyState(
        icon: Icons.mark_email_unread_outlined,
        text: AppStrings.noRequests,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      itemCount: state.incoming.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sp3),
      itemBuilder: (context, index) {
        final (request, from) = state.incoming[index];
        return _FriendCard(
          user: from,
          subtitle: Formatters.relativeTime(request.createdAt),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundAction(
                icon: Icons.check_rounded,
                color: AppColors.successJade,
                label: AppStrings.accept,
                onTap: () async {
                  await ref
                      .read(friendsProvider.notifier)
                      .acceptRequest(request.id);
                  if (context.mounted) {
                    RewardToast.show(
                      context,
                      message: AppStrings.nowYourFriend(from.firstName),
                    );
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sp2),
              _RoundAction(
                icon: Icons.close_rounded,
                color: AppColors.dangerCoral,
                label: AppStrings.decline,
                onTap: () => ref
                    .read(friendsProvider.notifier)
                    .declineRequest(request.id),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- Іздеу ----
  Widget _searchTab(FriendsState state) {
    final result = _searchResult;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textCapitalization: TextCapitalization.characters,
                style: AppTypography.body.copyWith(letterSpacing: 1),
                decoration: const InputDecoration(
                  hintText: AppStrings.searchHint,
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4,
                  ),
                ),
                child: const Text(AppStrings.searchBtn),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp5),
        if (_searched && result == null)
          const _EmptyState(
            icon: Icons.person_search_outlined,
            text: AppStrings.notFoundUser,
          )
        else if (result != null)
          _FriendCard(
            user: result,
            trailing: _searchTrailing(state, result),
          ).animate().fadeIn().slideY(begin: .08),
      ],
    );
  }

  Widget _searchTrailing(FriendsState state, User result) {
    final notifier = ref.read(friendsProvider.notifier);
    if (notifier.isFriend(result.id)) {
      return Text(
        AppStrings.tabMyFriends,
        style: AppTypography.caption.copyWith(color: AppColors.successJade),
      );
    }
    if (state.outgoingIds.contains(result.id)) {
      return Text(
        AppStrings.requestSent,
        style: AppTypography.caption.copyWith(color: AppColors.eagleBlue),
      );
    }
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
          textStyle: AppTypography.caption,
        ),
        onPressed: () async {
          await notifier.sendFriendRequest(result.id);
          if (mounted) {
            RewardToast.show(context, message: AppStrings.requestSent);
          }
        },
        child: const Text(AppStrings.addFriend),
      ),
    );
  }
}

/// Дос картасы: аватар + аты + QQ-ID + деңгей/ақыл + оң жақ әрекет.
class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.user,
    this.subtitle,
    this.trailing,
  });

  final User user;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: AppColors.sh1,
      ),
      child: Row(
        children: [
          UserPhoto(photoPath: user.profilePhotoPath, size: 48),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle ??
                      '${user.qosqanatId} · ${user.level} LVL · ★ ${Formatters.number(user.akylPoints)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sp2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color.withValues(alpha: .12),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return EmptyState(icon: icon, title: text, accent: AppColors.eagleBlue);
  }
}
