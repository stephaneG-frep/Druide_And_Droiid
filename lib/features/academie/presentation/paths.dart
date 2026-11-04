import '../../../app/sections.dart';

String modulePath(String moduleId) => '${AppSection.academie.path}/$moduleId';

String lessonPath(String moduleId, String lessonId) =>
    '${modulePath(moduleId)}/lecon/$lessonId';

String evaluationPath(String moduleId) => '${modulePath(moduleId)}/evaluation';
