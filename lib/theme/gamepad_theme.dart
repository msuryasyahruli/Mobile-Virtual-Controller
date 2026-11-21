import 'package:flutter/material.dart';

/// Controller layout preset supported by the gamepad UI.
enum GamepadStyle {
  playstation,
  xbox,
}

/// Button & control size preset for user ergonomics.
enum GamepadButtonSize {
  smaller(scale: 0.86, shortLabel: 'S', label: 'Smaller'),
  normal(scale: 1.0, shortLabel: 'M', label: 'Normal'),
  larger(scale: 1.12, shortLabel: 'L', label: 'Larger');

  /// Multiplier applied to control dimensions relative to the base artboard.
  final double scale;

  /// Compact badge label shown on the top bar selector.
  final String shortLabel;

  /// Human-readable preset name.
  final String label;

  const GamepadButtonSize({
    required this.scale,
    required this.shortLabel,
    required this.label,
  });
}

/// Visual styling descriptor for a single face action button.
class GamepadActionToken {
  final String label;
  final Color accentColor;
  final double borderWidth;

  const GamepadActionToken({
    required this.label,
    required this.accentColor,
    required this.borderWidth,
  });
}

/// Complete design-token palette for PlayStation (DualSense) and Xbox Series
/// layouts in both Light Mode and Dark Mode.
class GamepadTheme {
  final GamepadStyle style;
  final bool isDark;

  final Color chassisBg;
  final Color buttonFill;
  final Color buttonBorder;
  final Color buttonPressedFill;
  final Color plateFill;
  final Color plateBorder;

  final Color dpadCapFill;
  final Color dpadCapBorder;
  final Color dpadArrowColor;

  final Color faceCapFill;
  final Color faceCapBorder;

  final Color stickSocketFill;
  final Color stickSocketBorder;
  final Color stickCapFill;
  final Color stickCapBorder;
  final Color stickIndentFill;
  final Color stickIndentBorder;
  final double stickIndentBorderWidth;

  final Color touchpadFill;
  final Color touchpadBorder;
  final Color touchpadLightbar;
  final Color touchpadLabel;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final GamepadActionToken actionTop;
  final GamepadActionToken actionRight;
  final GamepadActionToken actionBottom;
  final GamepadActionToken actionLeft;

  final Color homeFill;
  final Color homeBorder;
  final Color homeIcon;
  final Color muteLed;

  final Color statusAccent;
  final Color gripTrimColor;
  final Color disconnectColor;

  const GamepadTheme({
    required this.style,
    required this.isDark,
    required this.chassisBg,
    required this.buttonFill,
    required this.buttonBorder,
    required this.buttonPressedFill,
    required this.plateFill,
    required this.plateBorder,
    required this.dpadCapFill,
    required this.dpadCapBorder,
    required this.dpadArrowColor,
    required this.faceCapFill,
    required this.faceCapBorder,
    required this.stickSocketFill,
    required this.stickSocketBorder,
    required this.stickCapFill,
    required this.stickCapBorder,
    required this.stickIndentFill,
    required this.stickIndentBorder,
    required this.stickIndentBorderWidth,
    required this.touchpadFill,
    required this.touchpadBorder,
    required this.touchpadLightbar,
    required this.touchpadLabel,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.actionTop,
    required this.actionRight,
    required this.actionBottom,
    required this.actionLeft,
    required this.homeFill,
    required this.homeBorder,
    required this.homeIcon,
    required this.muteLed,
    required this.statusAccent,
    required this.gripTrimColor,
    required this.disconnectColor,
  });

  /// Returns the matching preset for [style] and [isDark].
  static GamepadTheme resolve(GamepadStyle style, bool isDark) {
    return switch ((style, isDark)) {
      (GamepadStyle.playstation, false) => playstationLight,
      (GamepadStyle.playstation, true) => playstationDark,
      (GamepadStyle.xbox, false) => xboxLight,
      (GamepadStyle.xbox, true) => xboxDark,
    };
  }

