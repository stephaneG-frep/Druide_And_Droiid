import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'sections.dart';
import 'shell/app_shell.dart';
import 'shell/not_found_page.dart';
import 'shell/plus_page.dart';
import 'shell/section_placeholder_page.dart';

const plusPath = '/plus';

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
                  builder: (context, state) =>
                      SectionPlaceholderPage(section: section),
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
                      builder: (context, state) =>
                          SectionPlaceholderPage(section: section),
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
