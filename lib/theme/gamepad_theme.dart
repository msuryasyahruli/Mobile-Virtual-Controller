import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized haptic controller wired to the Quick Menu Haptics toggle.
class GamepadHaptics {
  static bool enabled = true;

  /// Triggers a light haptic impact only when haptics are enabled.
  static void lightImpact() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  const GamepadHaptics._();
}

/// Shared border-radius scale enforcing deliberate hierarchy across screens.
class GamepadRadii {
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 16.0;
  static const double pill = 999.0;

  const GamepadRadii._();
}

/// Controller layout preset supported by the gamepad UI.
enum GamepadStyle {
  playstation(displayName: 'PlayStation', shortLabel: 'PS5'),
  xbox(displayName: 'Xbox', shortLabel: 'XBOX'),
  nintendoSwitch(displayName: 'Switch Pro', shortLabel: 'SWITCH');

  /// Human-readable preset name shown in menus and pickers.
  final String displayName;

  /// Compact badge label shown on the status bar.
  final String shortLabel;

  const GamepadStyle({
    required this.displayName,
    required this.shortLabel,
  });
}

/// Alias matching external layout preset naming conventions.
typedef GamepadLayout = GamepadStyle;

/// Button & control size preset for user ergonomics.
enum GamepadButtonSize {
  smaller(scale: 0.86, shortLabel: 'S', label: 'Smaller'),
  normal(scale: 1.0, shortLabel: 'M', label: 'Normal'),
  larger(scale: 1.12, shortLabel: 'L', label: 'Larger');

  /// Multiplier applied to control dimensions relative to the base artboard.
  final double scale;

  /// Compact badge label.
  final String shortLabel;

  /// Human-readable preset name.
  final String label;

  const GamepadButtonSize({
    required this.scale,
    required this.shortLabel,
    required this.label,
  });
}

/// Persisted UI preferences shared between [ConnectScreen] and [GamepadScreen].
class GamepadAppearancePrefs {
  static const String _styleKey = 'vcontrollers_ui_style';
  static const String _legacyStyleKey = 'wifi_gamepad_ui_style';
  static const String _darkKey = 'vcontrollers_ui_dark';
  static const String _legacyDarkKey = 'wifi_gamepad_ui_dark';
  static const String _sizeKey = 'vcontrollers_ui_button_size';
  static const String _legacySizeKey = 'wifi_gamepad_ui_button_size';
  static const String _hapticsKey = 'vcontrollers_ui_haptics';
  static const String _gyroKey = 'vcontrollers_ui_gyro';
  static const String _deadzoneKey = 'vcontrollers_ui_deadzone';
  static const String _opacityKey = 'vcontrollers_ui_opacity';

  final GamepadStyle style;
  final bool isDark;
  final GamepadButtonSize buttonSize;
  final bool hapticsEnabled;
  final bool gyroEnabled;
  final double deadzone;
  final double hudOpacity;

  const GamepadAppearancePrefs({
    this.style = GamepadStyle.playstation,
    this.isDark = true,
    this.buttonSize = GamepadButtonSize.normal,
    this.hapticsEnabled = true,
    this.gyroEnabled = false,
    this.deadzone = 0.05,
    this.hudOpacity = 0.85,
  });

  /// Loads saved appearance settings with fallback to legacy keys and defaults.
  static Future<GamepadAppearancePrefs> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStyle =
          prefs.getString(_styleKey) ?? prefs.getString(_legacyStyleKey);
      final savedDark =
          prefs.getBool(_darkKey) ?? prefs.getBool(_legacyDarkKey);
      final savedSize =
          prefs.getString(_sizeKey) ?? prefs.getString(_legacySizeKey);
      final savedHaptics = prefs.getBool(_hapticsKey);
      final savedGyro = prefs.getBool(_gyroKey);
      final savedDeadzone = prefs.getDouble(_deadzoneKey);
      final savedOpacity = prefs.getDouble(_opacityKey);

      var style = GamepadStyle.playstation;
      if (savedStyle != null) {
        for (final preset in GamepadStyle.values) {
          if (preset.name == savedStyle) {
            style = preset;
            break;
          }
        }
      }

      var size = GamepadButtonSize.normal;
      if (savedSize != null) {
        for (final preset in GamepadButtonSize.values) {
          if (preset.name == savedSize) {
            size = preset;
            break;
          }
        }
      }

