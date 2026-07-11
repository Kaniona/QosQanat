import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/curriculum.dart';
import '../../data/lessons/math_lessons.dart';
import '../../models/enums.dart';
import '../../models/mastery.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/mastery_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/avatar/avatar_base.dart';
import '../../widgets/game/map_overlays.dart';
import '../../widgets/game/map_scenery.dart';
import '../../widgets/game/node_widget.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/mastery_heatmap.dart';
import '../../widgets/ui/stat_label.dart';

/// Оқу картасы — Duolingo-таза тік ирек жол (төменнен жоғары): тыныш бір
/// реңкті фон, ЕШҚАНДАЙ шашыраңқы декор жоқ — көз тек жолда. Ірі жалпақ
/// 3D түймелер жайлап ирелеңдейді; сынып/модуль белдеулері толық енді
/// панельдер. Ағымдағы node сәл ірі + алтын пульс + «Бастау» көпіршігі +
/// қасында тірі серік-маскот. 1-сыныптан оқушының ӨЗ сыныбына дейін ашық;
/// header-де өз сыныптың прогресі; скролл позициясы пән бойынша сақталады.
class LearningMapScreen extends ConsumerStatefulWidget {
  const LearningMapScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<LearningMapScreen> createState() => _LearningMapScreenState();
}

