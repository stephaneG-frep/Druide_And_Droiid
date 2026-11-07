import '../../../app/sections.dart';
import '../domain/bug_rule.dart';

String bugCasePath(int id) => '${AppSection.chaudron.path}/dossier/$id';

String bugGuidePath(BugFamily family) =>
    '${AppSection.chaudron.path}/guide/${family.name}';
