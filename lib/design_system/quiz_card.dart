import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import 'motion.dart';
import 'techno_card.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String explanation;
}

/// Question à choix unique avec correction immédiate.
class QuizCard extends StatefulWidget {
  const QuizCard({required this.question, this.footnote, super.key});

  final QuizQuestion question;
  final String? footnote;

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? _selected;

  @override
  void didUpdateWidget(QuizCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final techno = context.techno;
    final selected = _selected;
    final answered = selected != null;
    final correct = selected == question.answerIndex;
    final duration = MotionScope.duration(
      context,
      const Duration(milliseconds: 200),
    );

    return TechnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(question.prompt, style: context.text.titleSmall),
          const SizedBox(height: 12),
          for (final (index, option) in question.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _QuizOption(
                label: option,
                duration: duration,
                state: switch (index) {
                  _ when !answered => _OptionState.idle,
                  _ when index == question.answerIndex => _OptionState.correct,
                  _ when index == selected => _OptionState.wrong,
                  _ => _OptionState.dimmed,
                },
                onTap: answered
                    ? null
                    : () => setState(() => _selected = index),
              ),
            ),
          SmoothSize(
            child: answered
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          correct ? 'Bien joué !' : 'Pas tout à fait.',
                          style: context.text.titleSmall!.copyWith(
                            color: correct ? techno.emeraude : techno.danger,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.explanation,
                        style: context.text.bodyMedium,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => _selected = null),
                          child: const Text('Recommencer'),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (widget.footnote != null)
            Text(
              widget.footnote!,
              style: context.text.bodySmall!.copyWith(color: techno.muted),
            ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.label,
    required this.state,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final (color, icon, suffix) = switch (state) {
      _OptionState.idle => (techno.border, null, ''),
      _OptionState.correct => (
        techno.emeraude,
        Icons.check_circle_outline,
        ', bonne réponse',
      ),
      _OptionState.wrong => (
        techno.danger,
        Icons.cancel_outlined,
        ', votre réponse, incorrecte',
      ),
      _OptionState.dimmed => (techno.border, null, ''),
    };
    final shape = BeveledRectangleBorder(
      borderRadius: bevel,
      side: BorderSide(color: color, width: 1.5),
    );

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$label$suffix',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: duration,
          decoration: ShapeDecoration(
            shape: shape,
            color: state == _OptionState.idle || state == _OptionState.dimmed
                ? Colors.transparent
                : color.withValues(alpha: 0.14),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: shape,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label, style: context.text.bodyMedium),
                      ),
                      if (icon != null) Icon(icon, color: color, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