class _LearningMapScreenState extends ConsumerState<LearningMapScreen>
    with SingleTickerProviderStateMixin {
  static const _itemHeight = 108.0;
  static const _waveAmplitude = 62.0;
  static const _waveStep = .85;

  /// Пән бойынша сақталған скролл позициясы (қайта кіргенде сол жерден).
  static final Map<String, double> _savedOffsets = {};

  late final ScrollController _scrollController;

  /// Фон сахнасының (аврора/жұлдыз) дрейф контроллері.
  late final AnimationController _driftController;

  /// Ағымдағы node экраннан тыс қалғанда «Жалғастыру» түймесін көрсету.
  bool _showJump = false;

  /// Ағымдағы node-тың скролл-позициясы (түймемен соған қайтамыз).
  double _currentTarget = 0;

  /// Node аяқтау салтанаты: картаға оралғанда ЖАҢА аяқталған түйін пайда
  /// болса — конфетти атылады. [_seenDone] — бұған дейін аяқталған деп
  /// «көрілген» түйіндер; [_seededDone] алғашқы құрылыста тізімді себеді
  /// (бұрыннан аяқталғандарға салтанат жоқ).
  late final ConfettiController _confetti;
  final Set<String> _seenDone = {};
  bool _seededDone = false;

  /// Конфетти сәтінде серік-маскот та қуанады (celebrate көз ^ ^).
  bool _celebrateMascot = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 1400),
    );
    _scrollController = ScrollController(
      initialScrollOffset: _savedOffsets[widget.subjectId] ?? _currentOffset(),
    );
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      _savedOffsets[widget.subjectId] = _scrollController.offset;
      // Ағымдағы node көру аймағынан ~бір экран алыстаса — түймені көрсет.
      final show = (_scrollController.offset - _currentTarget).abs() > 300;
      if (show != _showJump) setState(() => _showJump = show);
    });
    // Фон авроралары мен жұлдыздардың баяу дрейфі (12с жіксіз цикл).
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  /// Алғаш ашқанда — ағымдағы node шамамен экран ортасында тұрсын.
  double _currentOffset() {
    final views = ref.read(taskProvider(widget.subjectId).notifier).nodeViews();
    final items = _buildItems(views);
    final index = items.indexWhere((it) => it.view?.isCurrent ?? false);
    if (index <= 2) return 0;
    return index * _itemHeight - 260;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _driftController.dispose();
    _confetti.dispose();
    super.dispose();
  }

  /// Тізім (индекс 0 = ең төмен): сынып банері → модуль бөлгіші → node-тар.
  /// Банер/бөлгіш прогрес көрсетеді — әр модульдің/сыныптың аяқталу үлесі
  /// алдын ала есептеледі (саяхат картасындағы «тарау» сезімі).
  List<_MapItem> _buildItems(List<NodeView> views) {
    bool isDone(NodeView v) =>
        v.status == NodeStatus.completed || v.status == NodeStatus.mastered;

    // Әр (сынып·модуль) және сынып бойынша done/total санын алдын ала жинау.
    final modDone = <String, int>{};
    final modTotal = <String, int>{};
    final gradeDone = <int, int>{};
    final gradeTotal = <int, int>{};
    for (final v in views) {
      final key = '${v.node.grade}-${v.node.module}';
      modTotal[key] = (modTotal[key] ?? 0) + 1;
      gradeTotal[v.node.grade] = (gradeTotal[v.node.grade] ?? 0) + 1;
      if (isDone(v)) {
        modDone[key] = (modDone[key] ?? 0) + 1;
        gradeDone[v.node.grade] = (gradeDone[v.node.grade] ?? 0) + 1;
      }
    }

    final items = <_MapItem>[];
    var lastGrade = 0;
    var lastModule = 0;
    var nodeIndex = 0;
    for (final view in views) {
      final g = view.node.grade;
      if (g != lastGrade) {
        lastGrade = g;
        lastModule = 0;
        final gt = gradeTotal[g] ?? 0;
        items.add(_MapItem.gradeBanner(g, gt > 0 && (gradeDone[g] ?? 0) == gt));
      }
      if (view.node.module != lastModule) {
        lastModule = view.node.module;
        final key = '$g-${view.node.module}';
        items.add(
          _MapItem.divider(
            view.node.module,
            view.node.moduleTitle,
            modDone[key] ?? 0,
            modTotal[key] ?? 0,
          ),
        );
      }
      items.add(_MapItem.node(view, nodeIndex++));
    }
    // Жолдың ең жоғарысы: КЕЛЕСІ сыныптың жабық қақпасы — «алда әлі биіктік
    // бар» деген аспирациялық тартылыс (Duolingo-ның жабық юниті іспетті).
    if (views.isNotEmpty && views.last.node.grade < 11) {
      items.add(_MapItem.teaser(views.last.node.grade + 1));
    }
    return items;
  }

  double _xFor(int nodeIndex) => sin(nodeIndex * _waveStep) * _waveAmplitude;

  @override
  Widget build(BuildContext context) {
    final subject = CurriculumData.subjectById(widget.subjectId);
    final notifier = ref.watch(taskProvider(widget.subjectId).notifier);
    ref.watch(taskProvider(widget.subjectId)); // прогресс өзгерісін тыңдау
    final animationsOn = ref.watch(
      settingsProvider.select((s) => s.animationsOn),
    );
    final streak = ref.watch(gameProvider.select((g) => g.currentStreak));

    // Оқушының серігі — маскот ағымдағы түйіннің қасында «тұрады».
    final assistant =
        ref.watch(currentUserProvider.select((u) => u?.assistantType)) ??
        AssistantType.bektur;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (animationsOn && !_driftController.isAnimating) {
      _driftController.repeat();
    } else if (!animationsOn && _driftController.isAnimating) {
      _driftController.stop();
    }

    final views = notifier.nodeViews();
    final userGrade = notifier.currentGradeLevel;

    // Бос күй: бұл пәнде әлі бірде-бір түйін болмаса — премиум EmptyState
    // (фон әлемі сақталады, header «артқа» түймесімен).
    if (views.isEmpty) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: MapScenery(
                subjectId: widget.subjectId,
                accent: subject.accent,
                scrollOffset: 0,
                t: 0,
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: EmptyState(
                  icon: subject.icon,
                  title: AppStrings.mapEmptyTitle,
                  subtitle: AppStrings.mapEmptySubtitle,
                  accent: subject.accent,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _MapHeader(
                subject: subject,
                userGrade: userGrade,
                doneCount: 0,
                totalCount: 0,
                streak: streak,
                onBack: () => context.pop(),
              ),
            ),
          ],
        ),
      );
    }

    // Header прогресі — оқушының ӨЗ сыныбы бойынша.
    final ownGrade = views.where((v) => v.node.grade == userGrade);
    final ownDone = ownGrade
        .where(
          (v) =>
              v.status == NodeStatus.completed ||
              v.status == NodeStatus.mastered,
        )
        .length;
    final items = _buildItems(views);
    final journey = buildJourney(views);
    final currentIndex = items.indexWhere((it) => it.view?.isCurrent ?? false);
    final currentView = currentIndex >= 0 ? items[currentIndex].view : null;
    _currentTarget = currentIndex <= 2 ? 0 : currentIndex * _itemHeight - 260;
    final headerHeight = MediaQuery.paddingOf(context).top + 96;

    // Картаға оралғанда ЖАҢА аяқталған түйін пайда болса — салтанат (confetti).
    final doneIds = {
      for (final v in views)
        if (v.status == NodeStatus.completed || v.status == NodeStatus.mastered)
          v.node.id,
    };
    if (!_seededDone) {
      _seenDone.addAll(doneIds);
      _seededDone = true;
    } else if (doneIds.length > _seenDone.length) {
      _seenDone.addAll(doneIds);
      if (animationsOn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _confetti.play();
          AppHaptics.heavy();
          // Маскот конфеттимен бірге қуанып, сәлден соң қалпына келеді.
          setState(() => _celebrateMascot = true);
          Future.delayed(const Duration(milliseconds: 1900), () {
            if (mounted) setState(() => _celebrateMascot = false);
          });
        });
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Фон: әлемдік деңгейдегі аврора-пейзаж — дуотон аспан, жұмсақ
            // жарық орбтары, паралакс тұман-жоталар (+ қараңғыда жұлдыздар).
            // Скролл мен дрейфке ілесіп «тірі» жүреді, бірақ түйіндермен
            // таласпайды — көз жолда қалады.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _driftController,
                  _scrollController,
                ]),
                builder: (context, _) => MapScenery(
                  subjectId: widget.subjectId,
                  accent: subject.accent,
                  scrollOffset: _scrollController.hasClients
                      ? _scrollController.offset
                      : _scrollController.initialScrollOffset,
                  t: animationsOn ? _driftController.value : 0,
                ),
              ),
            ),
            // Жол + node-тар: reverse тізім — төменнен жоғары өседі.
            ListView.builder(
              controller: _scrollController,
              reverse: true,
              // Clip.none — 2x ағымдағы node мен «Бастау» көпіршігі қиылмай,
              // толық көрінеді (жабысқақ header оларды үстінен жабады).
              clipBehavior: Clip.none,
              padding: EdgeInsets.only(top: headerHeight + 16, bottom: 64),
              itemCount: items.length,
              itemExtent: _itemHeight,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.kind == _ItemKind.gradeBanner) {
                  return _GradeBand(grade: item.grade!, mastered: item.mastered);
                }
                if (item.kind == _ItemKind.teaser) {
                  return _NextGradeTeaser(grade: item.grade!);
                }
                if (item.kind == _ItemKind.moduleDivider) {
                  return _ModuleBand(
                    module: item.module!,
                    title: item.moduleTitle!,
                    accent: subject.accent,
                    done: item.doneCount,
                    total: item.totalCount,
                  );
                }
                final view = item.view!;
                final x = _xFor(item.nodeIndex!);
                // Түйін + серіктері — коннекторсыз таза ирек (Duolingo).
                return Center(
                  child: Transform.translate(
                    offset: Offset(x, 0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          scale: view.isCurrent ? 1.18 : 1.0,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          child: NodeWidget(
                            view: view,
                            accent: subject.accent,
                            animationsOn: animationsOn,
                            onTap: () => _onNodeTap(view),
                          ),
                        ),
                        // Ағымдағы node үстінде «Бастау» көпіршігі — Duolingo
                        // стиліндегі айқын бағдар: «осында тұрсың, осыдан баста».
                        if (view.isCurrent)
                          Positioned(
                            top: -40,
                            child: _StartBubble(animationsOn: animationsOn),
                          ),
                        // Серік-маскот (Бектұр/Назым балапаны) ағымдағы түйіннің
                        // қасында ТҰРАДЫ — тыныс алады, жыпылықтайды: «мен де
                        // осы жолдамын, бірге жүреміз» сезімі. Түйін оңда болса
                        // маскот солда (ортаға қарай) — экраннан шықпайды.
                        if (view.isCurrent)
                          Positioned(
                            left: x >= 0 ? null : 96,
                            right: x >= 0 ? 96 : null,
                            bottom: -4,
                            child: _CompanionOnPath(
                              assistant: assistant,
                              animationsOn: animationsOn,
                              celebrate: _celebrateMascot,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Жоғарғы оң жақ: шолу (саяхат картасы) + белгілер түймелері.
            Positioned(
              top: headerHeight + AppSpacing.sp2,
              right: AppSpacing.sp4,
              child: MapControls(
                accent: subject.accent,
                onOverview: _openOverview,
                onLegend: _openLegend,
              ),
            ),
            // Оң жиектегі сынып секіру рейлі (вертикаль ортада).
            Positioned(
              right: 6,
              top: headerHeight + AppSpacing.sp10,
              bottom: 132,
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: 1,
                child: GradeJumpRail(
                  grades: journey,
                  currentGrade: userGrade,
                  accent: subject.accent,
                  onJump: _jumpTo,
                ),
              ),
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
                streak: streak,
                onBack: () => context.pop(),
              ),
            ),
            // Тұрақты «Жалғастыру» жолағы (thumb-zone, Duolingo үлгісі) —
            // бала ӘРҚАШАН келесі тапсырманы бір рет басып бастай алады, әрі
            // «📍» түймесімен өз орнына скролл жасайды. Ең айқын келесі қадам.
            if (currentView != null)
              Positioned(
                left: AppSpacing.sp5,
                right: AppSpacing.sp5,
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sp4,
                child:
                    _ContinueBar(
                          view: currentView,
                          accent: subject.accent,
                          offScreen: _showJump,
                          onContinue: () => _onNodeTap(currentView),
                          onLocate: _jumpToCurrent,
                        )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: .4, curve: Curves.easeOutBack),
              ),
            // Node аяқтау салтанаты — экран жоғарысынан атылатын конфетти
            // (картаға оралғанда жаңа түйін аяқталса). IgnorePointer — түртуді
            // бөгемейді; анимация өшік болса ешқашан ойналмайды.
            IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -.25),
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 24,
                  maxBlastForce: 18,
                  minBlastForce: 6,
                  gravity: .25,
                  emissionFrequency: .04,
                  colors: const [
                    AppColors.steppeGold,
                    AppColors.goldBright,
                    AppColors.eagleBlue,
                    AppColors.cosmicPurple,
                    AppColors.successJade,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ағымдағы node-қа тегіс скролл (жұмсақ haptic-пен).
  void _jumpToCurrent() {
    if (!_scrollController.hasClients) return;
    AppHaptics.tap();
    final target = _currentTarget.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  /// Берілген сынып банеріне (немесе нақты модульдің бірінші түйініне) секіру.
  void _jumpTo(int grade, int? module) {
    if (!_scrollController.hasClients) return;
    AppHaptics.tap();
    final views = ref.read(taskProvider(widget.subjectId).notifier).nodeViews();
    final items = _buildItems(views);
    final idx = module == null
        ? items.indexWhere(
            (it) => it.kind == _ItemKind.gradeBanner && it.grade == grade,
          )
        : items.indexWhere(
            (it) =>
                it.kind == _ItemKind.node &&
                it.view!.node.grade == grade &&
                it.view!.node.module == module,
          );
    if (idx < 0) return;
    final target = (idx * _itemHeight - 260).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  /// Саяхат картасы (overview) парағын ашу.
  void _openOverview() {
    AppHaptics.tap();
    final notifier = ref.read(taskProvider(widget.subjectId).notifier);
    final views = notifier.nodeViews();
    final subject = CurriculumData.subjectById(widget.subjectId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JourneyOverviewSheet(
        journey: buildJourney(views),
        userGrade: notifier.currentGradeLevel,
        subjectTitle: subject.title,
        accent: subject.accent,
        onJump: (grade, module) {
          Navigator.pop(context);
          _jumpTo(grade, module);
        },
      ),
    );
  }

  /// Белгілер (legend) парағын ашу.
  void _openLegend() {
    AppHaptics.tap();
    final subject = CurriculumData.subjectById(widget.subjectId);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => MapLegendSheet(accent: subject.accent),
    );
  }

  void _onNodeTap(NodeView view) {
    // Реттік ашу: құлыпталған node ашылмайды — алдыңғысын аяқтау керек.
    if (view.status == NodeStatus.locked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.nodeLocked)));
      return;
    }
    final repeat =
        view.status == NodeStatus.completed ||
        view.status == NodeStatus.mastered;
    final subject = CurriculumData.subjectById(widget.subjectId);
    final masteryLevel = ref
        .read(masteryProvider)
        .statFor(
          '${view.node.subject}_g${view.node.grade}_m${view.node.module}',
        )
        ?.level;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _NodePreviewSheet(
        view: view,
        accent: subject.accent,
        repeat: repeat,
        masteryLevel: masteryLevel,
        onStart: () {
          Navigator.pop(sheetContext);
          // «Сабақ» түріндегі node-та теория болса — алдымен ҮЙРЕТЕМІЗ,
          // сосын жаттығу. Қалғаны (босс) — тікелей тест.
          final hasLesson =
              view.node.type == NodeType.lesson &&
              lessonFor(view.node.subject, view.node.grade, view.node.module) !=
                  null;
          context.push(
            '${hasLesson ? '/learn/lesson' : '/learn/task'}/${view.node.id}',
            extra: widget.subjectId,
          );
        },
      ),
    );
  }
}

