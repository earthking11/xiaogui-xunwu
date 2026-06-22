import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/features/search/search_loading_page.dart';
import 'package:xiaogui_xunwu/services/search_service.dart';

void main() {
  testWidgets('shows loading feedback before navigating to results', (
    tester,
  ) async {
    final completer = Completer<ResolvedSearchResult>();

    await tester.pumpWidget(
      MaterialApp(
        home: SearchLoadingPage(
          question: '我的钥匙在哪',
          searchFuture: completer.future,
        ),
      ),
    );

    expect(find.text('小龟正在翻找记忆'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const ResolvedSearchResult(
        answer: '还没有可查找的记忆卡。',
        notFound: true,
        matches: [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('查找结果'), findsOneWidget);
    expect(find.text('还没有可查找的记忆卡。'), findsOneWidget);
  });
}
