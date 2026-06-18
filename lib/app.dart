import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/home/home_page.dart';

class XiaoguiXunwuApp extends StatelessWidget {
  const XiaoguiXunwuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '小龟寻物',
      theme: buildXunwuTheme(),
      home: const HomePage(
        pendingCount: 0,
        onCapturePressed: null,
        onSearchSubmitted: null,
        onSettingsPressed: null,
      ),
    );
  }
}
