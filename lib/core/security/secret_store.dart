import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Le stockage sécurisé refuse l'accès, par exemple un trousseau Linux verrouillé.
class SecretStoreUnavailable implements Exception {
  const SecretStoreUnavailable(this.message);

  final String message;

  factory SecretStoreUnavailable.from(PlatformException error) {
    return SecretStoreUnavailable(
      error.code == 'KeyringLocked'
          ? 'Le trousseau du système est verrouillé. Déverrouillez-le, par '
                'exemple avec l\'application Mots de passe et clés, puis '
                'réessayez.'
          : 'Le stockage sécurisé du système est indisponible.',
    );
  }

  @override
  String toString() => 'SecretStoreUnavailable';
}

/// Coffre des secrets (clés API), adossé au stockage sécurisé de la plateforme :
/// Keystore sur Android, libsecret sur Linux. Jamais inclus dans les sauvegardes.
class SecretStore {
  const SecretStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String name) => _guard(() => _storage.read(key: name));

  Future<void> write(String name, String value) =>
      _guard(() => _storage.write(key: name, value: value));

  Future<void> delete(String name) => _guard(() => _storage.delete(key: name));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw SecretStoreUnavailable.from(error);
    }
  }
}

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const SecretStore(FlutterSecureStorage()),
);