enum _ItemKind { node, moduleDivider, gradeBanner, teaser }

class _MapItem {
  const _MapItem.node(this.view, this.nodeIndex)
    : kind = _ItemKind.node,
      module = null,
      moduleTitle = null,
      grade = null,
      mastered = false,
      doneCount = 0,
      totalCount = 0;

  const _MapItem.divider(
    this.module,
    this.moduleTitle,
    this.doneCount,
    this.totalCount,
  ) : kind = _ItemKind.moduleDivider,
      view = null,
      nodeIndex = null,
      grade = null,
      mastered = false;

  const _MapItem.gradeBanner(this.grade, this.mastered)
    : kind = _ItemKind.gradeBanner,
      view = null,
      nodeIndex = null,
      module = null,
      moduleTitle = null,
      doneCount = 0,
      totalCount = 0;

  const _MapItem.teaser(this.grade)
    : kind = _ItemKind.teaser,
      view = null,
      nodeIndex = null,
      module = null,
      moduleTitle = null,
      mastered = false,
      doneCount = 0,
      totalCount = 0;

  final _ItemKind kind;
  final NodeView? view;
  final int? nodeIndex;
  final int? module;
  final String? moduleTitle;
  final int? grade;
  final bool mastered;
  final int doneCount;
  final int totalCount;
}

