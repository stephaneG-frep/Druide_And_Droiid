import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/gamification_repository.dart';
import '../domain/certificates.dart';
import '../domain/learner_stats.dart';

class CertificatePage extends ConsumerStatefulWidget {
  const CertificatePage({required this.certificateId, super.key});

  final String certificateId;

  @override
  ConsumerState<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends ConsumerState<CertificatePage> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(gamificationRepositoryProvider).learnerName().then((name) {
      if (mounted) _name.text = name;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _date(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(learnerStatsProvider).value ?? const LearnerStats();
    final catalog = ref.watch(learningCatalogProvider).value;
    final certificate = catalog == null
        ? null
        : certificatesFor(
            stats,
            catalog,
          ).where((item) => item.id == widget.certificateId).firstOrNull;

    return PageFrame(
      title: 'Certificat interne',
      children: [
        if (certificate == null)
          Text(
            'Ce certificat n\'est pas encore obtenu.',
            style: context.text.bodyMedium,
          )
        else ...[
          TechnoCard(
            accent: context.techno.orange,
            child: Column(
              spacing: 12,
              children: [
                const MaitreAndDroiid(width: 96),
                Text(
                  'Certificat interne de réussite',
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge,
                ),
                ListenableBuilder(
                  listenable: _name,
                  builder: (context, _) => Text(
                    _name.text.isEmpty ? 'Apprenti' : _name.text,
                    textAlign: TextAlign.center,
                    style: context.text.headlineSmall,
                  ),
                ),
                Text(
                  certificate.title,
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
                Text(
                  certificate.reason,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
                Text(
                  'Obtenu le ${_date(certificate.date)}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Votre nom, affiché sur le certificat',
              border: OutlineInputBorder(),
            ),
            onChanged: ref.read(gamificationRepositoryProvider).setLearnerName,
          ),
          const PhaseNotice(message: certificateDisclaimer),
        ],
      ],
    );
  }
}
