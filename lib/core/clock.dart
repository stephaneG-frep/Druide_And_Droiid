import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horloge remplaçable, pour que les tests maîtrisent les dates enregistrées.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