/// Түсті ашықтау/қоюлау (осы файлдың жергілікті көмекшісі).
Color _tone(Color c, double amount) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// Сынып белдеуі — толық енді қою-түн панель: ортада «N-СЫНЫП» алтынмен,
/// екі жағында жіңішке алтын сызықтар. Тыныш әрі салтанатты бөлім белгісі.
/// Сынып толық меңгерілсе — тәж + алтын жиек жарқылы.
class _GradeBand extends StatelessWidget {
  const _GradeBand({required this.grade, this.mastered = false});

  final int grade;
  final bool mastered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sp4,
          horizontal: AppSpacing.sp5,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.cosmicNight,
          borderRadius: AppRadius.rXl,
          border: mastered
              ? Border.all(color: AppColors.goldBright, width: 2)
              : null,
          boxShadow: mastered
              ? AppColors.glow(
                  AppColors.steppeGold,
                  opacity: .45,
                  blur: 20,
                  y: 6,
                )
              : AppColors.sh2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.steppeGold.withValues(alpha: 0),
                      AppColors.steppeGold.withValues(alpha: .6),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            if (mastered) ...[
              const Icon(
                Icons.workspace_premium_rounded,
                size: 20,
                color: AppColors.goldBright,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '$grade-СЫНЫП',
              style: AppTypography.h3.copyWith(
                color: AppColors.steppeGold,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.steppeGold.withValues(alpha: .6),
                      AppColors.steppeGold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Жолдың ең жоғарысындағы ЖАБЫҚ қақпа — келесі сыныптың тизері: құлып +
/// «АЛДА» чипі. Бала жолдың биікке жалғасатынын көріп, ұмтылыс сезеді.
class _NextGradeTeaser extends StatelessWidget {
  const _NextGradeTeaser({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: '$grade${AppStrings.mapGradeSuffix} — ${AppStrings.mapAheadChip}',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sp3,
            horizontal: AppSpacing.sp4,
          ),
          decoration: BoxDecoration(
            color: AppColors.nightInk.withValues(alpha: .5),
            borderRadius: AppRadius.rXl,
            border: Border.all(
              color: AppColors.white.withValues(alpha: .28),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 19,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$grade-СЫНЫП',
                      style: AppTypography.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      AppStrings.mapNextGradeHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: .72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.goldSoar,
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  AppStrings.mapAheadChip,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF7A4A00),
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ағымдағы түйіннің қасында тұрған серік-маскот (Бектұр/Назым балапаны):
/// тірі (тыныс + қалқу + көз жұму), астында жұмсақ жер көлеңкесі. Тек
/// декоратив — семантикадан шығарылған, түртуге кедергі жасамайды.
class _CompanionOnPath extends StatelessWidget {
  const _CompanionOnPath({
    required this.assistant,
    required this.animationsOn,
    this.celebrate = false,
  });

  final AssistantType assistant;
  final bool animationsOn;

  /// Түйін аяқталған салтанатта (конфетти) маскот та қуанады.
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final mascot = ExcludeSemantics(
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarBase(
              assistant: assistant,
              size: 58,
              animate: animationsOn,
              expression: celebrate
                  ? AvatarExpression.celebrate
                  : AvatarExpression.happy,
            ),
            Transform.translate(
              offset: const Offset(0, -5),
              child: Container(
                width: 38,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.nightInk.withValues(alpha: .16),
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(19, 4.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!animationsOn) return mascot;
    // Жеңіл «келіп қону» кіріспесі — экранға оралған сайын жұмсақ пайда болады.
    return mascot
        .animate()
        .fadeIn(duration: 320.ms)
        .slideY(begin: .18, curve: Curves.easeOutBack);
  }
}

/// Модуль белдеуі — Duolingo юнит-банері: толық енді, пәннің акцент түсіне
/// боялған панель. Сол жақта «X-МОДУЛЬ» + тақырып, оң жақта прогресс чипі
/// (аяқталса — галочка). Аяқталған модуль — жасыл (jade).
class _ModuleBand extends StatelessWidget {
  const _ModuleBand({
    required this.module,
    required this.title,
    required this.accent,
    required this.done,
    required this.total,
  });

  final int module;
  final String title;
  final Color accent;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && done == total;
    final base = complete ? AppColors.successJade : accent;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sp3,
          horizontal: AppSpacing.sp5,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, _tone(base, -.14)],
          ),
          borderRadius: AppRadius.rXl,
          boxShadow: AppColors.glow(base, opacity: .3, blur: 14, y: 6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$module-МОДУЛЬ',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: .85),
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            if (complete)
              const Icon(
                Icons.verified_rounded,
                color: AppColors.white,
                size: 26,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .22),
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  '$done/$total',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ағымдағы node үстіндегі «БАСТАУ» көпіршігі — төмен бағытталған құйрығы бар
/// алтын pill, жеңіл секіретін (Duolingo-стиль бағдар белгісі).
class _StartBubble extends StatelessWidget {
  const _StartBubble({required this.animationsOn});

  final bool animationsOn;

  @override
  Widget build(BuildContext context) {
    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: AppColors.goldSoar,
            borderRadius: AppRadius.rFull,
            boxShadow: AppColors.glow(
              AppColors.steppeGold,
              opacity: .5,
              blur: 14,
              y: 4,
            ),
          ),
          child: Text(
            AppStrings.nodeStart.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: const Color(0xFF7A4A00),
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ),
        // Төмен бағытталған құйрық (ромб) — pill-ге жабысып, node-ты нұсқайды.
        Transform.translate(
          offset: const Offset(0, -3),
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: AppColors.goldSoar,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
    if (!animationsOn) return bubble;
    return bubble
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 900.ms, curve: Curves.easeInOut);
  }
}

/// Тұрақты «Жалғастыру» жолағы — экранның төменгі thumb-зонасында ӘРҚАШАН
/// тұратын БІРЕГЕЙ басты әрекет (Duolingo үлгісі): ағымдағы тапсырманы бір
/// басып бастайды. Ағымдағы node экраннан тыс қалса — оң жақта «📍» түймесі
/// сол орынға тегіс скролл жасайды (екеуі — бөлек touch-нысана).
class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.view,
    required this.accent,
    required this.offScreen,
    required this.onContinue,
    required this.onLocate,
  });

  final NodeView view;
  final Color accent;
  final bool offScreen;
  final VoidCallback onContinue;
  final VoidCallback onLocate;

  static Color _shade(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final node = view.node;
    final repeat =
        view.status == NodeStatus.completed ||
        view.status == NodeStatus.mastered;

    return Row(
      children: [
        Expanded(
          child: Pressable(
            onTap: onContinue,
            semanticLabel:
                '${repeat ? AppStrings.nodeRepeat : AppStrings.mapContinue}: '
                '${node.title}',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp3,
                vertical: AppSpacing.sp3,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_shade(accent, .06), _shade(accent, -.16)],
                ),
                borderRadius: AppRadius.rFull,
                boxShadow: AppColors.glow(accent, opacity: .5, blur: 22, y: 8),
              ),
              child: Row(
                children: [
                  // Тапсырма түрінің медальоны (ақ мөлдір дөңгелек ішінде).
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: .22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: .35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      repeat
                          ? Icons.refresh_rounded
                          : NodeWidget.typeIcon(node.type),
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          repeat ? AppStrings.nodeRepeat : AppStrings.mapNext,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white.withValues(alpha: .85),
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                          ),
                        ),
                        Text(
                          node.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  // Айқын «ойнат» белгісі — басты әрекет ишарасы.
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: _shade(accent, -.06),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Ағымдағы node экраннан тыс — «📍» түймесі сол жерге қайтарады.
        if (offScreen) ...[
          const SizedBox(width: AppSpacing.sp2),
          Pressable(
            onTap: onLocate,
            semanticLabel: AppStrings.mapLocate,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppColors.cardShadow,
              ),
              child: Icon(Icons.my_location_rounded, color: accent, size: 24),
            ),
          ),
        ],
      ],
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
    required this.streak,
    required this.onBack,
  });

  final SubjectInfo subject;
  final int userGrade;
  final int doneCount;
  final int totalCount;
  final int streak;
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
        color: AppColors.surface,
        boxShadow: AppColors.sh1,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.back,
            onPressed: onBack,
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 32,
              color: AppColors.ink,
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: subject.accent.withValues(alpha: .16),
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
                    color: AppColors.ink,
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
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.successJade,
                          ),
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
          if (streak > 0) ...[
            const SizedBox(width: AppSpacing.sp2),
            StreakChip(streak: streak),
          ],
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
    this.masteryLevel,
  });

