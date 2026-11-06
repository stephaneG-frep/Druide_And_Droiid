import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/autosave.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/code_panel.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/techno_card.dart';
import '../../maitre/data/ai_settings_repository.dart';
import '../../maitre/presentation/ai_actions.dart';
import '../data/exercise_repository.dart';
import '../domain/course.dart';

/// Conserve le texte saisi pendant que l'apprenant écrit.
class ExerciseDraft extends Autosaver {
  ExerciseDraft(
    this._repository,
    this._text, {
    required this.exerciseId,
    required this.moduleId,
    super.debounce = const Duration(milliseconds: 300),
  });

  final ExerciseRepository _repository;
  final String exerciseId;
  final String moduleId;
  String _text;

  void update(String text) {
    if (text == _text) return;
    _text = text;
    markDirty();
  }

  @override
  Future<bool> persist() async {
    await _repository.saveText(
      exerciseId: exerciseId,
      moduleId: moduleId,
      text: _text,
    );
    return true;
  }
}

class ExerciseCard extends ConsumerStatefulWidget {
  const ExerciseCard({
    required this.exercise,
    required this.moduleId,
    super.key,
  });

  final Exercise exercise;
  final String moduleId;

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard>
    with AutomaticKeepAliveClientMixin {
  late final _lifecycle = AppLifecycleListener(
    onInactive: () => _draft?.flush(),
    onPause: () => _draft?.flush(),
  );
  final _answer = TextEditingController();
  ExerciseDraft? _draft;
  var _status = ExerciseStatus.draft;
  var _revealed = false;
  var _loadFailed = false;

  // Une liste paresseuse détruirait l'état lors du défilement.
  @override
  bool get wantKeepAlive => true;

  ExerciseRepository get _repository => ref.read(exerciseRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _load();
  }

  Future<void> _load() async {
    final exercise = widget.exercise;
    try {
      final saved = await _repository.find(exercise.id);
      if (!mounted) return;
      setState(() {
        _answer.text = saved?.text ?? '';
        _status = saved?.status ?? ExerciseStatus.draft;
        _revealed = _status != ExerciseStatus.draft;
        _draft = ExerciseDraft(
          _repository,
          _answer.text,
          exerciseId: exercise.id,
          moduleId: widget.moduleId,
        );
      });
    } on Exception catch (error) {
      debugPrint('Lecture de l\'exercice impossible : $error');
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _saveResult({required bool success}) async {
    await _draft?.discard();
    try {
      final earned = await _repository.saveResult(
        exerciseId: widget.exercise.id,
        moduleId: widget.moduleId,
        text: _answer.text,
        success: success,
      );
      if (!mounted) return;
      setState(() {
        _status = success ? ExerciseStatus.success : ExerciseStatus.retry;
      });
      if (earned > 0) showDruideToast(context, '+$earned XP gagnés !');
    } on Exception catch (error) {
      debugPrint('Enregistrement de l\'exercice impossible : $error');
      if (mounted) {
        showDruideToast(
          context,
          'Votre résultat n\'a pas pu être enregistré.',
          kind: ToastKind.error,
        );
      }
    }
  }

  Future<void> _check() async {
    final success = widget.exercise.accepts(_answer.text);
    await _saveResult(success: success);
  }

  void _restart() {
    setState(() {
      _status = ExerciseStatus.draft;
      _revealed = false;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    final draft = _draft;
    if (draft != null) {
      draft.flush();
      draft.dispose();
    }
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final exercise = widget.exercise;
    final isFill = exercise.kind == ExerciseKind.fill;
    final hasTeacher = ref.watch(
      aiSettingsProvider.select(
        (settings) => settings.value?.activeConfig != null,
      ),
    );

    if (_loadFailed) {
      return const ErrorNotice(
        message: 'Cet exercice n\'a pas pu être chargé.',
      );
    }

    return TechnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(exercise.prompt, style: context.text.titleSmall),
          TextField(
            controller: _answer,
            enabled: _draft != null,
            minLines: isFill ? 1 : 3,
            maxLines: isFill ? 1 : 8,
            onChanged: (text) => _draft?.update(text),
            style: context.text.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Votre réponse',
              border: OutlineInputBorder(),
            ),
          ),
          ..._buildState(isFill),
          if (hasTeacher)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Corriger avec le Maître'),
                onPressed: () => askForCorrection(
                  context,
                  ref,
                  statement: exercise.prompt,
                  answer: _answer.text,
                  reference: exercise.solution,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildState(bool isFill) {
    final techno = context.techno;

    if (_status == ExerciseStatus.success) {
      return [
        Text(
          'Exercice réussi.',
          style: context.text.titleSmall!.copyWith(color: techno.emeraude),
        ),
        _buildSolution(),
        _buildRestart(),
      ];
    }

    if (isFill) {
      return [
        if (_status == ExerciseStatus.retry) ...[
          Text(
            'Ce n\'est pas la réponse attendue. Réessayez, ou consultez la '
            'correction.',
            style: context.text.bodyMedium!.copyWith(color: techno.danger),
          ),
          if (_revealed) _buildSolution(),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ArcaneButton(
              label: 'Vérifier',
              icon: Icons.check,
              onPressed: _check,
            ),
            if (_status == ExerciseStatus.retry && !_revealed)
              ArcaneButton(
                label: 'Voir la correction',
                secondary: true,
                onPressed: () => setState(() => _revealed = true),
              ),
          ],
        ),
      ];
    }

    if (!_revealed) {
      return [
        Align(
          alignment: Alignment.centerLeft,
          child: ArcaneButton(
            label: 'Voir la correction',
            secondary: true,
            onPressed: () => setState(() => _revealed = true),
          ),
        ),
      ];
    }

    return [
      _buildSolution(),
      Text(
        'Comparez avec votre réponse : c\'est à vous de juger.',
        style: context.text.bodySmall!.copyWith(color: techno.muted),
      ),
      if (_status == ExerciseStatus.retry)
        Text(
          'Marqué à retravailler.',
          style: context.text.bodyMedium!.copyWith(color: techno.orange),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ArcaneButton(
            label: 'J\'ai réussi',
            icon: Icons.check,
            onPressed: () => _saveResult(success: true),
          ),
          ArcaneButton(
            label: 'À retravailler',
            secondary: true,
            onPressed: () => _saveResult(success: false),
          ),
        ],
      ),
    ];
  }

  Widget _buildSolution() {
    final exercise = widget.exercise;
    final language = exercise.solutionLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text('Correction', style: context.text.titleSmall),
        if (language != null)
          CodePanel(code: exercise.solution, language: language)
        else
          Text(exercise.solution, style: context.text.bodyMedium),
      ],
    );
  }

  Widget _buildRestart() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _restart,
        child: const Text('Refaire l\'exercice'),
      ),
    );
  }
}
