import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/clock.dart';
import '../../../design_system/adaptive_grid.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/rune_badge.dart';
import '../../../design_system/stat_tile.dart';
import '../../../design_system/techno_card.dart';
import '../../../design_system/xp_bar.dart';
import '../../academie/domain/module_catalog.dart';
import '../../academie/presentation/paths.dart';
import '../data/gamification_repository.dart';
import '../domain/badges.dart';
import '../domain/certificates.dart';
import '../domain/challenges.dart';
import '../domain/learner_stats.dart';
import '../domain/learning_paths.dart';
import '../domain/progression.dart';
import 'progression_paths.dart';
import 'reward_toast.dart';

class ProgressionPage extends ConsumerStatefulWidget {
  const ProgressionPage({super.key});

  @override
  ConsumerState<ProgressionPage> createState() => _ProgressionPageState();
}

class _ProgressionPageState extends ConsumerState<ProgressionPage> {
  LearningPath? _path;
  int _goal = defaultWeeklyGoal;

  GamificationRepository get _repository =>
      ref.read(gamificationRepositoryProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final path = await _repository.path();
    final goal = await _repository.weeklyGoal();
    if (!mounted) return;
    setState(() {
      _path = path;
      _goal = goal;
    });
    await rewardAndCelebrate(context, ref);
  }

  Future<void> _claim(Challenge challenge) async {
    final earned = await _repository.claim(challenge);
    if (earned > 0 && mounted) showDruideToast(context, '+$earned XP gagnés !');
    if (mounted) await rewardAndCelebrate(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final statsValue = ref.watch(learnerStatsProvider);
    final catalog = ref.watch(learningCatalogProvider).value;
    final stats = statsValue.value ?? const LearnerStats();
    final now = ref.watch(clockProvider)();
    final rank = Rank.forXp(stats.xp);
    final techno = context.techno;

    return PageFrame(
      title: AppSection.progression.label,
      children: [
        if (statsValue.hasError)
          const ErrorNotice(message: 'Impossible de lire votre progression.'),
        TechnoCard(
          accent: techno.emeraude,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Votre grade', style: context.text.bodyMedium),
              Text(rank.title, style: context.text.headlineSmall),
              const SizedBox(height: 12),
              XpBar(
                xp: stats.xp,
                floor: rank.minXp,
                ceiling: rank.next?.minXp ?? rank.minXp,
              ),
            ],
          ),
        ),
        const SectionTitle('Objectif de la semaine'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                '${lessonsThisWeek(stats, now)} leçons sur $_goal cette semaine',
                style: context.text.titleSmall,
              ),
              Slider(
                value: _goal.toDouble(),
                min: 1,
                max: 14,
                divisions: 13,
                label: '$_goal',
                onChanged: (value) => setState(() => _goal = value.round()),
                onChangeEnd: (value) =>
                    _repository.setWeeklyGoal(value.round()),
              ),
            ],
          ),
        ),
        const SectionTitle('Mon parcours'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              DropdownButtonFormField<LearningPath>(
                key: ValueKey(_path),
                initialValue: _path,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Votre objectif',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final path in LearningPath.values)
                    DropdownMenuItem(value: path, child: Text(path.label)),
                ],
                onChanged: (path) {
                  if (path == null) return;
                  setState(() => _path = path);
                  _repository.setPath(path);
                },
              ),
              if (_path case final path? when catalog != null)
                _PathStep(path: path, stats: stats, catalog: catalog),
            ],
          ),
        ),
        const SectionTitle('Défis'),
        for (final challenge in challengesFor(now))
          _ChallengeTile(
            challenge: challenge,
            stats: stats,
            now: now,
            onClaim: () => _claim(challenge),
          ),
        const SectionTitle('Statistiques'),
        AdaptiveGrid(
          minItemWidth: 140,
          maxColumns: 4,
          children: [
            StatTile(
              icon: Icons.bolt,
              value: '${stats.xp}',
              label: 'Points d\'expérience',
            ),
            StatTile(
              icon: Icons.task_alt,
              value: '${stats.completedLessons.length}',
              label: 'Leçons terminées',
            ),
            StatTile(
              icon: Icons.quiz_outlined,
              value: '${stats.passedQuizzes.length}',
              label: 'Quiz réussis',
            ),
            StatTile(
              icon: Icons.edit_note,
              value: '${stats.exercisesDone}',
              label: 'Exercices réussis',
            ),
            StatTile(
              icon: Icons.science_outlined,
              value: '${stats.labSolved.length}',
              label: 'Exercices du Lab',
            ),
            StatTile(
              icon: Icons.construction,
              value: '${stats.projectsDone.length}',
              label: 'Projets terminés',
            ),
            StatTile(
              icon: Icons.pest_control,
              value: '${stats.bugsVerified.length}',
              label: 'Bugs vérifiés',
            ),
            StatTile(
              icon: Icons.local_fire_department,
              value: '${stats.streak(now)}',
              label: 'Jours de suite',
            ),
          ],
        ),
        if (catalog != null) ...[
          const SectionTitle('Avancement par module'),
          TechnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (final module in academyModules)
                  _ModuleLine(module, stats: stats, catalog: catalog),
              ],
            ),
          ),
          const SectionTitle('Certificats internes'),
          _Certificates(certificatesFor(stats, catalog)),
        ],
        const SectionTitle('Badges'),
        AdaptiveGrid(
          minItemWidth: 130,
          maxColumns: 4,
          children: [
            for (final badge in badges)
              Tooltip(
                message: badge.description,
                child: RuneBadge(
                  icon: badge.icon,
                  label: badge.title,
                  caption: badge.description,
                  unlocked: stats.badges.containsKey(badge.id),
                ),
              ),
          ],
        ),
        const SectionTitle('Les huit grades'),
        AdaptiveGrid(
          minItemWidth: 130,
          maxColumns: 4,
          children: [
            for (final grade in Rank.values)
              RuneBadge(
                icon: grade.icon,
                label: grade.title,
                caption: '${grade.minXp} XP',
                unlocked: stats.xp >= grade.minXp,
              ),
          ],
        ),
        ArcaneButton(
          label: 'Voir l\'historique',
          icon: Icons.history,
          secondary: true,
          onPressed: () => context.go(progressionHistoryPath),
        ),
      ],
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.path,
    required this.stats,
    required this.catalog,
  });

  final LearningPath path;
  final LearnerStats stats;
  final LearningCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final next = nextLesson(
      path,
      catalog.lessonsByModule,
      stats.completedLessons,
    );
    if (next == null) {
      return Text('Parcours terminé, bravo !', style: context.text.titleSmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          'Prochaine étape : ${catalog.lessonTitles[next.lessonId]}',
          style: context.text.bodyMedium,
        ),
        ArcaneButton(
          label: 'Continuer',
          icon: Icons.arrow_forward,
          onPressed: () => context.go(lessonPath(next.moduleId, next.lessonId)),
        ),
      ],
    );
  }
}

