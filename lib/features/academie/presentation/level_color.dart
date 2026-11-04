import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/module_catalog.dart';

Color levelColor(BuildContext context, ModuleLevel level) {
  final techno = context.techno;
  return switch (level) {
    ModuleLevel.debutant => techno.emeraude,
    ModuleLevel.intermediaire => techno.cyan,
    ModuleLevel.avance => techno.violet,
    ModuleLevel.expert => techno.orange,
  };
}