      final haptics = savedHaptics ?? true;
      GamepadHaptics.enabled = haptics;

      return GamepadAppearancePrefs(
        style: style,
        isDark: savedDark ?? true,
        buttonSize: size,
        hapticsEnabled: haptics,
        gyroEnabled: savedGyro ?? false,
        deadzone: (savedDeadzone ?? 0.05).clamp(0.0, 0.25).toDouble(),
        hudOpacity: (savedOpacity ?? 0.85).clamp(0.20, 1.0).toDouble(),
      );
    } catch (_) {
      return const GamepadAppearancePrefs();
    }
  }

  /// Persists the current appearance settings to SharedPreferences.
  static Future<void> save({
    required GamepadStyle style,
    required bool isDark,
    required GamepadButtonSize buttonSize,
    bool? hapticsEnabled,
    bool? gyroEnabled,
    double? deadzone,
    double? hudOpacity,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_styleKey, style.name);
      await prefs.setBool(_darkKey, isDark);
      await prefs.setString(_sizeKey, buttonSize.name);
      if (hapticsEnabled != null) {
        GamepadHaptics.enabled = hapticsEnabled;
        await prefs.setBool(_hapticsKey, hapticsEnabled);
      }
      if (gyroEnabled != null) {
        await prefs.setBool(_gyroKey, gyroEnabled);
      }
      if (deadzone != null) {
        await prefs.setDouble(_deadzoneKey, deadzone.clamp(0.0, 0.25));
      }
      if (hudOpacity != null) {
        await prefs.setDouble(_opacityKey, hudOpacity.clamp(0.20, 1.0));
      }
    } catch (_) {
      // Ignore persistence errors safely.
    }
  }
}

/// Visual styling descriptor for a single face action button.
class GamepadActionToken {
  final String label;
  final Color accentColor;
  final Color? textColor;
  final double borderWidth;

  const GamepadActionToken({
    required this.label,
    required this.accentColor,
    required this.borderWidth,
    this.textColor,
  });

  /// Effective text/icon color, defaulting to [accentColor] when not overridden.
  Color get effectiveTextColor => textColor ?? accentColor;
}

