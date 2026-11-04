import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Coffre des secrets (clés API), adossé au stockage sécurisé de la plateforme :
/// Keystore sur Android, libsecret sur Linux. Jamais inclus dans les sauvegardes.
class SecretStore {
  const SecretStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String name) => _storage.read(key: name);

  Future<void> write(String name, String value) =>
      _storage.write(key: name, value: value);

  Future<void> delete(String name) => _storage.delete(key: name);
}

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const SecretStore(FlutterSecureStorage()),
);
