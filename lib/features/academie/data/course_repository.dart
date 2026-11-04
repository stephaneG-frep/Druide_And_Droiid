import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/course.dart';

class CourseRepository {
  const CourseRepository(this._bundle);

  final AssetBundle _bundle;

  static const _index = 'assets/courses/index.json';

  /// Identifiants des modules dont le contenu est disponible.
  Future<List<String>> availableModules() async {
    final decoded = jsonDecode(await _bundle.loadString(_index, cache: false));
    return (decoded as Map<String, Object?>)['modules'] is List<Object?>
        ? (decoded['modules']! as List<Object?>).cast<String>()
        : throw const FormatException('index des cours invalide');
  }

  Future<Course> load(String moduleId) async {
    final source = await _bundle.loadString(
      'assets/courses/$moduleId.json',
      cache: false,
    );
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('$moduleId : le cours doit être un objet');
    }
    final course = Course.fromJson(decoded);
    if (course.moduleId != moduleId) {
      throw FormatException('$moduleId : moduleId incohérent');
    }
    return course;
  }
}

final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepository(ref.watch(assetBundleProvider)),
);

/// Pas de nouvel essai automatique : relire le même fichier embarqué échouerait
/// de la même façon.
final availableModulesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(courseRepositoryProvider).availableModules(),
  retry: (_, _) => null,
);

/// État du contenu d'un module.
sealed class CourseLoad {
  const CourseLoad();

  Course? get course => null;
}

class CourseReady extends CourseLoad {
  const CourseReady(this.course);

  @override
  final Course course;
}

/// Le module n'a pas encore de contenu.
class CourseAbsent extends CourseLoad {
  const CourseAbsent();
}

/// Le fichier du cours est illisible : l'écran concerné le signale.
class CourseUnreadable extends CourseLoad {
  const CourseUnreadable();
}

/// Une erreur de contenu devient un état explicite, que chaque écran présente
/// à l'utilisateur.
final courseProvider = FutureProvider.family<CourseLoad, String>((
  ref,
  moduleId,
) async {
  try {
    final available = await ref.watch(availableModulesProvider.future);
    if (!available.contains(moduleId)) return const CourseAbsent();
    final course = await ref.watch(courseRepositoryProvider).load(moduleId);
    return CourseReady(course);
  } on Object catch (error) {
    if (error is! Exception && error is! FlutterError) rethrow;
    debugPrint('Cours $moduleId illisible : $error');
    return const CourseUnreadable();
  }
}, retry: (_, _) => null);
