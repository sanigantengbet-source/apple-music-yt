import 'package:flutter/material.dart';

/// Exact Apple Music design system colors & styling tokens
class AppleMusicColors {
  // Brand accents
  static const Color accent = Color(0xFFFA243C); // Apple Music Signature Pinkish Red
  static const Color accentLight = Color(0xFFFF375F);
  static const Color accentGlow = Color(0x66FA243C);

  // Background tones (True Dark Mode matching iOS Apple Music)
  static const Color background = Color(0xFF000000); // True pitch black
  static const Color surface = Color(0xFF1C1C1E); // Apple system grouped background dark
  static const Color surfaceElevated = Color(0xFF2C2C2E); // Apple secondary surface
  static const Color card = Color(0xFF242426);
  static const Color miniPlayerBg = Color(0xE6252528); // Translucent glass fill

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);

  // Borders & Dividers
  static const Color divider = Color(0xFF38383A);
  static const Color subtleBorder = Color(0xFF2C2C2E);

  // Category tile gradient pairs (Exact Apple Music Search style)
  static const List<List<Color>> categoryGradients = [
    [Color(0xFFFF2D55), Color(0xFFFF375F)], // Pop / Red-Pink
    [Color(0xFF5856D6), Color(0xFF7977F5)], // Hip-Hop / Deep Purple
    [Color(0xFFFF9500), Color(0xFFFFAD33)], // R&B / Vibrant Orange
    [Color(0xFF34C759), Color(0xFF30D158)], // Dance / Electronic Neon Green
    [Color(0xFF007AFF), Color(0xFF0A84FF)], // Rock / Electric Blue
    [Color(0xFFAF52DE), Color(0xFFBF5AF2)], // Indie / Violet
    [Color(0xFFFF2D55), Color(0xFFFF6482)], // Latin / Hot Pink
    [Color(0xFF30B0C7), Color(0xFF40C8E0)], // Chill / Cyan
    [Color(0xFFFF3B30), Color(0xFFFF453A)], // Workout / Crimson
    [Color(0xFF5E5CE6), Color(0xFF6E6DF2)], // Focus / Indigo
    [Color(0xFFFFD60A), Color(0xFFFFDF33)], // Hits / Gold Yellow
    [Color(0xFF64D2FF), Color(0xFF70D7FF)], // Sleep / Soft Blue
  ];
}
