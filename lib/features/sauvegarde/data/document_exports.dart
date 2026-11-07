import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../academie/data/course_repository.dart';
import '../../academie/domain/course.dart';
import '../../academie/domain/module_catalog.dart';
import '../../notes/domain/note.dart';
import '../../progression/domain/certificates.dart';
import '../../projets/domain/project.dart';

/// Retire le balisage léger des cours (`**gras**`, `code`).
String plainText(String text) => text.replaceAll('**', '').replaceAll('`', '');

String _date(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

/// Fabrique les PDF avec les polices de l'application, embarquées : les
/// accents et les caractères spéciaux s'affichent hors ligne.
class PdfExporter {
  PdfExporter(this._bundle);

  final AssetBundle _bundle;
  pw.ThemeData? _theme;
  pw.Font? _mono;

  Future<pw.ThemeData> _loadTheme() async {
    Future<pw.Font> font(String name) async =>
        pw.Font.ttf(await _bundle.load('assets/fonts/$name'));
    _mono ??= await font('IBMPlexMono-Regular.ttf');
    return _theme ??= pw.ThemeData.withFont(
      base: await font('AtkinsonHyperlegible-Regular.ttf'),
      bold: await font('AtkinsonHyperlegible-Bold.ttf'),
    );
  }

  Future<List<int>> _build(
    String title,
    List<pw.Widget> Function() content,
  ) async {
    final theme = await _loadTheme();
    final document = pw.Document(title: title, author: 'Druide And-Droiīd');
    document.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '$title · ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (_) => content(),
      ),
    );
    return document.save();
  }

  pw.Widget _heading(String text, {double size = 15}) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
    child: pw.Text(
      plainText(text),
      style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget _paragraph(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(plainText(text), style: const pw.TextStyle(fontSize: 11)),
  );

  pw.Widget _code(String code, {String? output}) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(8),
    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(code, style: pw.TextStyle(font: _mono, fontSize: 9)),
        if (output != null) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Sortie : $output',
            style: pw.TextStyle(font: _mono, fontSize: 9),
          ),
        ],
      ],
    ),
  );

  pw.Widget _box(String label, String text) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
    child: pw.Text(
      '$label : ${plainText(text)}',
      style: const pw.TextStyle(fontSize: 10.5),
    ),
  );

  List<pw.Widget> _block(LessonBlock block) => switch (block) {
    HeadingBlock(:final text) => [_heading(text, size: 13)],
    ParagraphBlock(:final text) => [_paragraph(text)],
    ListBlock(:final items) => [
      for (final item in items) _paragraph('• $item'),
    ],
    CodeBlock(:final code, :final output) => [_code(code, output: output)],
    CalloutBlock(:final kind, :final text) => [
      _box(kind == CalloutKind.warning ? 'Attention' : 'À savoir', text),
    ],
    TipBlock(:final text) => [_box('Conseil du Maître', text)],
    LayersBlock(:final title, :final layers) => [
      _heading(title, size: 12),
      for (final layer in layers) _paragraph('${layer.name} : ${layer.detail}'),
    ],
  };

  Future<List<int>> course(AcademyModule module, Course course) {
    return _build('Module ${module.number} — ${module.title}', () {
      return [
        _heading('Module ${module.number} — ${module.title}', size: 20),
        _paragraph(module.summary),
        for (final lesson in course.lessons) ...[
          pw.NewPage(),
          _heading(lesson.title, size: 17),
          for (final block in lesson.blocks) ..._block(block),
          if (lesson.exercises.isNotEmpty) ...[
            _heading('Exercices'),
            for (final exercise in lesson.exercises)
              _paragraph('• ${exercise.prompt}'),
          ],
        ],
        pw.NewPage(),
        _heading('Corrigés des exercices', size: 17),
        for (final lesson in course.lessons)
          for (final exercise in lesson.exercises) ...[
            _paragraph(exercise.prompt),
            exercise.solutionLanguage == null
                ? _paragraph('Corrigé : ${exercise.solution}')
                : _code(exercise.solution),
          ],
      ];
    });
  }

  Future<List<int>> notes(List<Note> notes) {
    return _build('Mes notes', () {
      return [
        _heading('Mes notes', size: 20),
        if (notes.isEmpty) _paragraph('Aucune note.'),
        for (final note in notes) ...[
          _heading(note.displayTitle),
          _paragraph('Modifiée le ${_date(note.updatedAt)}'),
          _paragraph(note.body),
        ],
      ];
    });
  }

  Future<List<int>> project(Project project, ProjectState state) {
    return _build(project.title, () {
      return [
        _heading(project.title, size: 20),
        _paragraph(project.stack),
        _heading('Objectif'),
        _paragraph(project.objective),
        _heading('Prérequis'),
        for (final item in project.prerequisites) _paragraph('• $item'),
        _heading('Étapes'),
        for (final (index, step) in project.steps.indexed) ...[
          _heading(
            '${index + 1}. ${step.title}'
            '${state.doneSteps.contains(index) ? ' (fait)' : ''}',
            size: 12,
          ),
          _paragraph(step.text),
          if (step.code case final code?) _code(code.code),
          _paragraph('Vérification : ${step.verify}'),
        ],
        _heading('Test'),
        _paragraph(project.testIntro),
        _code(project.test.code, output: project.test.output),
        _heading('Critères de réussite'),
        for (final (index, criterion) in project.criteria.indexed)
          _paragraph(
            '${state.doneCriteria.contains(index) ? '[x]' : '[ ]'} $criterion',
          ),
        if (state.proof.isNotEmpty) ...[
          _heading('Preuve'),
          _paragraph(state.proof),
        ],
      ];
    });
  }

  Future<List<int>> certificate(Certificate certificate, String name) {
    return _build('Certificat interne', () {
      return [
        pw.SizedBox(height: 60),
        pw.Center(
          child: pw.Text(
            'Certificat interne de réussite',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text(
            name.isEmpty ? 'Apprenti' : name,
            style: const pw.TextStyle(fontSize: 20),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            certificate.title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text(certificate.reason)),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('Obtenu le ${_date(certificate.date)}')),
        pw.SizedBox(height: 50),
        pw.Text(
          certificateDisclaimer,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ];
    });
  }
}

final pdfExporterProvider = Provider<PdfExporter>(
  (ref) => PdfExporter(ref.watch(assetBundleProvider)),
);

/// Réponses aux exercices de l'Académie et code du Lab, en Markdown lisible.
String exercisesMarkdown({
  required Map<String, Exercise> exercises,
  required Map<String, String> answers,
  required Map<String, String> labCode,
}) {
  final buffer = StringBuffer('# Mes exercices\n\n## Académie\n\n');
  if (answers.isEmpty) buffer.writeln('Aucune réponse.\n');
  for (final MapEntry(:key, :value) in answers.entries) {
    buffer
      ..writeln('### ${plainText(exercises[key]?.prompt ?? key)}\n')
      ..writeln('```\n$value\n```\n');
  }
  buffer.writeln('## Lab\n');
  if (labCode.isEmpty) buffer.writeln('Aucun code.\n');
  for (final MapEntry(:key, :value) in labCode.entries) {
    buffer
      ..writeln('### $key\n')
      ..writeln('```\n$value\n```\n');
  }
  return buffer.toString();
}

String notesMarkdown(List<Note> notes) =>
    [for (final note in notes) '# ${note.displayTitle}\n\n${note.body}\n']
        .join('\n');
