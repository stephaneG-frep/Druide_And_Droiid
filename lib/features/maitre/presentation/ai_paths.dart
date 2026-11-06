import '../../../app/sections.dart';

final aiSettingsPath = '${AppSection.parametres.path}/ia';

String conversationPath(int id, {String? question}) {
  final path = '${AppSection.maitre.path}/conversation/$id';
  return question == null
      ? path
      : '$path?question=${Uri.encodeQueryComponent(question)}';
}
