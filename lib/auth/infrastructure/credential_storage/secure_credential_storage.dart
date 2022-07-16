import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/infrastructure/credential_storage/credential_storage.dart';

class SecureCredentialsStorage implements CredentialStorage {
  final FlutterSecureStorage _storage;
  static const _key = 'oauth2_credentials';
  Credentials? _cacheCredentials;
  SecureCredentialsStorage(this._storage);

  @override
  Future<Credentials?> read() async {
    if (_cacheCredentials != null) {
      return _cacheCredentials;
    }
    final json = await _storage.read(key: _key);
    if (json == null) {
      return null;
    }
    try {
      return _cacheCredentials = Credentials.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    _cacheCredentials = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cacheCredentials = null;
    return _storage.delete(key: _key);
  }
}
