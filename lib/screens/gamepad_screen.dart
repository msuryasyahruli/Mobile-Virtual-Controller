import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/gamepad_input.dart';
import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';
import '../widgets/pc_suite_parts.dart';
import '../widgets/quick_menu_drawer.dart';
import 'gamepad_layout_parts.dart';
import 'hybrid_wasd_trackpad_screen.dart';
import 'pc_keyboard_screen.dart';
import 'pc_trackpad_screen.dart';
import 'playstation_gamepad_screen.dart';
import 'switch_pro_gamepad_screen.dart';
import 'xbox_gamepad_screen.dart';

/// Host gamepad screen managing WebSocket input state, orientation lock,
/// wakelock, slide-over [QuickMenuDrawer], live HUD Edit Mode, and dispatching
/// to [PlayStationGamepadScreen], [XboxGamepadScreen], or [SwitchProGamepadScreen].
class GamepadScreen extends StatefulWidget {
  /// Optional initial layout preset override (defaults to persisted preference).
  final GamepadStyle? initialStyle;

  /// Creates [GamepadScreen].
  const GamepadScreen({super.key, this.initialStyle});

  @override
  State<GamepadScreen> createState() => _GamepadScreenState();
}

class _GamepadScreenState extends State<GamepadScreen> {
  final ConnectionService _connectionService = ConnectionService.instance;

  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<String?>? _errorSubscription;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  GamepadInput _input = const GamepadInput();

  late GamepadStyle _style;
  GamepadButtonSize _buttonSize = GamepadButtonSize.normal;
  bool _isDark = true;
  bool _hapticsEnabled = true;
  bool _gyroEnabled = false;
  double _deadzone = 0.05;
  double _hudOpacity = 0.85;

  bool _isQuickMenuOpen = false;
  bool _isEditingHud = false;

