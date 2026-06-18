import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/services/api_key_store.dart';

void main() {
  test('InMemoryApiKeyStore saves trimmed key and clears it', () async {
    final store = InMemoryApiKeyStore();

    await store.saveApiKey('  test-key  ');

    expect(await store.readApiKey(), 'test-key');

    await store.clearApiKey();

    expect(await store.readApiKey(), isNull);
  });
}
