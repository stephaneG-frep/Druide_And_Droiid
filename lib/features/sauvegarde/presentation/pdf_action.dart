import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/druide_toast.dart';
import '../data/file_saver.dart';

/// Fabrique un PDF puis laisse choisir où l'enregistrer.
class PdfExportButton extends ConsumerStatefulWidget {
  const PdfExportButton({
    required this.fileName,
    required this.build,
    super.key,
  });

  final String fileName;
  final Future<List<int>> Function(WidgetRef ref) build;

  @override
  ConsumerState<PdfExportButton> createState() => _PdfExportButtonState();
}

class _PdfExportButtonState extends ConsumerState<PdfExportButton> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final bytes = await widget.build(ref);
      final location = await ref
          .read(fileSaverProvider)
          .save(widget.fileName, bytes);
      if (location != null && mounted) {
        showDruideToast(context, 'PDF enregistré : $location');
      }
    } on Exception catch (error) {
      debugPrint('Export PDF impossible : $error');
      if (mounted) {
        showDruideToast(
          context,
          'Le PDF n\'a pas pu être créé.',
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Exporter en PDF',
      icon: _busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      onPressed: _busy ? null : _export,
    );
  }
}
