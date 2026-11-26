import 'package:flutter/material.dart';

/// Unified Brand Design Tokens for the Trackpad, Mouse & Keyboard Suite
/// (Midnight Navy, Amber, Deep Orange, Gold & Silver) in Dark and Light modes.
class PcSuiteTheme {
  final bool isDark;
  final Color chassisBg;

  final Color keyFill;
  final Color keyPressedFill;
  final Color keyBorder;
  final Color keyText;

  final Color modifierFill;
  final Color modifierBorder;
  final Color modifierText;

  final Color trackpadFill;
  final Color trackpadBorder;
  final Color trackpadCaption;
  final Color trackpadCrosshair;

  final Color statusPillFill;
  final Color statusPillBorder;
  final Color statusPillText;

  final Color modeSwitchFill;
  final Color modeSwitchBorder;
  final Color modeSwitchText;

  final Color ctaFill;
  final Color ctaPressedFill;
  final Color ctaBorder;
  final Color ctaText;

  final Color alertFill;
  final Color alertBorder;
  final Color alertText;

  final Color highlightFill;
  final Color highlightBorder;
  final Color highlightText;

  final Color shortcutFill;
  final Color shortcutBorder;
  final Color shortcutText;

  const PcSuiteTheme({
    required this.isDark,
    required this.chassisBg,
    required this.keyFill,
    required this.keyPressedFill,
    required this.keyBorder,
    required this.keyText,
    required this.modifierFill,
    required this.modifierBorder,
    required this.modifierText,
    required this.trackpadFill,
    required this.trackpadBorder,
    required this.trackpadCaption,
    required this.trackpadCrosshair,
    required this.statusPillFill,
    required this.statusPillBorder,
    required this.statusPillText,
    required this.modeSwitchFill,
    required this.modeSwitchBorder,
    required this.modeSwitchText,
    required this.ctaFill,
    required this.ctaPressedFill,
    required this.ctaBorder,
    required this.ctaText,
    required this.alertFill,
    required this.alertBorder,
    required this.alertText,
    required this.highlightFill,
    required this.highlightBorder,
    required this.highlightText,
    required this.shortcutFill,
    required this.shortcutBorder,
    required this.shortcutText,
  });

  /// Dark Mode (Primary): Midnight Navy & Gold.
  static const PcSuiteTheme dark = PcSuiteTheme(
    isDark: true,
    chassisBg: Color(0xFF0A1628),
    keyFill: Color(0xFF001F3F),
    keyPressedFill: Color(0xFF0A315B),
    keyBorder: Color(0xFFC0C0C0),
    keyText: Color(0xFFC0C0C0),
    modifierFill: Color(0xFF001F3F),
    modifierBorder: Color(0xFFC0C0C0),
    modifierText: Color(0xFFC0C0C0),
    trackpadFill: Color(0xFF001F3F),
    trackpadBorder: Color(0xFFC0C0C0),
    trackpadCaption: Color(0xFFC0C0C0),
    trackpadCrosshair: Color(0xFF1E3A5F),
    statusPillFill: Color(0xFF001F3F),
    statusPillBorder: Color(0xFFF59E0B),
    statusPillText: Color(0xFFFFD700),
    modeSwitchFill: Color(0xFF001F3F),
    modeSwitchBorder: Color(0xFFF59E0B),
    modeSwitchText: Color(0xFFFFD700),
    ctaFill: Color(0xFFF59E0B),
    ctaPressedFill: Color(0xFFD97706),
    ctaBorder: Color(0xFFEA580C),
    ctaText: Color(0xFF0A1628),
    alertFill: Color(0xFF001F3F),
    alertBorder: Color(0xFFEA580C),
    alertText: Color(0xFFEA580C),
    highlightFill: Color(0xFF001F3F),
    highlightBorder: Color(0xFFF59E0B),
    highlightText: Color(0xFFFFD700),
    shortcutFill: Color(0xFF001F3F),
    shortcutBorder: Color(0xFFC0C0C0),
    shortcutText: Color(0xFFC0C0C0),
  );

  /// Light Mode: Silver & Navy Accent.
  static const PcSuiteTheme light = PcSuiteTheme(
    isDark: false,
    chassisBg: Color(0xFFFFFFFF),
    keyFill: Color(0xFFF1F4FA),
    keyPressedFill: Color(0xFFDCE3F0),
    keyBorder: Color(0xFFC0C0C0),
    keyText: Color(0xFF001F3F),
    modifierFill: Color(0xFFEEF1F6),
    modifierBorder: Color(0xFFC0C0C0),
    modifierText: Color(0xFF001F3F),
    trackpadFill: Color(0xFFF1F4FA),
    trackpadBorder: Color(0xFFC0C0C0),
    trackpadCaption: Color(0xFF64748B),
    trackpadCrosshair: Color(0xFFCBD5E1),
    statusPillFill: Color(0xFFEEF1F6),
    statusPillBorder: Color(0xFFC0C0C0),
    statusPillText: Color(0xFF001F3F),
    modeSwitchFill: Color(0xFFFFFBEB),
    modeSwitchBorder: Color(0xFFF59E0B),
    modeSwitchText: Color(0xFFB45309),
    ctaFill: Color(0xFFF59E0B),
    ctaPressedFill: Color(0xFFD97706),
    ctaBorder: Color(0xFFEA580C),
    ctaText: Color(0xFF0A1628),
    alertFill: Color(0xFFFFF7ED),
    alertBorder: Color(0xFFEA580C),
    alertText: Color(0xFFEA580C),
    highlightFill: Color(0xFFFFFBEB),
    highlightBorder: Color(0xFFF59E0B),
    highlightText: Color(0xFFB45309),
    shortcutFill: Color(0xFFEEF1F6),
    shortcutBorder: Color(0xFFC0C0C0),
    shortcutText: Color(0xFF001F3F),
  );

  static PcSuiteTheme resolve(bool isDark) => isDark ? dark : light;
}
