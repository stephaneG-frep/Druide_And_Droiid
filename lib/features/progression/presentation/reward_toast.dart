import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/druide_toast.dart';
import '../data/gamification_repository.dart';

/// Attribue ce qui est dû, puis l'annonce en un seul message.
Future<void> rewardAndCelebrate(BuildContext context, WidgetRef ref) async {
  final report = await settleRewards(ref);
  if (report.isEmpty || !context.mounted) return;
  final parts = [
    if (report.xp > 0) '+${report.xp} XP',
    if (report.rank case final rank?) 'Nouveau grade : ${rank.title}',
    for (final badge in report.badges) 'Badge : ${badge.title}',
  ];
  showDruideToast(context, parts.join(' · '));
}
