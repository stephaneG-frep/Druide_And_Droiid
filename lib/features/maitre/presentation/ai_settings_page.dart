import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/security/secret_store.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/ai_settings_repository.dart';
import '../domain/ai_chat.dart';
import '../domain/ai_provider.dart';
import 'chat_controller.dart';

class AiSettingsPage extends ConsumerWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);

    return PageFrame(
      title: 'Réglages du Maître',
      children: [
        switch (settings) {
          AsyncData(:final value) => _ProviderForm(settings: value),
          AsyncError() => const ErrorNotice(
            message: 'Les réglages n\'ont pas pu être lus.',
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _ProviderForm extends ConsumerStatefulWidget {
  const _ProviderForm({required this.settings});

  final AiSettings settings;

  @override
  ConsumerState<_ProviderForm> createState() => _ProviderFormState();
}

class _ProviderFormState extends ConsumerState<_ProviderForm> {
  late AiProviderKind _kind =
      widget.settings.active ?? AiProviderKind.anthropic;
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _key = TextEditingController();
  final _timeout = TextEditingController();
  final _maxTokens = TextEditingController();
  final _inputPrice = TextEditingController();
  final _outputPrice = TextEditingController();
  List<String> _models = const [];
  bool _busy = false;
  String? _result;
  bool _resultOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _baseUrl,
      _model,
      _key,
      _timeout,
      _maxTokens,
      _inputPrice,
      _outputPrice,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _load() {
    final config = widget.settings.configOf(_kind);
    _baseUrl.text = config.baseUrl;
    _model.text = config.model;
    _timeout.text = '${config.timeoutSeconds}';
    _maxTokens.text = '${config.maxOutputTokens}';
    _inputPrice.text = config.inputPricePerMillion?.toString() ?? '';
    _outputPrice.text = config.outputPricePerMillion?.toString() ?? '';
    _key.clear();
    _models = const [];
    _result = null;
  }

  AiProviderConfig get _config => AiProviderConfig(
    kind: _kind,
    baseUrl: _baseUrl.text.trim(),
    model: _model.text.trim(),
    timeoutSeconds:
        int.tryParse(_timeout.text) ?? AiProviderConfig.defaultTimeoutSeconds,
    maxOutputTokens:
        int.tryParse(_maxTokens.text) ??
        AiProviderConfig.defaultMaxOutputTokens,
    inputPricePerMillion: double.tryParse(
      _inputPrice.text.replaceAll(',', '.'),
    ),
    outputPricePerMillion: double.tryParse(
      _outputPrice.text.replaceAll(',', '.'),
    ),
  );

  bool get _hasKey =>
      _key.text.trim().isNotEmpty || widget.settings.keysSaved.contains(_kind);

  Future<void> _storeKeyIfTyped() async {
    final key = _key.text.trim();
    if (key.isEmpty) return;
    await ref.read(aiSettingsRepositoryProvider).saveKey(_kind, key);
    _key.clear();
  }

  Future<void> _guarded(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      await action();
    } on AiFailure catch (failure) {
      _show(failure.message, ok: false);
    } on SecretStoreUnavailable catch (error) {
      _show(error.message, ok: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message, {required bool ok}) {
    if (mounted) {
      setState(() {
        _result = message;
        _resultOk = ok;
      });
    }
  }

  Future<void> _test() => _guarded(() async {
    final problem = _config.urlProblem(withKey: _hasKey);
    if (problem != null) return _show(problem, ok: false);
    if (_kind.needsKey && !_hasKey) {
      return _show('Saisissez d\'abord votre clé.', ok: false);
    }
    await _storeKeyIfTyped();
    final client = await ref.read(aiClientBuilderProvider)(_config);
    final models = await client.listModels();
    if (!mounted) return;
    // Aucun choix automatique : le premier de la liste peut être le plus cher.
    setState(() => _models = models);
    _show(
      'Connexion réussie : ${models.length} modèles disponibles. Choisissez-en '
      'un, puis touchez Enregistrer et activer. Ce test ne génère aucune '
      'réponse.',
      ok: true,
    );
  });

  Future<void> _save() => _guarded(() async {
    final config = _config;
    final problem = config.urlProblem(withKey: _hasKey);
    if (problem != null) return _show(problem, ok: false);
    if (config.model.isEmpty) return _show('Choisissez un modèle.', ok: false);
    if (_kind.needsKey && !_hasKey) {
      return _show('Saisissez d\'abord votre clé.', ok: false);
    }
    await _storeKeyIfTyped();
    final repository = ref.read(aiSettingsRepositoryProvider);
    await repository.saveConfig(config);
    await repository.setActive(_kind);
    if (mounted) {
      showDruideToast(context, '${_kind.label} est maintenant actif.');
    }
  });

  Future<void> _deleteKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette clé ?'),
        content: const Text('Elle sera effacée du stockage sécurisé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _guarded(
      () => ref.read(aiSettingsRepositoryProvider).deleteKey(_kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final saved = widget.settings.keysSaved.contains(_kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        _ActiveNotice(settings: widget.settings, selected: _kind),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              DropdownButtonFormField<AiProviderKind>(
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Fournisseur',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final kind in AiProviderKind.values)
                    DropdownMenuItem(value: kind, child: Text(kind.label)),
                ],
                onChanged: (kind) {
                  if (kind == null) return;
                  setState(() {
                    _kind = kind;
                    _load();
                  });
                },
              ),
              if (_kind.editableBaseUrl)
                TextField(
                  controller: _baseUrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Adresse du service',
                    helperText: _kind == AiProviderKind.ollama
                        ? 'Sur l\'émulateur : http://10.0.2.2:11434. Sur '
                              'téléphone, utilisez adb reverse.'
                        : 'Avec le préfixe de l\'API, par exemple '
                              'https://exemple.com/v1.',
                    helperMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (_kind.acceptsKey)
                TextField(
                  controller: _key,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: saved
                        ? 'Remplacer la clé enregistrée'
                        : _kind.needsKey
                        ? 'Clé d\'API'
                        : 'Clé d\'API (facultative)',
                    helperText:
                        'Stockée dans le coffre de l\'appareil. Elle '
                        'n\'est jamais affichée ni sauvegardée.',
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (saved)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _deleteKey,
                    icon: const Icon(Icons.key_off_outlined),
                    label: const Text('Supprimer la clé'),
                  ),
                ),
              TextField(
                controller: _model,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Modèle',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_models.isNotEmpty)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Modèles disponibles',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final model in _models)
                      DropdownMenuItem(
                        value: model,
                        child: Text(model, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (model) => _model.text = model ?? _model.text,
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ArcaneButton(
                    label: 'Tester la connexion',
                    icon: Icons.wifi_tethering,
                    secondary: true,
                    onPressed: _busy ? null : _test,
                  ),
                  ArcaneButton(
                    label: 'Enregistrer et activer',
                    icon: Icons.check,
                    onPressed: _busy ? null : _save,
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_result case final result?)
                Text(
                  result,
                  style: context.text.bodyMedium!.copyWith(
                    color: _resultOk ? techno.emeraude : techno.danger,
                  ),
                ),
            ],
          ),
        ),
        const SectionTitle('Limites et coût'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              TextField(
                controller: _timeout,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Délai d\'attente (secondes)',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _maxTokens,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Longueur maximale d\'une réponse (jetons)',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _inputPrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tarif entrée (\$ / million de jetons)',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _outputPrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tarif sortie (\$ / million de jetons)',
                  border: OutlineInputBorder(),
                ),
              ),
              Text(
                'Facultatif. Les tarifs changent : relevez-les sur la page du '
                'fournisseur pour obtenir une estimation de coût.',
                style: context.text.bodySmall!.copyWith(color: techno.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dit quel fournisseur répond vraiment : choisir dans la liste ne l'active pas.
class _ActiveNotice extends StatelessWidget {
  const _ActiveNotice({required this.settings, required this.selected});

  final AiSettings settings;
  final AiProviderKind selected;

  @override
  Widget build(BuildContext context) {
    final config = settings.activeConfig;
    return TechnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Text(
            config == null
                ? 'Aucun fournisseur actif'
                : 'Actif : ${config.kind.label} · ${config.model}',
            style: context.text.titleSmall,
          ),
          if (selected != settings.active)
            Text(
              '${selected.label} n\'est pas actif. Touchez Enregistrer et '
              'activer pour l\'utiliser.',
              style: context.text.bodySmall!.copyWith(
                color: context.techno.orange,
              ),
            ),
        ],
      ),
    );
  }
}
