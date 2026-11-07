import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/persistence/app_database.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../academie/data/course_repository.dart';
import '../../academie/domain/course.dart';
import '../../grimoire/domain/grimoire_topics.dart';
import '../../grimoire/presentation/help_button.dart';
import '../../lab/data/lab_repository.dart';
import '../../lab/domain/lab_exercise.dart';
import '../../notes/data/notes_repository.dart';
import '../data/auto_backup.dart';
import '../data/backup_repository.dart';
import '../data/document_exports.dart';
import '../data/file_saver.dart';

String _stamp(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

String _date(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} à '
      '${two(date.hour)}:${two(date.minute)}';
}

/// Fichiers lisibles joints à une archive, et export des exercices.
Future<Map<String, String>> readableFiles(WidgetRef ref) async {
  final database = ref.read(appDatabaseProvider);
  final courses = ref.read(courseRepositoryProvider);
  final exercises = <String, Exercise>{};
  for (final module in await courses.availableModules()) {
    for (final lesson in (await courses.load(module)).lessons) {
      for (final exercise in lesson.exercises) {
        exercises[exercise.id] = exercise;
      }
    }
  }
  final answers = {
    for (final row in await database.select(database.exerciseAnswers).get())
      if (row.answer.trim().isNotEmpty) row.exerciseId: row.answer,
  };
  final labExercises = await ref.read(labExercisesProvider.future);
  final names = {
    for (final exercise in labExercises) exercise.id: exercise.fileName,
    for (final language in labLanguages)
      LabExercise.free(language).id: LabExercise.free(language).fileName,
  };
  final drafts = await database.select(database.labDrafts).get();
  final notes = await ref.read(notesRepositoryProvider).watch().first;

  return {
    'notes.md': notesMarkdown(notes),
    'exercices.md': exercisesMarkdown(
      exercises: exercises,
      answers: answers,
      labCode: {for (final draft in drafts) draft.exerciseId: draft.code},
    ),
    for (final draft in drafts)
      'lab/${draft.exerciseId}-${names[draft.exerciseId] ?? 'code.txt'}':
          draft.code,
  };
}

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on BackupException catch (error) {
      if (mounted) {
        showDruideToast(context, error.message, kind: ToastKind.error);
      }
    } on Exception catch (error) {
      debugPrint('Sauvegarde impossible : $error');
      if (mounted) {
        showDruideToast(
          context,
          'L\'opération a échoué.',
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(String name, List<int> bytes) async {
    final location = await ref.read(fileSaverProvider).save(name, bytes);
    if (location != null && mounted) {
      showDruideToast(context, 'Enregistré : $location');
    }
  }

  Future<void> _exportJson() => _run(() async {
    final json = await ref.read(backupRepositoryProvider).exportJson();
    await _save(
      'druide-sauvegarde-${_stamp(DateTime.now())}.json',
      utf8.encode(json),
    );
  });

  Future<void> _exportZip() => _run(() async {
    final bytes = await ref
        .read(backupRepositoryProvider)
        .exportZip(extraFiles: await readableFiles(ref));
    await _save('druide-sauvegarde-${_stamp(DateTime.now())}.zip', bytes);
  });

  Future<void> _exportExercises() => _run(() async {
    final files = await readableFiles(ref);
    await _save('mes-exercices.md', utf8.encode(files['exercices.md']!));
  });

  Future<void> _exportNotes() => _run(() async {
    final notes = await ref.read(notesRepositoryProvider).watch().first;
    await _save(
      'mes-notes.pdf',
      await ref.read(pdfExporterProvider).notes(notes),
    );
  });

  Future<void> _createNow() => _run(() async {
    await ref.read(autoBackupsProvider).create();
    ref.invalidate(autoBackupListProvider);
    if (mounted) showDruideToast(context, 'Copie de sécurité créée.');
  });

  Future<void> _restoreBytes(List<int> bytes) async {
    final repository = ref.read(backupRepositoryProvider);
    final json = repository.decode(bytes);
    final summary = repository.inspect(json);
    if (!mounted) return;
    // Pas de barre de progression pendant que l'utilisateur décide.
    setState(() => _busy = false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remplacer toutes vos données ?'),
        content: Text(
          'Sauvegarde du ${_date(summary.createdAt)}, ${summary.total} '
          'éléments.\n\nToutes vos données actuelles seront remplacées. Une '
          'copie de l\'état actuel sera créée juste avant.\n\nVos clés d\'API '
          'devront être saisies de nouveau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(autoBackupsProvider).create(beforeRestore: true);
    await repository.restore(json);
    ref.invalidate(autoBackupListProvider);
    if (mounted) showDruideToast(context, 'Sauvegarde restaurée.');
  }

  Future<void> _restoreFile() => _run(() async {
    final bytes = await ref.read(fileOpenerProvider).open();
    if (bytes != null) await _restoreBytes(bytes);
  });

  Future<void> _restoreAuto(AutoBackupFile backup) =>
      _run(() async => _restoreBytes(await backup.file.readAsBytes()));

  @override
  Widget build(BuildContext context) {
    final autos = ref.watch(autoBackupListProvider);

    return PageFrame(
      title: 'Sauvegardes',
      actions: const [HelpButton(GrimoireTopic.sauvegarder)],
      children: [
        Text(
          'Vos données s\'enregistrent automatiquement sur cet appareil. '
          'Exportez une sauvegarde pour les garder ailleurs, ou pour changer '
          'd\'appareil. Les clés d\'API ne sont jamais incluses.',
          style: context.text.bodyMedium,
        ),
        if (_busy) const LinearProgressIndicator(),
        const SectionTitle('Exporter'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ArcaneButton(
              label: 'Exporter en JSON',
              icon: Icons.data_object,
              onPressed: _busy ? null : _exportJson,
            ),
            ArcaneButton(
              label: 'Sauvegarde complète (ZIP)',
              icon: Icons.folder_zip_outlined,
              onPressed: _busy ? null : _exportZip,
            ),
            ArcaneButton(
              label: 'Mes exercices (Markdown)',
              icon: Icons.edit_note,
              secondary: true,
              onPressed: _busy ? null : _exportExercises,
            ),
            ArcaneButton(
              label: 'Mes notes (PDF)',
              icon: Icons.picture_as_pdf_outlined,
              secondary: true,
              onPressed: _busy ? null : _exportNotes,
            ),
          ],
        ),
        const SectionTitle('Restaurer'),
        ArcaneButton(
          label: 'Restaurer depuis un fichier',
          icon: Icons.restore,
          secondary: true,
          onPressed: _busy ? null : _restoreFile,
        ),
        const SectionTitle('Copies de sécurité'),
        Text(
          'Une copie par jour d\'utilisation, gardée dans le dossier privé de '
          'l\'application. Elle disparaît si vous désinstallez l\'application.',
          style: context.text.bodySmall,
        ),
        TextButton.icon(
          onPressed: _busy ? null : _createNow,
          icon: const Icon(Icons.add),
          label: const Text('Créer une copie maintenant'),
        ),
        switch (autos) {
          AsyncData(:final value) when value.isEmpty => const Text(
            'Aucune copie pour l\'instant.',
          ),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final backup in value)
                TechnoCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${backup.beforeRestore ? 'Avant restauration' : 'Copie'}'
                          ' du ${_date(backup.date)}',
                          style: context.text.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => _restoreAuto(backup),
                        child: const Text('Restaurer'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          AsyncError() => const Text(
            'Les copies de sécurité ne sont pas disponibles ici.',
          ),
          // Texte fixe : une animation sans fin gênerait les lecteurs d'écran.
          _ => const Text('Recherche des copies…'),
        },
      ],
    );
  }
}