  final NodeView view;
  final Color accent;
  final bool repeat;
  final VoidCallback onStart;
  final MasteryLevel? masteryLevel;

  @override
  Widget build(BuildContext context) {
    final node = view.node;
    final questionCount = node.type == NodeType.treasure
        ? Curriculum.treasureSessionSize
        : Curriculum.sessionSize;
    final color = repeat ? AppColors.successJade : accent;
    final lesson = lessonFor(node.subject, node.grade, node.module);

    // Биіктік шегі (экранның 90%-ы) + скролл: кіші телефондарда мазмұн
    // көп болса (сабақ алдыңғы көрінісі + қиындық + марапат) — overflow
    // болмай, парақ ішінде ыңғайлы скроллданады.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      child: SingleChildScrollView(
        child: Padding(
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
                        Text(
                          node.title,
                          style: AppTypography.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
              const SizedBox(height: AppSpacing.sp4),
              NodeFacts(node: node, questionCount: questionCount),
              if (masteryLevel != null) ...[
                const SizedBox(height: AppSpacing.sp3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp3,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: masteryColor(masteryLevel!).withValues(alpha: .14),
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: masteryColor(masteryLevel!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        masteryLevel!.label,
                        style: AppTypography.caption.copyWith(
                          color: masteryColor(masteryLevel!),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                            : AppColors.border,
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
                  _RewardChip(
                    icon: AppIcons.xp,
                    text: '+${node.xpReward}',
                    bg: AppColors.tintBlue,
                    fg: AppColors.eagleBlue,
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  _RewardChip(
                    icon: AppIcons.coin,
                    text: '+${node.coinReward}',
                    bg: AppColors.tintGold,
                    fg: AppColors.steppeGoldDeep,
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  _RewardChip(
                    icon: AppIcons.akyl,
                    text: '+${node.akylReward}',
                    bg: AppColors.tintPurple,
                    fg: AppColors.cosmicPurple,
                  ),
                ],
              ),
              // Сабақ түріндегі түйінде — «Бұл сабақта үйренесің»: тірек ой,
              // негізгі ереже/формула және үлгі есеп саны (баланы алдын ала
              // бағыттайды, не күтетінін біледі).
              if (node.type == NodeType.lesson && lesson != null) ...[
                const SizedBox(height: AppSpacing.sp4),
                LessonPreview(lesson: lesson),
              ],
              const SizedBox(height: AppSpacing.sp6),
              AppButton(
                label: repeat ? AppStrings.nodeRepeat : AppStrings.nodeStart,
                variant: repeat
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.primary,
                onPressed: onStart,
              ),
              // Осы модульдің теориясы болса — «Теорияны қайталау» (тәжірибе ↔ теория).
              if (lesson != null) ...[
                const SizedBox(height: AppSpacing.sp2),
                AppButton(
                  label: AppStrings.lessonReview,
                  variant: AppButtonVariant.text,
                  icon: Icons.menu_book_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/learn/lesson/${node.id}');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: AppSpacing.sp1,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rFull),
      child: StatLabel(
        icon: icon,
        text: text,
        color: fg,
        iconSize: 15,
        style: AppTypography.caption,
      ),
    );
  }
}