class _ChallengeTile extends ConsumerWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.stats,
    required this.now,
    required this.onClaim,
  });

  final Challenge challenge;
  final LearnerStats stats;
  final DateTime now;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = challengeProgress(challenge, stats, now);
    final claimed = stats.xpEvents.any(
      (event) => event.source == challengeSource(challenge, now),
    );
    final ready = done >= challenge.count;
    final period = challenge.period == ChallengePeriod.day
        ? 'Aujourd\'hui'
        : 'Cette semaine';

    return TechnoCard(
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.title, style: context.text.titleSmall),
                Text(
                  '$period · ${done.clamp(0, challenge.count)} sur '
                  '${challenge.count} · ${challenge.xp} XP',
                  style: context.text.bodySmall!.copyWith(
                    color: context.techno.muted,
                  ),
                ),
              ],
            ),
          ),
          if (claimed)
            Icon(Icons.check_circle, color: context.techno.emeraude)
          else if (ready)
            FilledButton(onPressed: onClaim, child: const Text('Réclamer')),
        ],
      ),
    );
  }
}

class _ModuleLine extends StatelessWidget {
  const _ModuleLine(this.module, {required this.stats, required this.catalog});

  final AcademyModule module;
  final LearnerStats stats;
  final LearningCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final lessons = catalog.lessonsByModule[module.id] ?? const <String>[];
    final done = lessons.where(stats.completedLessons.contains).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(
          '${module.title} : $done sur ${lessons.length}',
          style: context.text.bodyMedium,
        ),
        LinearProgressIndicator(
          value: lessons.isEmpty ? 0 : done / lessons.length,
        ),
      ],
    );
  }
}

class _Certificates extends StatelessWidget {
  const _Certificates(this.certificates);

  final List<Certificate> certificates;

  @override
  Widget build(BuildContext context) {
    if (certificates.isEmpty) {
      return Text(
        'Terminez un module et son évaluation pour obtenir un certificat '
        'interne.',
        style: context.text.bodyMedium!.copyWith(color: context.techno.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (final certificate in certificates)
          InkWell(
            onTap: () => context.go(certificatePath(certificate.id)),
            child: TechnoCard(
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.workspace_premium, color: context.techno.orange),
                  Expanded(
                    child: Text(
                      certificate.title,
                      style: context.text.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
