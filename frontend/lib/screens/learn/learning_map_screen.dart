import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/subject_worlds.dart';
import '../../data/curriculum.dart';
import '../../models/enums.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/game/map_backdrop.dart';
import '../../widgets/game/node_widget.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/oyu_ornament.dart';

/// Оқу картасы — тік синус жол (төменнен жоғары): 1-сыныптан оқушының
/// ӨЗ сыныбына дейінгі материал ашық, жоғарғы сыныптар мүлде көрінбейді.
/// Ағымдағы node (өз сыныбындағы алғашқы аяқталмаған) 2x + пульс.
/// Сынып банерлері мен модуль бөлгіштері ою-өрнекпен, header-де өз
/// сыныптың прогресі, скролл позициясы пән бойынша сақталады.
class LearningMapScreen extends ConsumerStatefulWidget {
  const LearningMapScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<LearningMapScreen> createState() => _LearningMapScreenState();
}

class _LearningMapScreenState extends ConsumerState<LearningMapScreen>
    with SingleTickerProviderStateMixin {
  static const _itemHeight = 116.0;
  static const _waveAmplitude = 64.0;
  static const _waveStep = .85;

  /// Пән бойынша сақталған скролл позициясы (қайта кіргенде сол жерден).
  static final Map<String, double> _savedOffsets = {};

  late final ScrollController _scrollController;

  /// Фон декорының жай дрейфі (бұлт, шар, электрон, сигнал).
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _savedOffsets[widget.subjectId] ?? _currentOffset(),
    );
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _savedOffsets[widget.subjectId] = _scrollController.offset;
      }
    });
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  /// Алғаш ашқанда — ағымдағы node шамамен экран ортасында тұрсын.
  double _currentOffset() {
    final views =
        ref.read(taskProvider(widget.subjectId).notifier).nodeViews();
    final items = _buildItems(views);
    final index = items.indexWhere((it) => it.view?.isCurrent ?? false);
    if (index <= 2) return 0;
    return index * _itemHeight - 260;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  /// Тізім (индекс 0 = ең төмен): сынып банері → модуль бөлгіші → node-тар.
  List<_MapItem> _buildItems(List<NodeView> views) {
    final items = <_MapItem>[];
    var lastGrade = 0;
    var lastModule = 0;
    var nodeIndex = 0;
    for (final view in views) {
      if (view.node.grade != lastGrade) {
        lastGrade = view.node.grade;
        lastModule = 0;
        items.add(_MapItem.gradeBanner(view.node.grade));
      }
      if (view.node.module != lastModule) {
        lastModule = view.node.module;
        items.add(_MapItem.divider(view.node.module, view.node.moduleTitle));
      }
      items.add(_MapItem.node(view, nodeIndex++));
    }
    return items;
  }

  double _xFor(int nodeIndex) => sin(nodeIndex * _waveStep) * _waveAmplitude;

  @override
  Widget build(BuildContext context) {
    final subject = CurriculumData.subjectById(widget.subjectId);
    final notifier = ref.watch(taskProvider(widget.subjectId).notifier);
    ref.watch(taskProvider(widget.subjectId)); // прогресс өзгерісін тыңдау
    final animationsOn =
        ref.watch(settingsProvider.select((s) => s.animationsOn));

    final worldTheme = SubjectWorldTheme.of(widget.subjectId);
    if (animationsOn && !_driftController.isAnimating) {
      _driftController.repeat();
    } else if (!animationsOn && _driftController.isAnimating) {
      _driftController.stop();
    }

    final views = notifier.nodeViews();
    final userGrade = notifier.currentGradeLevel;
    // Header прогресі — оқушының ӨЗ сыныбы бойынша.
    final ownGrade = views.where((v) => v.node.grade == userGrade);
    final ownDone = ownGrade
        .where((v) =>
            v.status == NodeStatus.completed ||
            v.status == NodeStatus.mastered)
        .length;
    final items = _buildItems(views);
    final headerHeight = MediaQuery.paddingOf(context).top + 96;

    return Scaffold(
      body: Stack(
        children: [
          // Фон: пәннің өз әлемі (дала / геометрия / аспан / ғарыш / схема).
          // Скроллға да құлақ асады — декор параллакспен бірге жылжиды.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_driftController, _scrollController]),
              builder: (context, _) => MapBackdrop(
                theme: worldTheme,
                accent: subject.accent,
                t: animationsOn ? _driftController.value : 0,
                scrollOffset: _scrollController.hasClients
                    ? _scrollController.offset
                    : _scrollController.initialScrollOffset,
              ),
            ),
          ),
          // Жол + node-тар: reverse тізім — төменнен жоғары өседі.
          ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: EdgeInsets.only(top: headerHeight + 16, bottom: 64),
            itemCount: items.length,
            itemExtent: _itemHeight,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.kind == _ItemKind.gradeBanner) {
                return _GradeBanner(grade: item.grade!);
              }
              if (item.kind == _ItemKind.moduleDivider) {
                return _ModuleDivider(
                  module: item.module!,
                  title: item.moduleTitle!,
                  accent: subject.accent,
                );
              }
              final view = item.view!;
              final x = _xFor(item.nodeIndex!);
              // Жоғарыдағы келесі node-қа дейінгі қатар саны (арада
              // банер/бөлгіш болса — секіріп өтеміз).
              var rowsToNext = 1;
              var lookup = index + 1;
              while (lookup < items.length &&
                  items[lookup].kind != _ItemKind.node) {
                rowsToNext++;
                lookup++;
              }
              final hasNext = lookup < items.length;
              final nextX = hasNext ? _xFor(item.nodeIndex! + 1) : x;
              final segmentDone =
                  view.status == NodeStatus.completed ||
                      view.status == NodeStatus.mastered;

              return CustomPaint(
                painter: hasNext
                    ? _ConnectorPainter(
                        fromX: x,
                        toX: nextX,
                        rows: rowsToNext,
                        rowHeight: _itemHeight,
                        color: segmentDone
                            ? AppColors.successJade
                            : AppColors.white,
                      )
                    : null,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(x, 0),
                    child: AnimatedScale(
                      scale: view.isCurrent ? 2.0 : 1.0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      child: NodeWidget(
                        view: view,
                        accent: subject.accent,
                        animationsOn: animationsOn,
                        onTap: () => _onNodeTap(view),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Жабысқақ header: ақ фон, сынып + пән + өз сынып прогресі.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MapHeader(
              subject: subject,
              userGrade: userGrade,
              doneCount: ownDone,
              totalCount: ownGrade.length,
              onBack: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _onNodeTap(NodeView view) {
    final repeat = view.status == NodeStatus.completed ||
        view.status == NodeStatus.mastered;
    final subject = CurriculumData.subjectById(widget.subjectId);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _NodePreviewSheet(
        view: view,
        accent: subject.accent,
        repeat: repeat,
        onStart: () {
          Navigator.pop(sheetContext);
          context.push(
            '/learn/task/${view.node.id}',
            extra: widget.subjectId,
          );
        },
      ),
    );
  }
}

enum _ItemKind { node, moduleDivider, gradeBanner }

class _MapItem {
  const _MapItem.node(this.view, this.nodeIndex)
      : kind = _ItemKind.node,
        module = null,
        moduleTitle = null,
        grade = null;

  const _MapItem.divider(this.module, this.moduleTitle)
      : kind = _ItemKind.moduleDivider,
        view = null,
        nodeIndex = null,
        grade = null;

  const _MapItem.gradeBanner(this.grade)
      : kind = _ItemKind.gradeBanner,
        view = null,
        nodeIndex = null,
        module = null,
        moduleTitle = null;

  final _ItemKind kind;
  final NodeView? view;
  final int? nodeIndex;
  final int? module;
  final String? moduleTitle;
  final int? grade;
}

/// Node аралық пунктир жол: төменгі node ортасынан жоғарғыға қарай.
class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({
    required this.fromX,
    required this.toX,
    required this.rows,
    required this.rowHeight,
    required this.color,
  });

  final double fromX;
  final double toX;
  final int rows;
  final double rowHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width / 2 + fromX, size.height / 2);
    final end =
        Offset(size.width / 2 + toX, size.height / 2 - rows * rowHeight);
    final paint = Paint()..color = color;
    const dotRadius = 3.2;
    const gap = 16.0;
    final delta = end - start;
    final count = (delta.distance / gap).floor();
    // Шеткі нүктелер дөңгелектердің астында қалады — арасын ғана саламыз.
    for (var i = 2; i < count - 1; i++) {
      final t = i / count;
      canvas.drawCircle(start + delta * t, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.fromX != fromX ||
      old.toX != toX ||
      old.rows != rows ||
      old.color != color;
}

/// Сынып банері: «5-СЫНЫП» — қою фонды, алтын жиекті, ою белдеулі.
class _GradeBanner extends StatelessWidget {
  const _GradeBanner({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
        decoration: BoxDecoration(
          gradient: AppColors.cosmicNight,
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: AppColors.steppeGold.withValues(alpha: .7),
            width: 1.5,
          ),
          boxShadow: AppColors.sh2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OyuDashBand(opacity: .7),
            const SizedBox(height: AppSpacing.sp2),
            Text(
              '$grade-СЫНЫП',
              style: AppTypography.h3.copyWith(
                color: AppColors.steppeGold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Модуль бөлгіші: ою-өрнекті жеңіл банер.
class _ModuleDivider extends StatelessWidget {
  const _ModuleDivider({
    required this.module,
    required this.title,
    required this.accent,
  });

  final int module;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sp3,
          horizontal: AppSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: accent.withValues(alpha: .35), width: 1.5),
          boxShadow: AppColors.sh1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OyuDivider(opacity: .55),
            const SizedBox(height: AppSpacing.sp1),
            Text(
              '${AppStrings.moduleWord} $module: $title',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.nightInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Жабысқақ header: ақ фон, «8-СЫНЫП · МАТЕМАТИКА», өз сынып прогресі.
class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.subject,
    required this.userGrade,
    required this.doneCount,
    required this.totalCount,
    required this.onBack,
  });

  final SubjectInfo subject;
  final int userGrade;
  final int doneCount;
  final int totalCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + AppSpacing.sp1,
        left: AppSpacing.sp1,
        right: AppSpacing.sp5,
        bottom: AppSpacing.sp3,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: AppColors.sh1,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded,
                size: 32, color: AppColors.nightInk),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: subject.accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(subject.icon, size: 22, color: subject.accent),
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$userGrade-СЫНЫП · ${subject.title.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.nightInk,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp1),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.rFull,
                        child: LinearProgressIndicator(
                          value: totalCount == 0 ? 0 : doneCount / totalCount,
                          minHeight: 8,
                          backgroundColor: AppColors.cloudBorder,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.successJade),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp2),
                    Text(
                      '$doneCount/$totalCount ${AppStrings.mapDone}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.successJade,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Node алдын ала көрінісі: икон, атау, сұрақ саны, марапаттар, Бастау.
class _NodePreviewSheet extends StatelessWidget {
  const _NodePreviewSheet({
    required this.view,
    required this.accent,
    required this.repeat,
    required this.onStart,
  });

  final NodeView view;
  final Color accent;
  final bool repeat;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final node = view.node;
    final questionCount = node.type == NodeType.treasure
        ? Curriculum.treasureSessionSize
        : Curriculum.sessionSize;
    final color = repeat ? AppColors.successJade : accent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sp6,
        AppSpacing.sp5,
        AppSpacing.sp6,
        AppSpacing.sp6 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: .4),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  repeat
                      ? Icons.check_rounded
                      : NodeWidget.typeIcon(node.type),
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.title,
                        style: AppTypography.h3, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${node.grade}${AppStrings.gradeMaterial} · '
                      '$questionCount ${AppStrings.questionWord}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (repeat) ...[
            const SizedBox(height: AppSpacing.sp4),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 26,
                    color: i < view.stars
                        ? AppColors.goldBright
                        : AppColors.cloudBorder,
                  ),
                const SizedBox(width: AppSpacing.sp2),
                Text(
                  '${AppStrings.bestResult}: ${view.stars}/3',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sp4),
          Row(
            children: [
              _RewardChip(text: '+${node.xpReward} ⚡'),
              const SizedBox(width: AppSpacing.sp2),
              _RewardChip(text: '+${node.coinReward} 💰'),
              const SizedBox(width: AppSpacing.sp2),
              _RewardChip(text: '+${node.akylReward} ★'),
            ],
          ),
          const SizedBox(height: AppSpacing.sp6),
          AppButton(
            label: repeat ? AppStrings.nodeRepeat : AppStrings.nodeStart,
            variant:
                repeat ? AppButtonVariant.secondary : AppButtonVariant.primary,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: AppSpacing.sp1,
      ),
      decoration: BoxDecoration(
        color: AppColors.steppeGoldLight,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: AppColors.steppeGoldDeep),
      ),
    );
  }
}
