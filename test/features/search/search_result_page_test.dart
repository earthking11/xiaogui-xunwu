import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaogui_xunwu/core/record_status.dart';
import 'package:xiaogui_xunwu/features/search/search_result_page.dart';
import 'package:xiaogui_xunwu/models/memory_record.dart';
import 'package:xiaogui_xunwu/services/search_service.dart';

void main() {
  testWidgets('search result page shows answer, reason, and record details', (
    tester,
  ) async {
    final record = MemoryRecord(
      recordId: 'record-1',
      photoPath: '/app/private/photo.jpg',
      thumbnailPath: '/app/private/thumb.jpg',
      capturedAt: DateTime.parse('2026-06-18T10:20:30.000Z'),
      gpsLatitude: 26.0,
      gpsLongitude: 119.0,
      gpsAccuracy: 10,
      readableLocation: '福建省福州市仓山区金山大道',
      userLocationNote: '书桌右上角透明盒旁',
      aiMainObjects: const ['黑色 Type-C 转接头'],
      aiAliases: const ['小黑头'],
      aiSceneDescription: '书桌上有透明盒。',
      aiLocationGuess: '可能在书桌右上角透明盒旁。',
      aiSearchSummary: '黑色 Type-C 转接头 小黑头 透明盒',
      aiConfidence: 0.9,
      status: RecordStatus.recognized,
      errorMessage: null,
      createdAt: DateTime.parse('2026-06-18T10:20:30.000Z'),
      updatedAt: DateTime.parse('2026-06-18T10:20:30.000Z'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SearchResultPage(
          question: '黑色转接头在哪',
          showPhoto: false,
          result: ResolvedSearchResult(
            answer: '可能在书桌右上角透明盒旁。',
            notFound: false,
            matches: [
              ResolvedSearchMatch(
                record: record,
                confidence: 0.88,
                reason: '主要物品和摘要都匹配。',
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.text('黑色 Type-C 转接头 可能在福建省福州市仓山区金山大道的书桌右上角透明盒旁。'),
      findsOneWidget,
    );
    expect(find.text('主要物品和摘要都匹配。'), findsOneWidget);
    expect(find.text('书桌右上角透明盒旁'), findsOneWidget);
    expect(find.text('福建省福州市仓山区金山大道'), findsOneWidget);
  });
}
