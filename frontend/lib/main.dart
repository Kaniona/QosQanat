import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'navigation/app_router.dart';
import 'services/local_storage_service.dart';
import 'services/mock_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalStorageService.instance.init();
    await MockDataService.instance.seedMockData();
  } catch (e) {
    runApp(_BootErrorApp(message: '$e'));
    return;
  }
  runApp(const ProviderScope(child: QosQanatApp()));
}

class QosQanatApp extends ConsumerWidget {
  const QosQanatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

/// Қойма ашылмай қалса көрсетілетін қауіпсіз экран.
class _BootErrorApp extends StatelessWidget {
  const _BootErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.dawnBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.dangerCoral),
                const SizedBox(height: 16),
                Text(AppStrings.error, style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
