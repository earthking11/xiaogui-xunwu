import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/features/settings/settings_page.dart';

void main() {
  testWidgets('settings page saves trimmed API key', (tester) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          initialApiKey: null,
          onSave: (value) async {
            saved = value;
          },
          onTestApiKey: (_) async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  test-key  ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(saved, 'test-key');
  });
}
