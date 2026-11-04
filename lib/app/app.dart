import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/motion.dart';
import '../features/parametres/presentation/appearance_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

const appTitle = 'Druide And-Droiīd';

class DruideApp extends ConsumerWidget {
  const DruideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);

    return MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appearance.themeMode,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final level = media.disableAnimations
            ? MotionLevel.none
            : appearance.motion;

        return MotionScope(
          level: level,
          child: MediaQuery(
            data: media.copyWith(disableAnimations: level == MotionLevel.none),
            child: child!,
          ),
        );
      },
    );
  }
}