  /// PlayStation DualSense — Light Mode palette.
  static const GamepadTheme playstationLight = GamepadTheme(
    style: GamepadStyle.playstation,
    isDark: false,
    chassisBg: Color(0xFFFFFFFF),
    buttonFill: Color(0xFFEEF1F6),
    buttonBorder: Color(0xFFD2D8E4),
    buttonPressedFill: Color(0xFFE0E7F3),
    plateFill: Color(0xFFE8EDF5),
    plateBorder: Color(0xFFD2D8E6),
    dpadCapFill: Color(0xFFFFFFFF),
    dpadCapBorder: Color(0xFFCBD2DF),
    dpadArrowColor: Color(0xFF475569),
    faceCapFill: Color(0xFFFFFFFF),
    faceCapBorder: Color(0xFFCBD2DF),
    stickSocketFill: Color(0xFFE2E7F0),
    stickSocketBorder: Color(0xFFCBD2E0),
    stickCapFill: Color(0xFFFFFFFF),
    stickCapBorder: Color(0xFFCBD2E0),
    stickIndentFill: Color(0xFFF1F4F9),
    stickIndentBorder: Color(0xFFB8C2D3),
    stickIndentBorderWidth: 1.2,
    touchpadFill: Color(0xFFF1F4FA),
    touchpadBorder: Color(0xFFD5DBE8),
    touchpadLightbar: Color(0xFF0070D1),
    touchpadLabel: Color(0xFF8A94A6),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF8A94A6),
    actionTop: GamepadActionToken(
      label: '△',
      accentColor: Color(0xFF00C875),
      borderWidth: 1.5,
    ),
    actionRight: GamepadActionToken(
      label: '○',
      accentColor: Color(0xFFFF385C),
      borderWidth: 1.5,
    ),
    actionBottom: GamepadActionToken(
      label: '✕',
      accentColor: Color(0xFF0070D1),
      borderWidth: 1.5,
    ),
    actionLeft: GamepadActionToken(
      label: '□',
      accentColor: Color(0xFFC837AB),
      borderWidth: 1.5,
    ),
    homeFill: Color(0xFFFFFFFF),
    homeBorder: Color(0xFF0070D1),
    homeIcon: Color(0xFF0070D1),
    muteLed: Color(0xFFFFA000),
    statusAccent: Color(0xFF0070D1),
    gripTrimColor: Color(0xFFDDE3EE),
    disconnectColor: Color(0xFFE11D48),
  );

  /// PlayStation DualSense — Dark Mode palette.
  static const GamepadTheme playstationDark = GamepadTheme(
    style: GamepadStyle.playstation,
    isDark: true,
    chassisBg: Color(0xFF0B0C12),
    buttonFill: Color(0xFF181A26),
    buttonBorder: Color(0xFF2C3044),
    buttonPressedFill: Color(0xFF24283B),
    plateFill: Color(0xFF121420),
    plateBorder: Color(0xFF1E2235),
    dpadCapFill: Color(0xFF212538),
    dpadCapBorder: Color(0xFF2E334D),
    dpadArrowColor: Color(0xFFCBD5E1),
    faceCapFill: Color(0xFF202436),
    faceCapBorder: Color(0xFF2E334D),
    stickSocketFill: Color(0xFF0E1019),
    stickSocketBorder: Color(0xFF23273B),
    stickCapFill: Color(0xFF202436),
    stickCapBorder: Color(0xFF353B55),
    stickIndentFill: Color(0xFF161927),
    stickIndentBorder: Color(0xFF4A5376),
    stickIndentBorderWidth: 1.2,
    touchpadFill: Color(0xFF141724),
    touchpadBorder: Color(0xFF24283D),
    touchpadLightbar: Color(0xFF0070D1),
    touchpadLabel: Color(0xFF4A5270),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF4A5270),
    actionTop: GamepadActionToken(
      label: '△',
      accentColor: Color(0xFF00F5A0),
      borderWidth: 1.5,
    ),
    actionRight: GamepadActionToken(
      label: '○',
      accentColor: Color(0xFFFF4757),
      borderWidth: 1.5,
    ),
    actionBottom: GamepadActionToken(
      label: '✕',
      accentColor: Color(0xFF00A8FF),
      borderWidth: 1.5,
    ),
    actionLeft: GamepadActionToken(
      label: '□',
      accentColor: Color(0xFFE056FD),
      borderWidth: 1.5,
    ),
    homeFill: Color(0xFF181B28),
    homeBorder: Color(0xFF0070D1),
    homeIcon: Color(0xFFFFFFFF),
    muteLed: Color(0xFFFFA000),
    statusAccent: Color(0xFF00A8FF),
    gripTrimColor: Color(0xFF1C2032),
    disconnectColor: Color(0xFFFF4757),
  );

  /// Xbox Series — Light Mode (Robot White) palette.
  static const GamepadTheme xboxLight = GamepadTheme(
    style: GamepadStyle.xbox,
    isDark: false,
    chassisBg: Color(0xFFFFFFFF),
    buttonFill: Color(0xFFEEF1F6),
    buttonBorder: Color(0xFFD2D8E4),
    buttonPressedFill: Color(0xFFE0E8E2),
    plateFill: Color(0xFFE8EDF5),
    plateBorder: Color(0xFFD2D8E6),
    dpadCapFill: Color(0xFFFFFFFF),
    dpadCapBorder: Color(0xFFCBD2DF),
    dpadArrowColor: Color(0xFF475569),
    faceCapFill: Color(0xFFFFFFFF),
    faceCapBorder: Color(0xFFCBD2DF),
    stickSocketFill: Color(0xFFE2E7F0),
    stickSocketBorder: Color(0xFFCBD2E0),
    stickCapFill: Color(0xFFFFFFFF),
    stickCapBorder: Color(0xFFCBD2E0),
    stickIndentFill: Color(0xFFF1F4F9),
    stickIndentBorder: Color(0xFF107C10),
    stickIndentBorderWidth: 1.5,
    touchpadFill: Color(0xFFF1F4FA),
    touchpadBorder: Color(0xFFD5DBE8),
    touchpadLightbar: Color(0xFF107C10),
    touchpadLabel: Color(0xFF8A94A6),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF8A94A6),
    actionTop: GamepadActionToken(
      label: 'Y',
      accentColor: Color(0xFFFFB800),
      borderWidth: 2.0,
    ),
    actionRight: GamepadActionToken(
      label: 'B',
      accentColor: Color(0xFFE74C3C),
      borderWidth: 2.0,
    ),
    actionBottom: GamepadActionToken(
      label: 'A',
      accentColor: Color(0xFF107C10),
      borderWidth: 2.0,
    ),
    actionLeft: GamepadActionToken(
      label: 'X',
      accentColor: Color(0xFF0078D7),
      borderWidth: 2.0,
    ),
    homeFill: Color(0xFF107C10),
    homeBorder: Color(0xFF107C10),
    homeIcon: Color(0xFFFFFFFF),
    muteLed: Color(0xFFFFA000),
    statusAccent: Color(0xFF107C10),
    gripTrimColor: Color(0xFFDDE3EE),
    disconnectColor: Color(0xFFE74C3C),
  );

  /// Xbox Series — Dark Mode (Carbon Black) palette.
  static const GamepadTheme xboxDark = GamepadTheme(
    style: GamepadStyle.xbox,
    isDark: true,
    chassisBg: Color(0xFF0E1012),
    buttonFill: Color(0xFF1B1E23),
    buttonBorder: Color(0xFF2E333B),
    buttonPressedFill: Color(0xFF252A32),
    plateFill: Color(0xFF15181D),
    plateBorder: Color(0xFF262B33),
    dpadCapFill: Color(0xFF22262D),
    dpadCapBorder: Color(0xFF343A45),
    dpadArrowColor: Color(0xFFCBD5E1),
    faceCapFill: Color(0xFF1E2228),
    faceCapBorder: Color(0xFF343A45),
    stickSocketFill: Color(0xFF121418),
    stickSocketBorder: Color(0xFF262B33),
    stickCapFill: Color(0xFF22262D),
    stickCapBorder: Color(0xFF383E4A),
    stickIndentFill: Color(0xFF181B20),
    stickIndentBorder: Color(0xFF22C55E),
    stickIndentBorderWidth: 1.5,
    touchpadFill: Color(0xFF15181D),
    touchpadBorder: Color(0xFF262B33),
    touchpadLightbar: Color(0xFF22C55E),
    touchpadLabel: Color(0xFF64748B),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFFA1ABB8),
    textMuted: Color(0xFF64748B),
    actionTop: GamepadActionToken(
      label: 'Y',
      accentColor: Color(0xFFFACC15),
      borderWidth: 2.0,
    ),
    actionRight: GamepadActionToken(
      label: 'B',
      accentColor: Color(0xFFF43F5E),
      borderWidth: 2.0,
    ),
    actionBottom: GamepadActionToken(
      label: 'A',
      accentColor: Color(0xFF22C55E),
      borderWidth: 2.0,
    ),
    actionLeft: GamepadActionToken(
      label: 'X',
      accentColor: Color(0xFF38BDF8),
      borderWidth: 2.0,
    ),
    homeFill: Color(0xFF107C10),
    homeBorder: Color(0xFF22C55E),
    homeIcon: Color(0xFFFFFFFF),
    muteLed: Color(0xFFFFA000),
    statusAccent: Color(0xFF22C55E),
    gripTrimColor: Color(0xFF1F232A),
    disconnectColor: Color(0xFFF43F5E),
  );
}
