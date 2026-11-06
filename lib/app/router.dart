import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/academie/domain/module_catalog.dart';
import '../features/academie/presentation/academie_page.dart';
import '../features/academie/presentation/evaluation_page.dart';
import '../features/academie/presentation/lesson_page.dart';
import '../features/academie/presentation/module_page.dart';
import '../features/accueil/presentation/accueil_page.dart';
import '../features/chaudron/presentation/chaudron_page.dart';
import '../features/grimoire/presentation/grimoire_page.dart';
import '../features/lab/presentation/lab_page.dart';
import '../features/maitre/presentation/ai_settings_page.dart';
import '../features/maitre/presentation/chat_page.dart';
import '../features/maitre/presentation/maitre_page.dart';
import '../features/notes/presentation/note_editor_page.dart';
import '../features/notes/presentation/notes_page.dart';
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
  AppSection.notes => const NotesPage(),
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
      // L'éditeur couvre la navigation et laisse toute la place au clavier.
      GoRoute(
        path: newNotePath,
        builder: (context, state) =>
            NoteEditorPage(moduleId: state.uri.queryParameters['module']),
      ),
      GoRoute(
        path: '/note/:noteId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['noteId']!);
          return id == null
              ? NotFoundPage(uri: state.uri)
              : NoteEditorPage(noteId: id);
        },
      ),
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
                    if (section == AppSection.maitre)
                      GoRoute(
                        path: 'conversation/:conversationId',
                        builder: (context, state) {
                          final id = int.tryParse(
                            state.pathParameters['conversationId']!,
                          );
                          return id == null
                              ? NotFoundPage(uri: state.uri)
                              : ChatPage(
                                  conversationId: id,
                                  question:
                                      state.uri.queryParameters['question'],
                                );
                        },
                      ),
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
                        routes: [
                          GoRoute(
                            path: 'lecon/:lessonId',
                            builder: (context, state) => LessonPage(
                              moduleId: state.pathParameters['moduleId']!,
                              lessonId: state.pathParameters['lessonId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'evaluation',
                            builder: (context, state) => EvaluationPage(
                              moduleId: state.pathParameters['moduleId']!,
                            ),
                          ),
                        ],
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
                      routes: [
                        if (section == AppSection.parametres)
                          GoRoute(
                            path: 'ia',
                            builder: (context, state) => const AiSettingsPage(),
                          ),
                      ],
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
