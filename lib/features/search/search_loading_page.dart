import 'package:flutter/material.dart';

import '../../services/search_service.dart';
import 'search_result_page.dart';

class SearchLoadingPage extends StatefulWidget {
  const SearchLoadingPage({
    super.key,
    required this.question,
    required this.searchFuture,
  });

  final String question;
  final Future<ResolvedSearchResult> searchFuture;

  @override
  State<SearchLoadingPage> createState() => _SearchLoadingPageState();
}

class _SearchLoadingPageState extends State<SearchLoadingPage> {
  @override
  void initState() {
    super.initState();
    _showResult();
  }

  Future<void> _showResult() async {
    ResolvedSearchResult result;
    try {
      result = await widget.searchFuture;
    } on Exception {
      result = const ResolvedSearchResult(
        answer: '小龟暂时没有找到结果，请检查网络后再试。',
        notFound: true,
        matches: [],
      );
    }
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            SearchResultPage(question: widget.question, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('正在查找')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 42,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 20),
            Text(
              '小龟正在翻找记忆',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
