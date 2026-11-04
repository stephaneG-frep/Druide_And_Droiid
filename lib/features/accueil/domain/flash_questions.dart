import '../../../design_system/quiz_card.dart';

/// Question du jour, stable sur une même journée.
QuizQuestion flashQuestionFor(DateTime date) {
  final dayNumber = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(2000)).inDays;
  return flashQuestions[dayNumber % flashQuestions.length];
}

const flashQuestions = [
  QuizQuestion(
    prompt: 'Sur quel noyau repose Android ?',
    options: ['Windows NT', 'Linux', 'Darwin'],
    answerIndex: 1,
    explanation:
        'Android s\'appuie sur le noyau Linux, qui gère notamment les '
        'processus, la mémoire et les pilotes matériels.',
  ),
  QuizQuestion(
    prompt:
        'Quel outil dialogue avec un appareil Android depuis un ordinateur ?',
    options: ['ADB', 'Gradle', 'Logcat Studio'],
    answerIndex: 0,
    explanation:
        'ADB (Android Debug Bridge) permet par exemple d\'installer une '
        'application ou d\'ouvrir un shell sur l\'appareil.',
  ),
  QuizQuestion(
    prompt: 'Quel fichier déclare les permissions d\'une application ?',
    options: ['build.gradle', 'pubspec.yaml', 'AndroidManifest.xml'],
    answerIndex: 2,
    explanation:
        'Le manifeste décrit l\'application au système : ses composants, '
        'ses permissions et ses fonctionnalités requises.',
  ),
  QuizQuestion(
    prompt: 'En Kotlin, quel mot-clé déclare une variable non réassignable ?',
    options: ['var', 'val', 'let'],
    answerIndex: 1,
    explanation:
        '`val` crée une référence en lecture seule, alors que `var` peut '
        'être réassignée.',
  ),
  QuizQuestion(
    prompt:
        'Quel format Google Play demande-t-il pour une nouvelle application ?',
    options: ['AAB', 'ZIP', 'DEB'],
    answerIndex: 0,
    explanation:
        'Google Play génère les APK adaptés à chaque appareil à partir d\'un '
        'Android App Bundle (AAB).',
  ),
];