/// Complete design-token palette for PlayStation (DualSense), Xbox Series,
/// and Nintendo Switch Pro layouts in both Light Mode and Dark Mode.
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
  final Color? leftStickIndentBorder;
  final Color? rightStickIndentBorder;
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
  final Color onStatusAccent;
  final Color? statusBadgeFill;
  final Color? statusBadgeBorder;
  final Color gripTrimColor;
  final Color disconnectColor;

  final Color? macroLeftFill;
  final Color? macroLeftBorder;
  final Color? macroLeftText;
  final Color? macroRightFill;
  final Color? macroRightBorder;
  final Color? macroRightText;

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
    required this.onStatusAccent,
    required this.gripTrimColor,
    required this.disconnectColor,
    this.leftStickIndentBorder,
    this.rightStickIndentBorder,
    this.statusBadgeFill,
    this.statusBadgeBorder,
    this.macroLeftFill,
    this.macroLeftBorder,
    this.macroLeftText,
    this.macroRightFill,
    this.macroRightBorder,
    this.macroRightText,
  });

  /// Effective inner rim border for the left thumbstick.
  Color get effectiveLeftStickIndentBorder =>
      leftStickIndentBorder ?? stickIndentBorder;

  /// Effective inner rim border for the right thumbstick.
  Color get effectiveRightStickIndentBorder =>
      rightStickIndentBorder ?? stickIndentBorder;

  /// Effective fill color for the top status badge pill.
  Color get effectiveStatusBadgeFill => statusBadgeFill ?? buttonFill;

  /// Effective border color for the top status badge pill.
  Color get effectiveStatusBadgeBorder => statusBadgeBorder ?? buttonBorder;

  /// Returns the matching preset for [style] and [isDark].
  static GamepadTheme resolve(GamepadStyle style, bool isDark) {
    return switch ((style, isDark)) {
      (GamepadStyle.playstation, false) => playstationLight,
      (GamepadStyle.playstation, true) => playstationDark,
      (GamepadStyle.xbox, false) => xboxLight,
      (GamepadStyle.xbox, true) => xboxDark,
      (GamepadStyle.nintendoSwitch, false) => nintendoSwitchLight,
      (GamepadStyle.nintendoSwitch, true) => nintendoSwitchDark,
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
    touchpadLabel: Color(0xFF5B6577),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF5B6577),
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
    onStatusAccent: Color(0xFFFFFFFF),
    gripTrimColor: Color(0xFFDDE3EE),
    disconnectColor: Color(0xFFC81E42),
    macroLeftFill: Color(0xFFEEF1F6),
    macroLeftBorder: Color(0xFF0070D1),
    macroLeftText: Color(0xFF005BB0),
    macroRightFill: Color(0xFFEEF1F6),
    macroRightBorder: Color(0xFF0070D1),
    macroRightText: Color(0xFF005BB0),
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
    touchpadLabel: Color(0xFF7D88A8),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF8A96AE),
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
    onStatusAccent: Color(0xFF0B0C12),
    gripTrimColor: Color(0xFF1C2032),
    disconnectColor: Color(0xFFFF6B7A),
    macroLeftFill: Color(0xFF121C2B),
    macroLeftBorder: Color(0xFF0070D1),
    macroLeftText: Color(0xFF60B4FF),
    macroRightFill: Color(0xFF121C2B),
    macroRightBorder: Color(0xFF0070D1),
    macroRightText: Color(0xFF60B4FF),
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
    touchpadLabel: Color(0xFF5B6577),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF5B6577),
    actionTop: GamepadActionToken(
      label: 'Y',
      accentColor: Color(0xFFFFB800),
      textColor: Color(0xFFB45309),
      borderWidth: 2.0,
    ),
    actionRight: GamepadActionToken(
      label: 'B',
      accentColor: Color(0xFFE74C3C),
      textColor: Color(0xFFC0392B),
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
    onStatusAccent: Color(0xFFFFFFFF),
    gripTrimColor: Color(0xFFDDE3EE),
    disconnectColor: Color(0xFFC0392B),
    macroLeftFill: Color(0xFFEEF1F6),
    macroLeftBorder: Color(0xFF107C10),
    macroLeftText: Color(0xFF0C660C),
    macroRightFill: Color(0xFFEEF1F6),
    macroRightBorder: Color(0xFF107C10),
    macroRightText: Color(0xFF0C660C),
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
    touchpadLabel: Color(0xFF8A96AE),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFFA1ABB8),
    textMuted: Color(0xFF8A96AE),
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
    onStatusAccent: Color(0xFF0E1012),
    gripTrimColor: Color(0xFF1F232A),
    disconnectColor: Color(0xFFFF6B81),
    macroLeftFill: Color(0xFF132219),
    macroLeftBorder: Color(0xFF22C55E),
    macroLeftText: Color(0xFF4ADE80),
    macroRightFill: Color(0xFF132219),
    macroRightBorder: Color(0xFF22C55E),
    macroRightText: Color(0xFF4ADE80),
  );

  /// Nintendo Switch Pro — Light Mode palette with Joy-Con dual stick accents.
  static const GamepadTheme nintendoSwitchLight = GamepadTheme(
    style: GamepadStyle.nintendoSwitch,
    isDark: false,
    chassisBg: Color(0xFFFFFFFF),
    buttonFill: Color(0xFFEEF1F6),
    buttonBorder: Color(0xFFD2D8E4),
    buttonPressedFill: Color(0xFFE3E8F2),
    plateFill: Color(0xFFE8EDF5),
    plateBorder: Color(0xFFD2D8E6),
    dpadCapFill: Color(0xFFFFFFFF),
    dpadCapBorder: Color(0xFFCBD2DF),
    dpadArrowColor: Color(0xFF334155),
    faceCapFill: Color(0xFFFFFFFF),
    faceCapBorder: Color(0xFFCBD2DF),
    stickSocketFill: Color(0xFFE2E7F0),
    stickSocketBorder: Color(0xFFCBD2E0),
    stickCapFill: Color(0xFFFFFFFF),
    stickCapBorder: Color(0xFFCBD2E0),
    stickIndentFill: Color(0xFFF1F4F9),
    stickIndentBorder: Color(0xFF0AB9E6),
    leftStickIndentBorder: Color(0xFF0AB9E6),
    rightStickIndentBorder: Color(0xFFFF3C28),
    stickIndentBorderWidth: 1.5,
    touchpadFill: Color(0xFFF1F4FA),
    touchpadBorder: Color(0xFFD5DBE8),
    touchpadLightbar: Color(0xFFE60012),
    touchpadLabel: Color(0xFF5B6577),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF5B6577),
    actionTop: GamepadActionToken(
      label: 'X',
      accentColor: Color(0xFF0AB9E6),
      textColor: Color(0xFF0284C7),
      borderWidth: 2.0,
    ),
    actionRight: GamepadActionToken(
      label: 'A',
      accentColor: Color(0xFFE60012),
      textColor: Color(0xFFE60012),
      borderWidth: 2.0,
    ),
    actionBottom: GamepadActionToken(
      label: 'B',
      accentColor: Color(0xFFF59E0B),
      textColor: Color(0xFFB45309),
      borderWidth: 2.0,
    ),
    actionLeft: GamepadActionToken(
      label: 'Y',
      accentColor: Color(0xFF10B981),
      textColor: Color(0xFF047857),
      borderWidth: 2.0,
    ),
    homeFill: Color(0xFFFFFFFF),
    homeBorder: Color(0xFFE60012),
    homeIcon: Color(0xFFE60012),
    muteLed: Color(0xFFFFA000),
    statusAccent: Color(0xFFE60012),
    onStatusAccent: Color(0xFFFFFFFF),
    statusBadgeFill: Color(0xFFEEF1F6),
    statusBadgeBorder: Color(0xFFD2D8E4),
    gripTrimColor: Color(0xFFDDE3EE),
    disconnectColor: Color(0xFFCC0010),
    macroLeftFill: Color(0xFFEEF1F6),
    macroLeftBorder: Color(0xFF0AB9E6),
    macroLeftText: Color(0xFF026AA7),
    macroRightFill: Color(0xFFEEF1F6),
    macroRightBorder: Color(0xFFFF3C28),
    macroRightText: Color(0xFFCC0010),
  );

  /// Nintendo Switch Pro — Dark Mode palette with Joy-Con dual stick accents.
  static const GamepadTheme nintendoSwitchDark = GamepadTheme(
    style: GamepadStyle.nintendoSwitch,
    isDark: true,
    chassisBg: Color(0xFF0E1012),
    buttonFill: Color(0xFF1B1E23),
    buttonBorder: Color(0xFF2E333B),
    buttonPressedFill: Color(0xFF262A32),
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
    stickIndentBorder: Color(0xFF0AB9E6),
    leftStickIndentBorder: Color(0xFF0AB9E6),
    rightStickIndentBorder: Color(0xFFFF3C28),
    stickIndentBorderWidth: 1.5,
    touchpadFill: Color(0xFF15181D),
    touchpadBorder: Color(0xFF262B33),
    touchpadLightbar: Color(0xFFFF3C28),
    touchpadLabel: Color(0xFF8A96AE),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFFA1ABB8),
    textMuted: Color(0xFF8A96AE),
    actionTop: GamepadActionToken(
      label: 'X',
      accentColor: Color(0xFF0AB9E6),
      textColor: Color(0xFF38BDF8),
      borderWidth: 2.0,
    ),
    actionRight: GamepadActionToken(
      label: 'A',
      accentColor: Color(0xFFFF3C28),
      textColor: Color(0xFFFF5C4B),
      borderWidth: 2.0,
    ),
    actionBottom: GamepadActionToken(
      label: 'B',
      accentColor: Color(0xFFFACC15),
      textColor: Color(0xFFFACC15),
      borderWidth: 2.0,
    ),
    actionLeft: GamepadActionToken(
      label: 'Y',
      accentColor: Color(0xFF22C55E),
      textColor: Color(0xFF22C55E),
      borderWidth: 2.0,
    ),
    homeFill: Color(0xFF261419),
    homeBorder: Color(0xFFFF3C28),
    homeIcon: Color(0xFFFF5C4B),
    muteLed: Color(0xFFFFA000),
    statusAccent: Color(0xFFFF5C4B),
    onStatusAccent: Color(0xFF0E1012),
    statusBadgeFill: Color(0xFF15181C),
    statusBadgeBorder: Color(0xFF262B33),
    gripTrimColor: Color(0xFF1F232A),
    disconnectColor: Color(0xFFFF6B5B),
    macroLeftFill: Color(0xFF12222E),
    macroLeftBorder: Color(0xFF0AB9E6),
    macroLeftText: Color(0xFF38BDF8),
    macroRightFill: Color(0xFF261419),
    macroRightBorder: Color(0xFFFF3C28),
    macroRightText: Color(0xFFFB7185),
  );
}
