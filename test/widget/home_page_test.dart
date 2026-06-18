import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/features/home/home_page.dart';

void main() {
  testWidgets(
    'home page shows camera surface, capture button, and search field',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(
            pendingCount: 1,
            onCapturePressed: null,
            onSearchSubmitted: null,
            onSettingsPressed: null,
          ),
        ),
      );

      expect(find.text('小龟寻物'), findsOneWidget);
      expect(find.text('1 张照片待识别'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('问问小龟：我的东西放哪了？'), findsOneWidget);
    },
  );
}
