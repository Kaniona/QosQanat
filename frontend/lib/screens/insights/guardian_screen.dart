import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/curriculum.dart';
import '../../models/mastery.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mastery_provider.dart';
import '../../widgets/ui/coach_card.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/mastery_heatmap.dart';
import '../../widgets/ui/panels.dart';

/// Ұстаз / ата-ана панелі — PIN-мен қорғалған, офлайн аналитика. Құрылғыдағы
/// оқушылардың шеберлік картасын, әлсіз тұстарын, белсенділігін көрсетеді,
/// тапсырма беруге және есепті бөлісуге мүмкіндік береді.
class GuardianScreen extends ConsumerStatefulWidget {
  const GuardianScreen({super.key});

  @override
  ConsumerState<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends ConsumerState<GuardianScreen> {
  bool _unlocked = false;
  String? _studentId;

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return _PinGate(onUnlock: () => setState(() => _unlocked = true));
    }
    final storage = ref.read(storageProvider);
    final id = _studentId;
    if (id == null) {
      return _Roster(
        onSelect: (uid) => setState(() => _studentId = uid),
      );
    }
    final user = storage.getUser(id);
    if (user == null) {
      return _Roster(onSelect: (uid) => setState(() => _studentId = uid));
    }
    return _StudentDetail(
      user: user,
      onBack: () => setState(() => _studentId = null),
    );
  }
}

// ============================ PIN ============================

