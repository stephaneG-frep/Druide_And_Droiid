import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/dialogue_bubble.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/motion.dart';
import '../../../design_system/quiz_card.dart';
import '../../../design_system/techno_card.dart';
import '../domain/course.dart';

/// Questionnaire noté : réponses, validation, correction détaillée, reprise.
class QuizRunner extends StatefulWidget {
  const QuizRunner({
    required this.questions,
    required this.passPercent,
    required this.onSubmitted,
    super.key,
  });

  final List<CourseQuestion> questions;
  final int passPercent;

  /// Appelé à la validation avec le score obtenu.
  final ValueChanged<int> onSubmitted;

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner>
    with AutomaticKeepAliveClientMixin {
  final _selections = <int, Set<int>>{};
  var _submitted = false;

  // Une liste paresseuse détruirait les réponses cochées lors du défilement.
  @override
  bool get wantKeepAlive => true;

  int get _answered =>
      _selections.values.where((selection) => selection.isNotEmpty).length;

  void _toggle(int question, int option) {
    setState(() {
      final selection = _selections.putIfAbsent(question, () => {});
      if (widget.questions[question].isMultiple) {
        if (!selection.remove(option)) selection.add(option);
      } else {
        selection
          ..clear()
          ..add(option);
      }
    });
  }

  void _submit() {
    setState(() => _submitted = true);
    widget.onSubmitted(scoreOf(widget.questions, _selections));
  }

  void _restart() {
    setState(() {
      _selections.clear();
      _submitted = false;
    });
  }

  OptionState _stateOf(CourseQuestion question, int option, Set<int> selected) {
    final isSelected = selected.contains(option);
    if (!_submitted) {
      return isSelected ? OptionState.selected : OptionState.idle;
    }
    if (question.answers.contains(option)) return OptionState.correct;
    return isSelected ? OptionState.wrong : OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final total = widget.questions.length;
    final duration = MotionScope.duration(
      context,
      const Duration(milliseconds: 200),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (final (index, question) in widget.questions.indexed)
          _buildQuestion(index, question, duration),
        if (_submitted)
          _buildResult(scoreOf(widget.questions, _selections), total)
        else if (_answered == total)
          Align(
            alignment: Alignment.centerLeft,
            child: ArcaneButton(
              label: 'Valider mes réponses',
              icon: Icons.check,
              onPressed: _submit,
            ),
          )
        else
          Text(
            'Répondez à toutes les questions pour valider '
            '($_answered / $total).',
            style: context.text.bodySmall!.copyWith(
              color: context.techno.muted,
            ),
          ),
      ],
    );
  }

  Widget _buildQuestion(int index, CourseQuestion question, Duration duration) {
    final techno = context.techno;
    final selected = _selections[index] ?? const <int>{};
    final correct = question.isCorrect(selected);

    return TechnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            '${index + 1}. ${question.prompt}',
            style: context.text.titleSmall,
          ),
          if (question.isMultiple)
            Text(
              'Plusieurs réponses possibles.',
              style: context.text.bodySmall!.copyWith(color: techno.muted),
            ),
          for (final (option, label) in question.options.indexed)
            QuizOption(
              label: label,
              duration: duration,
              state: _stateOf(question, option, selected),
              onTap: _submitted ? null : () => _toggle(index, option),
            ),
          if (_submitted) ...[
            Text(
              correct ? 'Bien joué !' : 'Pas tout à fait.',
              style: context.text.titleSmall!.copyWith(
                color: correct ? techno.emeraude : techno.danger,
              ),
            ),
            Text(question.explanation, style: context.text.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildResult(int score, int total) {
    final passed = hasPassed(score, total, widget.passPercent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Semantics(
          liveRegion: true,
          child: DialogueBubble(
            origin: 'Message préenregistré',
            mood: passed ? MascotMood.joyeux : MascotMood.encourageant,
            message: passed
                ? 'Résultat : $score / $total. Réussi, bravo !'
                : 'Résultat : $score / $total. Il faut '
                      '${widget.passPercent} % pour réussir. Relisez les '
                      'corrections, puis retentez votre chance !',
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: ArcaneButton(
            label: 'Recommencer',
            icon: Icons.replay,
            secondary: true,
            onPressed: _restart,
          ),
        ),
      ],
    );
  }
}
