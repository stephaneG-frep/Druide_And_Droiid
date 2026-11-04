import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/academie/domain/module_catalog.dart';
import '../features/academie/presentation/academie_page.dart';
import '../features/academie/presentation/module_page.dart';
import '../features/accueil/presentation/accueil_page.dart';
import '../features/chaudron/presentation/chaudron_page.dart';
import '../features/grimoire/presentation/grimoire_page.dart';
import '../features/lab/presentation/lab_page.dart';
import '../features/maitre/presentation/maitre_page.dart';
import '../features/parametres/presentation/parametres_page.dart';
import '../features/progression/presentation/progression_page.dart';
import '../features/projets/presentation/projets_page.dart';
import 'sections.dart';
import 'shell/app_shell.dart';
import 'shell/not_found_page.dart';
import 'shell/plus_page.dart';

const plusPath = '/plus';

Widget _pageFor(AppSection section) => switch (section) {
  AppSection.accueil => const AccueilPage(),
  AppSection.academie => const AcademiePage(),
  AppSection.maitre => const MaitrePage(),
  AppSection.lab => const LabPage(),
  AppSection.chaudron => const ChaudronPage(),
  AppSection.projets => const ProjetsPage(),
  AppSection.progression => const ProgressionPage(),
  AppSection.grimoire => const GrimoirePage(),
  AppSection.parametres => const ParametresPage(),
};

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppSection.accueil.path,
    errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          for (final section in AppSection.primary)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: section.path,
                  builder: (context, state) => _pageFor(section),
                  routes: [
                    if (section == AppSection.academie)
                      GoRoute(
                        path: ':moduleId',
                        builder: (context, state) {
                          final module = moduleById(
                            state.pathParameters['moduleId']!,
                          );
                          return module == null
                              ? NotFoundPage(uri: state.uri)
                              : ModulePage(module: module);
                        },
                      ),
                  ],
                ),
              ],
            ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: plusPath,
                builder: (context, state) => const PlusPage(),
                routes: [
                  for (final section in AppSection.secondary)
                    GoRoute(
                      path: section.path.substring(plusPath.length + 1),
                      builder: (context, state) => _pageFor(section),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
