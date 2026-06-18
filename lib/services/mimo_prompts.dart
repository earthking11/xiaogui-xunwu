String recognitionPrompt({
  required DateTime capturedAt,
  required double? gpsLatitude,
  required double? gpsLongitude,
  required double? gpsAccuracy,
  required String? userLocationNote,
}) {
  final gpsText = gpsLatitude == null || gpsLongitude == null
      ? '无'
      : '$gpsLatitude,$gpsLongitude，精度 ${gpsAccuracy ?? 0} 米';
  final noteText = userLocationNote == null || userLocationNote.trim().isEmpty
      ? '无'
      : userLocationNote.trim();

  return '''
你是“小龟寻物”的物品记忆卡生成器。请根据图片、拍摄时间、GPS 和用户备注，生成固定 JSON。

硬规则：
1. 只描述图片中能看见或用户备注中明确写到的信息。
2. 可以推测“桌面、抽屉、盒子旁、柜子里”等画面位置线索。
3. 不要假装知道图片外的房间名、楼层、柜子层级。
4. 如果用户备注存在，必须保留在搜索摘要里。
5. 只输出 JSON，不要输出 Markdown。

字段：
mainObjects: 字符串数组，主要物品名称。
aliases: 字符串数组，用户可能会用来搜索的别名。
sceneDescription: 字符串，简短描述画面。
locationGuess: 字符串，基于图片和备注的可能位置。
searchSummary: 字符串，适合后续检索的中文摘要。
confidence: 0 到 1 的数字。
needsUserNote: 布尔值，如果图片无法判断位置线索则为 true。

拍摄时间：${capturedAt.toIso8601String()}
GPS：$gpsText
用户备注：$noteText
''';
}

String searchPrompt({
  required String question,
  required List<String> recordSummaries,
}) {
  return '''
你是“小龟寻物”的查找助手。用户会问一个东西放在哪里。你只能基于记忆卡摘要回答，不能编造不存在的位置或记录。

硬规则：
1. 只从给定记忆卡中选择。
2. 如果没有把握，notFound 设为 true，并返回可能相关的候选。
3. reason 要说明匹配依据。
4. 只输出 JSON，不要输出 Markdown。

输出 JSON 字段：
answer: 一句话中文答案。
matches: 数组，每项包含 recordId、confidence、reason。
notFound: 布尔值。

用户问题：
$question

记忆卡摘要：
${recordSummaries.join('\n\n---\n\n')}
''';
}
