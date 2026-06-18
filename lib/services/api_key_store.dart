import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ApiKeyStore {
  Future<String?> readApiKey();
  Future<void> saveApiKey(String apiKey);
  Future<void> clearApiKey();
}

class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'mimo_api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readApiKey() {
    return _storage.read(key: _key);
  }

  @override
  Future<void> saveApiKey(String apiKey) {
    return _storage.write(key: _key, value: apiKey.trim());
  }

  @override
  Future<void> clearApiKey() {
    return _storage.delete(key: _key);
  }
}

class InMemoryApiKeyStore implements ApiKeyStore {
  String? _apiKey;

  @override
  Future<String?> readApiKey() async => _apiKey;

  @override
  Future<void> saveApiKey(String apiKey) async {
    _apiKey = apiKey.trim();
  }

  @override
  Future<void> clearApiKey() async {
    _apiKey = null;
  }
}
