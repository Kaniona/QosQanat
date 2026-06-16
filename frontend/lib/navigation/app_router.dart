import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../screens/auth/assistant_select_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/learning_map_screen.dart';
import '../screens/learn/result_screen.dart';
import '../screens/learn/subject_select_screen.dart';
import '../screens/learn/task_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/rating/rating_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/social/battle_result_screen.dart';
import '../screens/social/battle_screen.dart';
import '../screens/social/battle_setup_screen.dart';
import '../screens/social/friends_screen.dart';
import '../screens/tournament/tournament_screen.dart';
import '../widgets/ui/app_drawer.dart';
import '../widgets/ui/app_tab_bar.dart';

/// Кіруді талап етпейтін маршруттар.
const _publicPaths = {
  '/splash',
  '/welcome',
  '/login',
  '/register',
  '/forgot-password',
  '/assistant-select',
};

/// Auth күйі өзгергенде router-ді жаңартатын көпір.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authProvider.select((s) => s.isAuthenticated), (_, _) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authed = ref.read(authProvider).isAuthenticated;
      final public = _publicPaths.contains(state.matchedLocation);
      // Сеанс жоқ болса — қорғалған беттерден Welcome-ге.
      if (!authed && !public) return '/welcome';
      return null;
    },
    routes: [
      // ---- Аутентификация ағыны ----
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/assistant-select',
        builder: (_, _) => const AssistantSelectScreen(),
      ),

      // ---- Негізгі shell: 5 таб (IndexedStack — таб күйі сақталады) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _MainShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/rating', builder: (_, _) => const RatingScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/learn',
              builder: (_, _) => const SubjectSelectScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/shop', builder: (_, _) => const ShopScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ---- Shell үстінен ашылатын толық экрандар ----
      GoRoute(
        path: '/learn/map/:subjectId',
        builder: (_, state) =>
            LearningMapScreen(subjectId: state.pathParameters['subjectId']!),
      ),
      GoRoute(
        path: '/learn/task/:nodeId',
        builder: (_, state) =>
            TaskScreen(nodeId: state.pathParameters['nodeId']!),
      ),
      GoRoute(
        path: '/learn/result',
        builder: (_, state) {
          final extra = state.extra as ({String nodeId, TaskResult result});
          return ResultScreen(nodeId: extra.nodeId, result: extra.result);
        },
      ),
      GoRoute(path: '/friends', builder: (_, _) => const FriendsScreen()),
      GoRoute(
        path: '/battle-setup',
        builder: (_, _) => const BattleSetupScreen(),
      ),
      GoRoute(path: '/battle', builder: (_, _) => const BattleScreen()),
      GoRoute(
        path: '/battle-result',
        builder: (_, _) => const BattleResultScreen(),
      ),
      GoRoute(
        path: '/tournament',
        builder: (_, _) => const TournamentScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});

/// Таб табы + свайп drawer-і бар негізгі қаңқа.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      drawerEdgeDragWidth: 40,
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: AppTabBar(
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