  @override
  void initState() {
    super.initState();
    _style = widget.initialStyle ?? GamepadStyle.playstation;
    _connectionStatus = _connectionService.currentStatus;
    _enterGamepadMode();
    _loadAppearancePrefs();
    _statusSubscription = _connectionService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = status;
      });
    });
    _errorSubscription = _connectionService.errorStream.listen((error) {
      if (!mounted || error == null || error.isEmpty) return;
      _updateInput(const GamepadInput());
      Navigator.of(context).pushReplacementNamed('/');
    });
  }

  /// Locks landscape (or allows portrait for the Trackpad), enables immersive mode, keeps screen awake.
  Future<void> _applyOrientationForStyle() {
    return SystemChrome.setPreferredOrientations(
      _style == GamepadStyle.pcTrackpad
          ? const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );
  }

  Future<void> _enterGamepadMode() async {
    await _applyOrientationForStyle();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
  }

  /// Restores portrait orientation and disables wakelock when leaving the screen.
  Future<void> _exitGamepadMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await WakelockPlus.disable();
  }

  /// Restores saved controller layout, button size, haptics, gyro, deadzone, and opacity.
  Future<void> _loadAppearancePrefs() async {
    final appearance = await GamepadAppearancePrefs.load();
    if (!mounted) return;
    setState(() {
      _style = widget.initialStyle ?? appearance.style;
      _isDark = appearance.isDark;
      _buttonSize = appearance.buttonSize;
      _hapticsEnabled = appearance.hapticsEnabled;
      _gyroEnabled = appearance.gyroEnabled;
      _deadzone = appearance.deadzone;
      _hudOpacity = appearance.hudOpacity;
    });
    _applyOrientationForStyle();
  }

  /// Persists all current appearance & control settings.
  Future<void> _saveAppearancePrefs() {
    return GamepadAppearancePrefs.save(
      style: _style,
      isDark: _isDark,
      buttonSize: _buttonSize,
      hapticsEnabled: _hapticsEnabled,
      gyroEnabled: _gyroEnabled,
      deadzone: _deadzone,
      hudOpacity: _hudOpacity,
    );
  }

  /// Opens the right-edge Quick Menu Drawer overlay.
  void _openQuickMenu() {
    GamepadHaptics.lightImpact();
    setState(() {
      _isEditingHud = false;
      _isQuickMenuOpen = true;
    });
  }

  /// Closes the Quick Menu Drawer and resumes multi-touch gamepad input.
  void _closeQuickMenu() {
    if (!_isQuickMenuOpen) return;
    setState(() {
      _isQuickMenuOpen = false;
    });
  }

  /// Selects a specific controller layout preset.
  void _setStyle(GamepadStyle nextStyle) {
    if (_style == nextStyle) return;
    GamepadHaptics.lightImpact();
    setState(() {
      _style = nextStyle;
    });
    _applyOrientationForStyle();
    _saveAppearancePrefs();
  }

  /// Updates the control size preset (Smaller / Normal / Larger).
  void _setButtonSize(GamepadButtonSize nextSize) {
    if (_buttonSize == nextSize) return;
    GamepadHaptics.lightImpact();
    setState(() {
      _buttonSize = nextSize;
    });
    _saveAppearancePrefs();
  }

  /// Toggles between Dark Mode (Primary) and Light Mode.
  void _toggleBrightness() {
    GamepadHaptics.lightImpact();
    setState(() {
      _isDark = !_isDark;
    });
    _saveAppearancePrefs();
  }

  /// Toggles global controller haptics on or off.
  void _toggleHaptics() {
    final next = !_hapticsEnabled;
    GamepadHaptics.enabled = next;
    if (next) {
      GamepadHaptics.lightImpact();
    }
    setState(() {
      _hapticsEnabled = next;
    });
    _saveAppearancePrefs();
  }

  /// Toggles gyro tilt steering mode on or off.
  void _toggleGyro() {
    GamepadHaptics.lightImpact();
    setState(() {
      _gyroEnabled = !_gyroEnabled;
    });
    _saveAppearancePrefs();
  }

  /// Updates analog stick radial deadzone live (`0%–25%`).
  void _setDeadzone(double value) {
    final clamped = value.clamp(0.0, 0.25).toDouble();
    if (clamped == _deadzone) return;
    setState(() {
      _deadzone = clamped;
    });
    _saveAppearancePrefs();
  }

  /// Updates HUD overlay opacity live (`20%–100%`).
  void _setHudOpacity(double value) {
    final clamped = value.clamp(0.20, 1.0).toDouble();
    if (clamped == _hudOpacity) return;
    setState(() {
      _hudOpacity = clamped;
    });
    _saveAppearancePrefs();
  }

  /// Closes the drawer and activates live HUD Layout Edit Mode (button size & reset).
  void _enterHudEditMode() {
    GamepadHaptics.lightImpact();
    setState(() {
      _isQuickMenuOpen = false;
      _isEditingHud = true;
    });
  }

  /// Exits HUD Layout Edit Mode and resumes gameplay.
  void _exitHudEditMode() {
    GamepadHaptics.lightImpact();
    setState(() {
      _isEditingHud = false;
    });
  }

  /// Resets HUD button size, deadzone, and opacity back to factory defaults.
  void _resetHudDefaults() {
    GamepadHaptics.lightImpact();
    setState(() {
      _buttonSize = GamepadButtonSize.normal;
      _deadzone = 0.05;
      _hudOpacity = 0.85;
    });
    _saveAppearancePrefs();
  }

  /// Updates the canonical [GamepadInput] state and sends JSON only on change.
  void _updateInput(GamepadInput nextInput) {
    if (nextInput == _input) return;
    _input = nextInput;
    _connectionService.sendInput(_input);
  }

  /// Resets all controls to neutral, closes the WebSocket, and opens PC Pairing (`/`).
  Future<void> _openPcPairing() async {
    GamepadHaptics.lightImpact();
    setState(() {
      _isQuickMenuOpen = false;
      _isEditingHud = false;
    });
    _updateInput(const GamepadInput());
    await _connectionService.disconnect();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  /// Returns status badge color and short text for the top status pill.
  GamepadStatusBadge _statusMeta(GamepadTheme theme) {
    final prefix = _style.statusPrefix;
    final gyroSuffix = (!_style.isPcSuite && _gyroEnabled) ? ' • GYRO' : '';
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return (color: theme.statusAccent, label: '$prefix • LIVE$gyroSuffix');
      case ConnectionStatus.reconnecting:
        return (
          color: const Color(0xFFD97706),
          label: '$prefix • SYNC$gyroSuffix',
        );
      case ConnectionStatus.disconnected:
        return (
          color: theme.disconnectColor,
          label: '$prefix • OFF$gyroSuffix',
        );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionService.sendInput(const GamepadInput());
    _exitGamepadMode();
    super.dispose();
  }

  /// Builds the active layout screen widget (PlayStation, Xbox, Switch Pro, or PC Suite).
  Widget _buildActiveGamepad(GamepadTheme theme, GamepadStatusBadge status) {
    final pcConfig = PcSuiteScreenConfig(
      theme: theme,
      hudOpacity: _hudOpacity,
      status: status,
      onOpenMenu: _openQuickMenu,
      onSwitchStyle: _setStyle,
    );

    return switch (_style) {
      GamepadStyle.playstation => PlayStationGamepadScreen(
          theme: theme,
          buttonSize: _buttonSize,
          deadzone: _deadzone,
          hudOpacity: _hudOpacity,
          status: status,
          serverIp: _connectionService.currentIp,
          serverPort: _connectionService.currentPort,
          getInput: () => _input,
          onInputChanged: _updateInput,
          onOpenMenu: _openQuickMenu,
        ),
      GamepadStyle.xbox => XboxGamepadScreen(
          theme: theme,
          buttonSize: _buttonSize,
          deadzone: _deadzone,
          hudOpacity: _hudOpacity,
          status: status,
          serverIp: _connectionService.currentIp,
          serverPort: _connectionService.currentPort,
          getInput: () => _input,
          onInputChanged: _updateInput,
          onOpenMenu: _openQuickMenu,
        ),
      GamepadStyle.nintendoSwitch => SwitchProGamepadScreen(
          theme: theme,
          buttonSize: _buttonSize,
          deadzone: _deadzone,
          hudOpacity: _hudOpacity,
          status: status,
          serverIp: _connectionService.currentIp,
          serverPort: _connectionService.currentPort,
          getInput: () => _input,
          onInputChanged: _updateInput,
          onOpenMenu: _openQuickMenu,
        ),
      GamepadStyle.pcTrackpad => PcTrackpadScreen(
          config: pcConfig,
          onMouseMove: _connectionService.sendMouseMove,
          onMouseButton: _connectionService.sendMouseButton,
          onMouseScroll: _connectionService.sendMouseScroll,
          onShortcut: _connectionService.sendShortcut,
          onTapKey: (key) {
            _connectionService.sendKeyEvent(key, true);
            _connectionService.sendKeyEvent(key, false);
          },
        ),
      GamepadStyle.pcKeyboardWin ||
      GamepadStyle.pcKeyboardMac =>
        PcKeyboardScreen(
          config: pcConfig,
          isMac: _style == GamepadStyle.pcKeyboardMac,
          onKeyEvent: (key, pressed, modifiers) =>
              _connectionService.sendKeyEvent(
            key,
            pressed,
            modifiers: modifiers,
          ),
          onShortcut: _connectionService.sendShortcut,
        ),
      GamepadStyle.hybridWasdTrackpad => HybridWasdTrackpadScreen(
          config: pcConfig,
          onKeyChanged: _connectionService.sendKeyEvent,
          onMouseMove: _connectionService.sendMouseMove,
          onMouseButton: _connectionService.sendMouseButton,
          onMouseScroll: _connectionService.sendMouseScroll,
        ),
    };
  }

  /// Compact floating toolbar shown when `EDIT HUD LAYOUT` mode is active.
  Widget _buildHudEditToolbar() {
    final tokens = QuickMenuTokens.resolve(_isDark);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14, left: 16, right: 16),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.editHudBorder, width: 1.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HUD EDIT',
                      style: TextStyle(
                        color: tokens.headerTitle,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 10),
                    for (final preset in GamepadButtonSize.values) ...[
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => _setButtonSize(preset),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: preset == _buttonSize
                                ? tokens.chipActiveFill
                                : tokens.chipIdleFill,
                            foregroundColor: preset == _buttonSize
                                ? tokens.chipActiveText
                                : tokens.chipIdleText,
                            side: BorderSide(
                              color: preset == _buttonSize
                                  ? tokens.chipActiveBorder
                                  : tokens.chipIdleBorder,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            preset.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: _resetHudDefaults,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: tokens.chipIdleFill,
                          foregroundColor: tokens.chipIdleText,
                          side: BorderSide(color: tokens.chipIdleBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: _exitHudEditMode,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: tokens.pairingFill,
                          foregroundColor: tokens.pairingText,
                          side: BorderSide(
                            color: tokens.pairingBorder,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GamepadTheme.resolve(_style, _isDark);
    final status = _statusMeta(theme);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Active controller layout screen (PlayStation / Xbox / Switch Pro).
        _buildActiveGamepad(theme, status),

        // Live HUD Edit toolbar when editing layout size/opacity.
        if (_isEditingHud) _buildHudEditToolbar(),

        // Slide-over Quick Menu Drawer overlay from the right edge.
        QuickMenuDrawer(
          isOpen: _isQuickMenuOpen,
          isDark: _isDark,
          activeStyle: _style,
          connectionStatus: _connectionStatus,
          hapticsEnabled: _hapticsEnabled,
          gyroEnabled: _gyroEnabled,
          deadzone: _deadzone,
          hudOpacity: _hudOpacity,
          onClose: _closeQuickMenu,
          onSelectStyle: _setStyle,
          onToggleTheme: _toggleBrightness,
          onToggleHaptics: _toggleHaptics,
          onToggleGyro: _toggleGyro,
          onDeadzoneChanged: _setDeadzone,
          onHudOpacityChanged: _setHudOpacity,
          onEditHudLayout: _enterHudEditMode,
          onOpenPcPairing: _openPcPairing,
        ),
      ],
    );
  }
}
