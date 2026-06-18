import 'package:flutter/material.dart';

class XunwuColors {
  static const ink = Color(0xFF15201C);
  static const paper = Color(0xFFF6FAF7);
  static const mint = Color(0xFF2F9E7E);
  static const mintDark = Color(0xFF1C6F5B);
  static const warm = Color(0xFFF2A950);
  static const line = Color(0xFFDDE8E1);
}

ThemeData buildXunwuTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: XunwuColors.mint,
      brightness: Brightness.light,
      primary: XunwuColors.mint,
      surface: XunwuColors.paper,
    ),
    scaffoldBackgroundColor: XunwuColors.paper,
    textTheme: base.textTheme.apply(
      bodyColor: XunwuColors.ink,
      displayColor: XunwuColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: XunwuColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: XunwuColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: XunwuColors.mint, width: 1.5),
      ),
    ),
  );
}
