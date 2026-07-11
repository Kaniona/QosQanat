import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_haptics.dart';
import '../core/utils/app_sounds.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../screens/assistant/assistant_chat_screen.dart';
import '../screens/auth/assistant_select_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/insights/about_screen.dart';
import '../screens/insights/guardian_screen.dart';
import '../screens/insights/progress_screen.dart';
import '../screens/learn/exam_screen.dart';
import '../screens/learn/learning_map_screen.dart';
import '../screens/onboarding/placement_screen.dart';
import '../screens/learn/lesson_screen.dart';
import '../screens/learn/result_screen.dart';
import '../screens/learn/review_session_screen.dart';
import '../screens/learn/subject_select_screen.dart';
import '../screens/learn/daily_challenge_screen.dart';
import '../screens/learn/reference_screen.dart';
import '../screens/learn/task_screen.dart';
import '../screens/learn/ubt_screen.dart';
import '../screens/onboarding/intro_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/rating/rating_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/social/battle_result_screen.dart';
import '../screens/social/battle_screen.dart';
import '../screens/social/battle_setup_screen.dart';
import '../screens/social/friends_screen.dart';
import '../providers/tournament_provider.dart';
import '../screens/tournament/tournament_play_screen.dart';
import '../screens/tournament/tournament_result_screen.dart';
import '../screens/tournament/tournament_screen.dart';
import '../widgets/ui/ambient_backdrop.dart';
import '../widgets/ui/app_drawer.dart';
import '../widgets/ui/app_tab_bar.dart';

/// Кіруді талап етпейтін маршруттар.
const _publicPaths = {
  '/splash',
  '/welcome',
  '/intro',
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

  // Толық экранды маршруттардың премиум ауысуы — «Қозғалыс» баптауы
  // өшірілсе, лезде ауысады (animationsOn-ды бүкіл апп құрметтейді).
  Page<void> page(GoRouterState state, Widget child) => _appPage(
        state,
        child,
        animate: ref.read(settingsProvider).animationsOn,
      );

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
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => page(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (_, state) => page(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: '/intro',
        pageBuilder: (_, state) => page(state, const IntroScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => page(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) => page(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (_, state) => page(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/assistant-select',
        pageBuilder: (_, state) => page(state, const AssistantSelectScreen()),
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
        pageBuilder: (_, state) => page(
          state,
          LearningMapScreen(subjectId: state.pathParameters['subjectId']!),
        ),
      ),
      GoRoute(
        path: '/learn/lesson/:nodeId',
        pageBuilder: (_, state) => page(
          state,
          LessonScreen(nodeId: state.pathParameters['nodeId']!),
        ),
      ),
      GoRoute(
        path: '/learn/task/:nodeId',
        pageBuilder: (_, state) => page(
          state,
          TaskScreen(nodeId: state.pathParameters['nodeId']!),
        ),
      ),
      GoRoute(
        path: '/learn/result',
        pageBuilder: (_, state) {
          final extra = state.extra as ({String nodeId, TaskResult result});
          return page(
            state,
            ResultScreen(nodeId: extra.nodeId, result: extra.result),
          );
        },
      ),
      GoRoute(
        path: '/learn/review',
        pageBuilder: (_, state) => page(state, const ReviewSessionScreen()),
      ),
      GoRoute(
        path: '/learn/exam/:subjectId',
        pageBuilder: (_, state) => page(
          state,
          ExamScreen(subjectId: state.pathParameters['subjectId']!),
        ),
      ),
      GoRoute(
        path: '/learn/ubt',
        pageBuilder: (_, state) => page(state, const UbtScreen()),
      ),
      GoRoute(
        path: '/learn/reference',
        pageBuilder: (_, state) => page(state, const ReferenceScreen()),
      ),
      GoRoute(
        path: '/daily',
        pageBuilder: (_, state) => page(state, const DailyChallengeScreen()),
      ),
      GoRoute(
        path: '/placement',
        pageBuilder: (_, state) => page(state, const PlacementScreen()),
      ),
      GoRoute(
        path: '/friends',
        pageBuilder: (_, state) => page(state, const FriendsScreen()),
      ),
      GoRoute(
        path: '/battle-setup',
        pageBuilder: (_, state) => page(state, const BattleSetupScreen()),
      ),
      GoRoute(
        path: '/battle',
        pageBuilder: (_, state) => page(state, const BattleScreen()),
      ),
      GoRoute(
        path: '/battle-result',
        pageBuilder: (_, state) => page(state, const BattleResultScreen()),
      ),
      GoRoute(
        path: '/tournament',
        pageBuilder: (_, state) => page(state, const TournamentScreen()),
      ),
      GoRoute(
        path: '/tournament/play/:id',
        pageBuilder: (_, state) => page(
          state,
          TournamentPlayScreen(tournamentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/tournament/result',
        pageBuilder: (_, state) => page(
          state,
          TournamentResultScreen(result: state.extra as TournamentResult),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => page(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/assistant',
        pageBuilder: (_, state) => page(state, const AssistantChatScreen()),
      ),
      GoRoute(
        path: '/guardian',
        pageBuilder: (_, state) => page(state, const GuardianScreen()),
      ),
      GoRoute(
        path: '/progress',
        pageBuilder: (_, state) => page(state, const ProgressScreen()),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (_, state) => page(state, const AboutScreen()),
      ),
    ],
  );
});

/// Премиум бет ауысуы: жұмсақ fade + төменнен сәл жоғары сырғу.
/// [animate] false болса — лезде ауысу (қозғалыс баптауы өшірілген).
Page<void> _appPage(
  GoRouterState state,
  Widget child, {
  required bool animate,
}) {
  if (!animate) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Таб табы + свайп drawer-і бар негізгі қаңқа.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      drawerEdgeDragWidth: 40,
      body: Stack(
        children: [
          // Бүкіл апп бойы нәзік жүзбелі бренд тереңдігі (ең артта).
          const AmbientBackdrop(
            colors: [
              AppColors.eagleBlue,
              AppColors.cosmicPurple,
              AppColors.steppeGold,
            ],
          ),
          SafeArea(bottom: false, child: shell),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        currentIndex: shell.currentIndex,
        onTap: (index) {
          if (index != shell.currentIndex) {
            AppHaptics.tap();
            AppSounds.tap();
          }
          shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          );
        },
      ),
    );
  }
}
