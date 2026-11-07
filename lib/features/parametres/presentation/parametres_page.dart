import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/motion.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../maitre/presentation/ai_paths.dart';
import '../../sauvegarde/presentation/backup_paths.dart';
import 'appearance_controller.dart';

class ParametresPage extends ConsumerWidget {
  const ParametresPage({super.key});

  void _report(BuildContext context, bool saved) {
    if (!saved && context.mounted) {
      showDruideToast(
        context,
        'Réglage appliqué, mais impossible de l\'enregistrer.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);

    return PageFrame(
      title: AppSection.parametres.label,
      children: [
        const SectionTitle('Professeur IA'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                'Fournisseur, modèle, clé et limites de Maître And-Droiīd.',
                style: context.text.bodyMedium,
              ),
              ArcaneButton(
                label: 'Réglages du Maître',
                icon: Icons.tune,
                secondary: true,
                onPressed: () => context.go(aiSettingsPath),
              ),
            ],
          ),
        ),
        const SectionTitle('Apparence'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thème', style: context.text.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Système'),
                  ),
                ],
                selected: {appearance.themeMode},
                onSelectionChanged: (selection) async {
                  final saved = await controller.setThemeMode(selection.single);
                  if (context.mounted) _report(context, saved);
                },
              ),
              const SizedBox(height: 16),
              Text('Animations', style: context.text.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<MotionLevel>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: MotionLevel.full, label: Text('Toutes')),
                  ButtonSegment(
                    value: MotionLevel.reduced,
                    label: Text('Réduites'),
                  ),
                  ButtonSegment(value: MotionLevel.none, label: Text('Aucune')),
                ],
                selected: {appearance.motion},
                onSelectionChanged: (selection) async {
                  final saved = await controller.setMotion(selection.single);
                  if (context.mounted) _report(context, saved);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'La réduction des animations demandée par votre système est '
                'toujours respectée.',
                style: context.text.bodySmall!.copyWith(
                  color: context.techno.muted,
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Sauvegardes'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                'Exporter, restaurer et retrouver vos copies de sécurité.',
                style: context.text.bodyMedium,
              ),
              ArcaneButton(
                label: 'Sauvegardes',
                icon: Icons.save_outlined,
                secondary: true,
                onPressed: () => context.go(backupPath),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