class _PinGate extends ConsumerStatefulWidget {
  const _PinGate({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  ConsumerState<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends ConsumerState<_PinGate> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final storage = ref.read(storageProvider);
    final pin = _controller.text.trim();
    if (pin.length != 4) {
      setState(() => _error = AppStrings.guardianPinWrong);
      return;
    }
    final saved = storage.guardianPin;
    if (saved == null) {
      storage.setGuardianPin(pin);
      widget.onUnlock();
    } else if (saved == pin) {
      widget.onUnlock();
    } else {
      setState(() => _error = AppStrings.guardianPinWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = ref.read(storageProvider).guardianPin == null;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.guardianTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 72, color: AppColors.eagleBlue),
            const SizedBox(height: AppSpacing.sp4),
            Text(
              isNew ? AppStrings.guardianPinNew : AppStrings.guardianPinPrompt,
              textAlign: TextAlign.center,
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.sp5),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: AppTypography.h2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                errorText: _error,
                hintText: '••••',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.sp5),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text(AppStrings.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================ Roster ============================

class _Roster extends ConsumerWidget {
  const _Roster({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageProvider);
    final users = storage.getAllUsers();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.guardianRoster)),
      body: users.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.group_rounded,
                title: AppStrings.guardianNoData,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.sp5),
              children: [
                for (final u in users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
                    child: PanelCard(
                      onTap: () => onSelect(u.id),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppColors.eagleBlue.withValues(alpha: .14),
                            child: Text(
                              u.firstName.isEmpty
                                  ? '?'
                                  : u.firstName.characters.first.toUpperCase(),
                              style: AppTypography.h3
                                  .copyWith(color: AppColors.eagleBlue),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sp3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName,
                                    style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w800)),
                                Text('${u.grade}-сынып',
                                    style: AppTypography.caption),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ============================ Student detail ============================

class _StudentDetail extends ConsumerWidget {
  const _StudentDetail({required this.user, required this.onBack});
  final User user;
  final VoidCallback onBack;

  MasterySnapshot _snapshot(WidgetRef ref) {
    final storage = ref.read(storageProvider);
    return MasterySnapshot(
      skills: storage.getAllSkillStats(user.id),
      dueCount: storage.getDueReviews(user.id, DateTime.now()).length,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = _snapshot(ref);
    final practicedSubjects = CurriculumData.subjects
        .where((s) =>
            snap.skillsForSubject(s.id).any((st) => st.attempts > 0))
        .toList();
    final weak = snap.weakSkills.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        title: Text(user.firstName),
        actions: [
          IconButton(
            tooltip: AppStrings.guardianShareReport,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _shareReport(context, snap),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _assignSheet(context, ref),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text(AppStrings.guardianAssign),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sp5, AppSpacing.sp5,
            AppSpacing.sp5, AppSpacing.sp12),
        children: [
          _HeaderCard(user: user, snap: snap),
          const SizedBox(height: AppSpacing.sp5),

          if (practicedSubjects.isEmpty)
            const EmptyState(
              icon: Icons.insights_rounded,
              title: AppStrings.guardianNoData,
            )
          else ...[
            // Әлсіз тақырыптар
            if (weak.isNotEmpty) ...[
              SectionHeader(title: AppStrings.guardianWeakTopics),
              PanelCard(
                child: Column(
                  children: [
                    for (final s in weak)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sp1),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 18, color: AppColors.warningSunset),
                            const SizedBox(width: AppSpacing.sp2),
                            Expanded(
                              child: Text(CoachCard.topicTitle(s.skillId),
                                  style: AppTypography.bodySmall),
                            ),
                            Text('${(s.ema * 100).round()}%',
                                style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warningSunset)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sp5),
            ],

            // Пән бойынша шеберлік карталары
            for (final subject in practicedSubjects) ...[
              SectionHeader(title: subject.title),
              PanelCard(
                child: MasteryHeatmap(
                  subjectId: subject.id,
                  grade: user.grade,
                  snapshot: snap,
                ),
              ),
              const SizedBox(height: AppSpacing.sp5),
            ],
            const MasteryLegend(),
            const SizedBox(height: AppSpacing.sp5),

            // Соңғы белсенділік
            _RecentActivity(userId: user.id),
          ],
        ],
      ),
    );
  }

  void _shareReport(BuildContext context, MasterySnapshot snap) {
    final buf = StringBuffer()
      ..writeln('QosQanat — ${user.fullName} (${user.grade}-сынып)')
      ..writeln(
          '${AppStrings.guardianAccuracy}: ${(snap.overallAccuracy * 100).round()}%')
      ..writeln('${AppStrings.coachReviewReady}: ${snap.dueCount}');
    final weak = snap.weakSkills.take(5).toList();
    if (weak.isNotEmpty) {
      buf.writeln('${AppStrings.guardianWeakTopics}:');
      for (final s in weak) {
        buf.writeln('  • ${CoachCard.topicTitle(s.skillId)} '
            '(${(s.ema * 100).round()}%)');
      }
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.guardianShareReport)),
    );
  }

  void _assignSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AssignSheet(
        grade: user.grade,
        onAssign: (subject, module) async {
          await ref.read(storageProvider).saveAssignment(Assignment(
                studentId: user.id,
                subject: subject,
                grade: user.grade,
                module: module,
                createdAt: DateTime.now(),
              ));
          ref.invalidate(assignmentsProvider);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.guardianAssigned)),
            );
          }
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.user, required this.snap});
  final User user;
  final MasterySnapshot snap;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      gradient: AppColors.heroEagle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.fullName,
              style: AppTypography.h2.copyWith(color: Colors.white)),
          Text('${user.grade}-сынып · ${user.city}',
              style: AppTypography.caption
                  .copyWith(color: Colors.white.withValues(alpha: .85))),
          const SizedBox(height: AppSpacing.sp4),
          Row(
            children: [
              _Stat(
                  label: AppStrings.guardianAccuracy,
                  value: '${(snap.overallAccuracy * 100).round()}%'),
              _Stat(
                  label: AppStrings.coachReviewReady,
                  value: '${snap.dueCount}'),
              _Stat(label: 'Streak', value: '${user.currentStreak}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTypography.h2.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: Colors.white.withValues(alpha: .85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.read(storageProvider).getAllNodeProgress(userId);
    final recent = progress.values
        .where((p) => p.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    if (recent.isEmpty) return const SizedBox.shrink();
    final top = recent.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: AppStrings.guardianActivity),
        PanelCard(
          child: Column(
            children: [
              for (final p in top)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sp1),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18,
                          color: p.stars >= 3
                              ? AppColors.successJade
                              : AppColors.muted),
                      const SizedBox(width: AppSpacing.sp2),
                      Expanded(
                        child: Text(
                          CoachCard.topicTitle(
                              skillIdFromNode(p.nodeId) ?? ''),
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${p.completedAt!.day}.${p.completedAt!.month}',
                          style: AppTypography.caption),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================ Assign sheet ============================

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.grade, required this.onAssign});
  final int grade;
  final void Function(String subject, int module) onAssign;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  String _subject = 'math';

  @override
  Widget build(BuildContext context) {
    final count = Curriculum.moduleCount(_subject, widget.grade);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.sp5, AppSpacing.sp5,
          AppSpacing.sp5, MediaQuery.of(context).viewInsets.bottom + AppSpacing.sp5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.guardianAssign, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sp3),
          Wrap(
            spacing: AppSpacing.sp2,
            children: [
              for (final s in CurriculumData.subjects)
                ChoiceChip(
                  label: Text(s.title),
                  selected: _subject == s.id,
                  onSelected: (_) => setState(() => _subject = s.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp3),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var m = 1; m <= count; m++)
                  ListTile(
                    leading: const Icon(Icons.menu_book_rounded),
                    title: Text(
                      Curriculum.nodeById(
                                  '${skillIdFor(_subject, widget.grade, m)}_n0')
                              ?.moduleTitle ??
                          '$m-модуль',
                    ),
                    onTap: () => widget.onAssign(_subject, m),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
