import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../progression/presentation/reward_toast.dart';
import '../data/project_repository.dart';
import '../domain/final_grid.dart';

class FinalProjectPage extends ConsumerStatefulWidget {
  const FinalProjectPage({super.key});

  @override
  ConsumerState<FinalProjectPage> createState() => _FinalProjectPageState();
}

class _FinalProjectPageState extends ConsumerState<FinalProjectPage> {
  final _scores = {
    for (final criterion in finalCriteria)
      criterion.name: TextEditingController(),
  };
  final _proofs = {
    for (final criterion in finalCriteria)
      criterion.name: TextEditingController(),
  };
  bool _loaded = false;

  @override
  void dispose() {
    for (final controller in [..._scores.values, ..._proofs.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final repository = ref.read(projectRepositoryProvider);
    for (final criterion in finalCriteria) {
      final score = int.tryParse(_scores[criterion.name]!.text.trim()) ?? 0;
      await repository.saveFinal(
        criterion.name,
        score.clamp(0, criterion.maximum),
        _proofs[criterion.name]!.text.trim(),
      );
    }
    if (mounted) {
      showDruideToast(context, 'Grille enregistrée.');
      await rewardAndCelebrate(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(finalEntriesProvider);
    final entries = saved.value ?? const <String, FinalEntry>{};
    if (!_loaded && saved.hasValue) {
      _loaded = true;
      for (final MapEntry(:key, :value) in entries.entries) {
        _scores[key]?.text = '${value.score}';
        _proofs[key]?.text = value.proof;
      }
    }
    final result = evaluateFinal(entries);
    final techno = context.techno;

    return PageFrame(
      title: 'Évaluation finale',
      children: [
        Text(
          'Votre propre application, utile à au moins une personne réelle. '
          'Validation à partir de $finalPassMark points sur 100, avec au moins '
          '$finalMinimumRequired en sécurité et en tests.',
          style: context.text.bodyLarge,
        ),
        const PhaseNotice(
          message:
              'Cette évaluation est une autoévaluation : l\'application calcule '
              'votre total, mais ne contrôle ni votre code ni vos preuves. Une '
              'note sans preuve compte pour zéro. Faites-la relire si possible.',
        ),
        for (final criterion in finalCriteria)
          TechnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(
                  '${criterion.name} (sur ${criterion.maximum})',
                  style: context.text.titleSmall,
                ),
                TextField(
                  controller: _scores[criterion.name],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _proofs[criterion.name],
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Preuve',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ArcaneButton(
          label: 'Enregistrer la grille',
          icon: Icons.save_outlined,
          onPressed: _save,
        ),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Text(
                '${result.total} sur 100',
                style: context.text.headlineSmall,
              ),
              Text(
                result.validated
                    ? 'Validé par autoévaluation.'
                    : 'À reprendre : c\'est une étape, pas un échec.',
                style: context.text.titleSmall!.copyWith(
                  color: result.validated ? techno.emeraude : techno.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
