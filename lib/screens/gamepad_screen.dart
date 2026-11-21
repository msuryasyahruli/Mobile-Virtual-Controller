import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/gamepad_input.dart';
import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';
import '../widgets/dedicated_stick_click_button.dart';
import '../widgets/gamepad_dpad.dart';
import '../widgets/gamepad_face_buttons.dart';
import '../widgets/gamepad_shoulder_button.dart';
import '../widgets/gamepad_thumbstick.dart';
import '../widgets/gamepad_touchpad.dart';

/// Landscape mobile gamepad screen supporting PlayStation (DualSense) and
/// Xbox Series layouts in both Light Mode and Dark Mode with true multi-touch.
class GamepadScreen extends StatefulWidget {
  /// Creates [GamepadScreen].
  const GamepadScreen({super.key});

  @override
  State<GamepadScreen> createState() => _GamepadScreenState();
}

class _GamepadScreenState extends State<GamepadScreen> {
  static const double _artboardWidth = 852.0;
  static const double _artboardHeight = 393.0;
  static const String _prefStyleKey = 'wifi_gamepad_ui_style';
  static const String _prefDarkKey = 'wifi_gamepad_ui_dark';
  static const String _prefButtonSizeKey = 'wifi_gamepad_ui_button_size';

  final ConnectionService _connectionService = ConnectionService.instance;

  StreamSubscription<ConnectionStatus>? _statusSubscription;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  GamepadInput _input = const GamepadInput();

  GamepadStyle _style = GamepadStyle.playstation;
  GamepadButtonSize _buttonSize = GamepadButtonSize.normal;
  bool _isDark = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _connectionStatus = _connectionService.currentStatus;
    _enterGamepadMode();
    _loadAppearancePrefs();
    _statusSubscription = _connectionService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = status;
      });
    });
  }

  /// Locks landscape orientation, enables immersive full-bleed mode, and keeps screen awake.
  Future<void> _enterGamepadMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

  /// Restores saved PlayStation/Xbox layout, button size, and Light/Dark preference.
  Future<void> _loadAppearancePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStyle = prefs.getString(_prefStyleKey);
      final savedDark = prefs.getBool(_prefDarkKey);
      final savedSize = prefs.getString(_prefButtonSizeKey);
      if (!mounted) return;
      setState(() {
        if (savedStyle == GamepadStyle.xbox.name) {
          _style = GamepadStyle.xbox;
        } else if (savedStyle == GamepadStyle.playstation.name) {
          _style = GamepadStyle.playstation;
        }
        if (savedDark != null) {
          _isDark = savedDark;
        }
        if (savedSize != null) {
          for (final preset in GamepadButtonSize.values) {
            if (preset.name == savedSize) {
              _buttonSize = preset;
              break;
            }
          }
        }
      });
    } catch (_) {
      // Fall back to default preset if SharedPreferences is unavailable.
    }
  }

  /// Persists the selected layout style, button size, and theme mode.
  Future<void> _saveAppearancePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefStyleKey, _style.name);
      await prefs.setBool(_prefDarkKey, _isDark);
      await prefs.setString(_prefButtonSizeKey, _buttonSize.name);
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  /// Toggles seamlessly between PlayStation and Xbox controller layouts.
  void _toggleStyle() {
    HapticFeedback.lightImpact();
    setState(() {
      _style = _style == GamepadStyle.playstation
          ? GamepadStyle.xbox
          : GamepadStyle.playstation;
    });
    _saveAppearancePrefs();
  }

  /// Updates the control size preset (Smaller / Normal / Larger).
  void _setButtonSize(GamepadButtonSize nextSize) {
    if (_buttonSize == nextSize) return;
    HapticFeedback.lightImpact();
    setState(() {
      _buttonSize = nextSize;
    });
    _saveAppearancePrefs();
  }

  /// Toggles seamlessly between Light Mode and Dark Mode.
  void _toggleBrightness() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDark = !_isDark;
    });
    _saveAppearancePrefs();
  }

  /// Updates the canonical [GamepadInput] state and sends JSON only on change.
  void _updateInput(GamepadInput nextInput) {
    if (nextInput == _input) return;
    _input = nextInput;
    _connectionService.sendInput(_input);
  }

  /// Resets all controls to neutral, closes the WebSocket, and returns to ConnectScreen.
  Future<void> _handleDisconnect() async {
    HapticFeedback.lightImpact();
    _updateInput(const GamepadInput());
    await _connectionService.disconnect();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  /// Returns status badge color and short text for the center top status pill.
  ({Color color, String label}) _statusMeta(GamepadTheme theme) {
    final prefix = _style == GamepadStyle.playstation ? 'PS5' : 'XBOX';
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return (color: theme.statusAccent, label: '$prefix • LIVE');
      case ConnectionStatus.reconnecting:
        return (color: const Color(0xFFFFA000), label: '$prefix • SYNC');
      case ConnectionStatus.disconnected:
        return (color: theme.disconnectColor, label: '$prefix • OFF');
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _connectionService.sendInput(const GamepadInput());
    _exitGamepadMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GamepadTheme.resolve(_style, _isDark);
    final isPlayStation = _style == GamepadStyle.playstation;

    // Symmetric horizontal padding strictly larger than notch / status bar so the
    // controller always stays centered even with asymmetric display cutouts.
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final notchOrStatusBar = [
      viewPadding.left,
      viewPadding.right,
      mediaPadding.left,
      mediaPadding.right,
      viewPadding.top,
      mediaPadding.top,
    ].reduce(math.max);
    final horizontalSafePadding = math.max(notchOrStatusBar + 16.0, 48.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.chassisBg,
        body: SafeArea(
          left: false,
          right: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalSafePadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availW = constraints.maxWidth;
                final availH = constraints.maxHeight;
                final scale = math.min(
                  availW / _artboardWidth,
                  availH / _artboardHeight,
                );
                final boardW = _artboardWidth * scale;
                final boardH = _artboardHeight * scale;
                double s(double v) => v * scale;

                return Center(
                  child: SizedBox(
                    width: boardW,
                    height: boardH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Shared top bar: L2/LT, L1/LB | Status + Quick toggles | R1/RB, R2/RT.
                        _buildTopBar(theme: theme, s: s),

                        // Main PlayStation or Xbox control deck.
                        if (isPlayStation)
                          ..._buildPlayStationControls(theme: theme, s: s)
                        else
                          ..._buildXboxControls(theme: theme, s: s),

                        // Subtle bottom ergonomic grip trim bars (140x6, radius 3).
                        Positioned(
                          left: s(40),
                          bottom: s(6),
                          child: Container(
                            width: s(140),
                            height: s(6),
                            decoration: BoxDecoration(
                              color: theme.gripTrimColor,
                              borderRadius: BorderRadius.circular(s(3)),
                            ),
                          ),
                        ),
                        Positioned(
                          right: s(40),
                          bottom: s(6),
                          child: Container(
                            width: s(140),
                            height: s(6),
                            decoration: BoxDecoration(
                              color: theme.gripTrimColor,
                              borderRadius: BorderRadius.circular(s(3)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Places a control centered on artboard coordinates `(cx, cy)` so changing
  /// button size grows/shrinks symmetrically without shifting its anchor.
  Widget _centered({
    required double Function(double) s,
    required double cx,
    required double cy,
    required double width,
    required double height,
    required Widget child,
  }) {
    return Positioned(
      left: s(cx) - width / 2,
      top: s(cy) - height / 2,
      child: child,
    );
  }

  /// Builds the shared top bar with shoulder/trigger buttons, status pill, and appearance controls.
  Widget _buildTopBar({
    required GamepadTheme theme,
    required double Function(double) s,
  }) {
    final isPS = _style == GamepadStyle.playstation;
    final status = _statusMeta(theme);
    final bs = _buttonSize.scale;
    final shoulderHeight = s((32 * bs).clamp(26.0, 36.0));
    final triggerWidth = s(72 * bs);
    final bumperWidth = s(64 * bs);

    return Positioned(
      top: s(8),
      left: s(20),
      right: s(20),
      height: s(36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left shoulder buttons: L2/LT + L1/LB.
          GamepadShoulderButton(
            theme: theme,
            label: isPS ? 'L2' : 'LT',
            width: triggerWidth,
            height: shoulderHeight,
            borderRadius: s(8),
            onPressed: (down) =>
                _updateInput(_input.copyWith(lt: down ? 1.0 : 0.0)),
          ),
          SizedBox(width: s(8)),
          GamepadShoulderButton(
            theme: theme,
            label: isPS ? 'L1' : 'LB',
            width: bumperWidth,
            height: shoulderHeight,
            borderRadius: s(8),
            onPressed: (down) => _updateInput(_input.copyWith(lb: down)),
          ),

          // Center bar: Style toggle, Size (S/M/L) selector, Status pill, Light/Dark, Disconnect.
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: s(6)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TopActionChip(
                      theme: theme,
                      height: s(24),
                      borderRadius: s(12),
                      horizontalPadding: s(9),
                      onTap: _toggleStyle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_esports_rounded,
                            size: s(12),
                            color: theme.statusAccent,
                          ),
                          SizedBox(width: s(4)),
                          Text(
                            isPS ? 'PS5' : 'XBOX',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: s(9.5),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: s(6)),

                    // Button size segmented selector: S (Smaller) / M (Normal) / L (Larger).
                    _ButtonSizeSelector(
                      theme: theme,
                      selected: _buttonSize,
                      height: s(24),
                      borderRadius: s(12),
                      segmentWidth: s(22),
                      fontSize: s(9),
                      onSelected: _setButtonSize,
                    ),
                    SizedBox(width: s(6)),

                    // Connection status pill (116x24, radius 12).
                    Container(
                      width: s(116),
                      height: s(24),
                      padding: EdgeInsets.symmetric(horizontal: s(8)),
                      decoration: BoxDecoration(
                        color: theme.buttonFill,
                        borderRadius: BorderRadius.circular(s(12)),
                        border: Border.all(
                          color: theme.buttonBorder,
                          width: 1.0,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: s(6.5),
                              height: s(6.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: status.color,
                                boxShadow: [
                                  BoxShadow(
                                    color: status.color.withValues(alpha: 0.55),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: s(6)),
                            Text(
                              status.label,
                              style: TextStyle(
                                color: status.color,
                                fontSize: s(10),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: s(6)),

                    // Light / Dark Mode toggle.
                    _TopActionChip(
                      theme: theme,
                      width: s(28),
                      height: s(24),
                      borderRadius: s(12),
                      onTap: _toggleBrightness,
                      child: Icon(
                        _isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: s(13),
                        color: theme.textPrimary,
                      ),
                    ),
                    SizedBox(width: s(6)),

                    // Disconnect button.
                    _TopActionChip(
                      theme: theme,
                      width: s(28),
                      height: s(24),
                      borderRadius: s(12),
                      borderColorOverride:
                          theme.disconnectColor.withValues(alpha: 0.55),
                      onTap: _handleDisconnect,
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        size: s(13),
                        color: theme.disconnectColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right shoulder buttons: R1/RB + R2/RT.
          GamepadShoulderButton(
            theme: theme,
            label: isPS ? 'R1' : 'RB',
            width: bumperWidth,
            height: shoulderHeight,
            borderRadius: s(8),
            onPressed: (down) => _updateInput(_input.copyWith(rb: down)),
          ),
          SizedBox(width: s(8)),
          GamepadShoulderButton(
            theme: theme,
            label: isPS ? 'R2' : 'RT',
            width: triggerWidth,
            height: shoulderHeight,
            borderRadius: s(8),
            onPressed: (down) =>
                _updateInput(_input.copyWith(rt: down ? 1.0 : 0.0)),
          ),
        ],
      ),
    );
  }

  /// Builds PlayStation DualSense symmetric control clusters relative to 852x393.
  List<Widget> _buildPlayStationControls({
    required GamepadTheme theme,
    required double Function(double) s,
  }) {
    final bs = _buttonSize.scale;
    double b(double v) => s(v * bs);

    final dpadSize = b(144);
    final plateSize = b(144);
    final faceBtnSize = b(44);
    final stickSocket = b(96);
    final stickCap = b(64);
    final stickIndent = b(36);
    final clickW = b(48);
    final clickH = b(36);
    final utilW = b(44);
    final utilH = b(26);
    final homeSize = b(40);

    return [
      // Left Cluster — Top-left recessed D-Pad (center 114, 138).
      _centered(
        s: s,
        cx: 114,
        cy: 138,
        width: dpadSize,
        height: dpadSize,
        child: GamepadDPad(
          theme: theme,
          size: dpadSize,
          onChanged: (up, down, left, right) => _updateInput(
            _input.copyWith(
              dpadUp: up,
              dpadDown: down,
              dpadLeft: left,
              dpadRight: right,
            ),
          ),
        ),
      ),

      // Left Cluster — Lower-outer dedicated L3 pill button (center 82, 284).
      _centered(
        s: s,
        cx: 82,
        cy: 284,
        width: clickW,
        height: clickH,
        child: DedicatedStickClickButton(
          theme: theme,
          label: 'L3',
          width: clickW,
          height: clickH,
          borderRadius: b(10),
          onPressed: (down) => _updateInput(_input.copyWith(l3: down)),
        ),
      ),

      // Left Cluster — Lower-inner Left Analog Stick (center 224, 276).
      _centered(
        s: s,
        cx: 224,
        cy: 276,
        width: stickSocket,
        height: stickSocket,
        child: GamepadThumbstick(
          theme: theme,
          socketSize: stickSocket,
          capSize: stickCap,
          indentSize: stickIndent,
          onChanged: (offset) => _updateInput(
            _input.copyWith(lx: offset.dx, ly: offset.dy),
          ),
        ),
      ),

      // Center — SHARE pill (center 250, 89) left of touchpad top.
      _centered(
        s: s,
        cx: 250,
        cy: 89,
        width: utilW,
        height: utilH,
        child: _UtilityMultiTouchButton(
          theme: theme,
          width: utilW,
          height: utilH,
          borderRadius: b(6),
          onPressed: (down) => _updateInput(_input.copyWith(select: down)),
          child: Text(
            'SHARE',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: b(8.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),

      // Center — DualSense Touchpad (280x160, radius 16) with blue lightbar.
      Positioned(
        left: s(286),
        top: s(68),
        child: GamepadTouchpad(
          theme: theme,
          width: s(280),
          height: s(160),
          borderRadius: s(16),
          onPressed: (down) => _updateInput(_input.copyWith(select: down)),
        ),
      ),

      // Center — OPTIONS pill (center 602, 89) right of touchpad top.
      _centered(
        s: s,
        cx: 602,
        cy: 89,
        width: utilW,
        height: utilH,
        child: _UtilityMultiTouchButton(
          theme: theme,
          width: utilW,
          height: utilH,
          borderRadius: b(6),
          onPressed: (down) => _updateInput(_input.copyWith(start: down)),
          child: Text(
            'OPT',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: b(8.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),

      // Center — Circular PS Home button (center 426, 272) below touchpad.
      _centered(
        s: s,
        cx: 426,
        cy: 272,
        width: homeSize,
        height: homeSize,
        child: _HomeGuideButton(
          theme: theme,
          size: homeSize,
          isXbox: false,
          onTap: _toggleStyle,
        ),
      ),

      // Center — Amber Mute LED pill (16x6) underneath PS Home button.
      Positioned(
        left: s(418),
        top: s(304),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isMuted = !_isMuted);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: s(16),
            height: s(6),
            decoration: BoxDecoration(
              color: _isMuted
                  ? theme.muteLed
                  : theme.muteLed.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(s(3)),
              boxShadow: [
                BoxShadow(
                  color: theme.muteLed.withValues(alpha: _isMuted ? 0.85 : 0.45),
                  blurRadius: _isMuted ? 8 : 5,
                ),
              ],
            ),
          ),
        ),
      ),

      // Center — Subtle connected IP caption near bottom.
      if (_connectionService.currentIp != null &&
          _connectionService.currentIp!.isNotEmpty)
        Positioned(
          left: s(326),
          right: s(326),
          top: s(326),
          child: Text(
            '${_connectionService.currentIp}:${ConnectionService.serverPort}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: s(9.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),

      // Right Cluster — Top-right Face Button plate (center 738, 138).
      _centered(
        s: s,
        cx: 738,
        cy: 138,
        width: plateSize,
        height: plateSize,
        child: GamepadFaceButtons(
          theme: theme,
          plateSize: plateSize,
          buttonSize: faceBtnSize,
          onTopChanged: (down) => _updateInput(_input.copyWith(y: down)),
          onRightChanged: (down) => _updateInput(_input.copyWith(b: down)),
          onBottomChanged: (down) => _updateInput(_input.copyWith(a: down)),
          onLeftChanged: (down) => _updateInput(_input.copyWith(x: down)),
        ),
      ),

      // Right Cluster — Lower-inner Right Analog Stick (center 628, 276).
      _centered(
        s: s,
        cx: 628,
        cy: 276,
        width: stickSocket,
        height: stickSocket,
        child: GamepadThumbstick(
          theme: theme,
          socketSize: stickSocket,
          capSize: stickCap,
          indentSize: stickIndent,
          onChanged: (offset) => _updateInput(
            _input.copyWith(rx: offset.dx, ry: offset.dy),
          ),
        ),
      ),

      // Right Cluster — Lower-outer dedicated R3 pill button (center 770, 284).
      _centered(
        s: s,
        cx: 770,
        cy: 284,
        width: clickW,
        height: clickH,
        child: DedicatedStickClickButton(
          theme: theme,
          label: 'R3',
          width: clickW,
          height: clickH,
          borderRadius: b(10),
          onPressed: (down) => _updateInput(_input.copyWith(r3: down)),
        ),
      ),
    ];
  }

  /// Builds Xbox Series asymmetric control clusters relative to 852x393.
  List<Widget> _buildXboxControls({
    required GamepadTheme theme,
    required double Function(double) s,
  }) {
    final bs = _buttonSize.scale;
    double b(double v) => s(v * bs);

    final stickSocket = b(96);
    final stickCap = b(64);
    final stickIndent = b(36);
    final dpadSize = b(132);
    final plateSize = b(144);
    final faceBtnSize = b(44);
    final clickW = b(48);
    final clickH = b(36);
    final viewW = b(36);
    final viewH = b(26);
    final shareW = b(28);
    final shareH = b(20);
    final homeSize = b(40);

    return [
      // Left Cluster — Top-left Left Analog Stick (center 114, 130).
      _centered(
        s: s,
        cx: 114,
        cy: 130,
        width: stickSocket,
        height: stickSocket,
        child: GamepadThumbstick(
          theme: theme,
          socketSize: stickSocket,
          capSize: stickCap,
          indentSize: stickIndent,
          onChanged: (offset) => _updateInput(
            _input.copyWith(lx: offset.dx, ly: offset.dy),
          ),
        ),
      ),

      // Left Cluster — Lower-outer dedicated LS pill button (center 90, 284).
      _centered(
        s: s,
        cx: 90,
        cy: 284,
        width: clickW,
        height: clickH,
        child: DedicatedStickClickButton(
          theme: theme,
          label: 'LS',
          width: clickW,
          height: clickH,
          borderRadius: b(10),
          onPressed: (down) => _updateInput(_input.copyWith(l3: down)),
        ),
      ),

      // Left Cluster — Lower-inner Enlarged Hybrid D-Pad dish (center 244, 268).
      _centered(
        s: s,
        cx: 244,
        cy: 268,
        width: dpadSize,
        height: dpadSize,
        child: GamepadDPad(
          theme: theme,
          size: dpadSize,
          onChanged: (up, down, left, right) => _updateInput(
            _input.copyWith(
              dpadUp: up,
              dpadDown: down,
              dpadLeft: left,
              dpadRight: right,
            ),
          ),
        ),
      ),

      // Center — View button (center 366, 160) left of Xbox Guide.
      _centered(
        s: s,
        cx: 366,
        cy: 160,
        width: viewW,
        height: viewH,
        child: _UtilityMultiTouchButton(
          theme: theme,
          width: viewW,
          height: viewH,
          borderRadius: b(8),
          onPressed: (down) => _updateInput(_input.copyWith(select: down)),
          child: Icon(
            Icons.filter_none_rounded,
            size: b(13),
            color: theme.textPrimary,
          ),
        ),
      ),

      // Center — Circular Xbox Guide / Nexus sphere (center 426, 160).
      _centered(
        s: s,
        cx: 426,
        cy: 160,
        width: homeSize,
        height: homeSize,
        child: _HomeGuideButton(
          theme: theme,
          size: homeSize,
          isXbox: true,
          onTap: _toggleStyle,
        ),
      ),

      // Center — Menu button (center 486, 160) right of Xbox Guide.
      _centered(
        s: s,
        cx: 486,
        cy: 160,
        width: viewW,
        height: viewH,
        child: _UtilityMultiTouchButton(
          theme: theme,
          width: viewW,
          height: viewH,
          borderRadius: b(8),
          onPressed: (down) => _updateInput(_input.copyWith(start: down)),
          child: Icon(
            Icons.menu_rounded,
            size: b(15),
            color: theme.textPrimary,
          ),
        ),
      ),

      // Center — Share button (center 426, 214) centered below Xbox Guide.
      _centered(
        s: s,
        cx: 426,
        cy: 214,
        width: shareW,
        height: shareH,
        child: _UtilityMultiTouchButton(
          theme: theme,
          width: shareW,
          height: shareH,
          borderRadius: b(6),
          onPressed: (down) => _updateInput(_input.copyWith(select: down)),
          child: Icon(
            Icons.ios_share_rounded,
            size: b(11),
            color: theme.textSecondary,
          ),
        ),
      ),

      // Center — Subtle connected IP caption below Share.
      if (_connectionService.currentIp != null &&
          _connectionService.currentIp!.isNotEmpty)
        Positioned(
          left: s(326),
          right: s(326),
          top: s(248),
          child: Text(
            '${_connectionService.currentIp}:${ConnectionService.serverPort}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: s(9.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),

      // Right Cluster — Top-right Face Button plate (center 738, 138).
      _centered(
        s: s,
        cx: 738,
        cy: 138,
        width: plateSize,
        height: plateSize,
        child: GamepadFaceButtons(
          theme: theme,
          plateSize: plateSize,
          buttonSize: faceBtnSize,
          onTopChanged: (down) => _updateInput(_input.copyWith(y: down)),
          onRightChanged: (down) => _updateInput(_input.copyWith(b: down)),
          onBottomChanged: (down) => _updateInput(_input.copyWith(a: down)),
          onLeftChanged: (down) => _updateInput(_input.copyWith(x: down)),
        ),
      ),

      // Right Cluster — Lower-inner Right Analog Stick (center 628, 276).
      _centered(
        s: s,
        cx: 628,
        cy: 276,
        width: stickSocket,
        height: stickSocket,
        child: GamepadThumbstick(
          theme: theme,
          socketSize: stickSocket,
          capSize: stickCap,
          indentSize: stickIndent,
          onChanged: (offset) => _updateInput(
            _input.copyWith(rx: offset.dx, ry: offset.dy),
          ),
        ),
      ),

      // Right Cluster — Lower-outer dedicated RS pill button (center 770, 284).
      _centered(
        s: s,
        cx: 770,
        cy: 284,
        width: clickW,
        height: clickH,
        child: DedicatedStickClickButton(
          theme: theme,
          label: 'RS',
          width: clickW,
          height: clickH,
          borderRadius: b(10),
          onPressed: (down) => _updateInput(_input.copyWith(r3: down)),
        ),
      ),
    ];
  }
}

/// Multi-touch utility button used for SHARE, OPTIONS, View, Menu, and Share controls.
class _UtilityMultiTouchButton extends StatefulWidget {
  final GamepadTheme theme;
  final double width;
  final double height;
  final double borderRadius;
  final ValueChanged<bool> onPressed;
  final Widget child;

  const _UtilityMultiTouchButton({
    required this.theme,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_UtilityMultiTouchButton> createState() =>
      _UtilityMultiTouchButtonState();
}

class _UtilityMultiTouchButtonState extends State<_UtilityMultiTouchButton> {
  final Set<int> _activePointers = {};

  bool get _isPressed => _activePointers.isNotEmpty;

  void _handleDown(PointerDownEvent event) {
    final wasPressed = _isPressed;
    _activePointers.add(event.pointer);
    if (!wasPressed) {
      setState(() {});
      HapticFeedback.lightImpact();
      widget.onPressed(true);
    }
  }

  void _handleEnd(int pointerId) {
    if (!_activePointers.remove(pointerId)) return;
    if (!_isPressed) {
      setState(() {});
      widget.onPressed(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final accent = theme.statusAccent;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleDown,
      onPointerUp: (e) => _handleEnd(e.pointer),
      onPointerCancel: (e) => _handleEnd(e.pointer),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 65),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isPressed ? theme.buttonPressedFill : theme.buttonFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed ? accent : theme.buttonBorder,
              width: _isPressed ? 1.3 : 1.0,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Circular PlayStation Home or Xbox Guide / Nexus sphere button (40x40 reference).
class _HomeGuideButton extends StatefulWidget {
  final GamepadTheme theme;
  final double size;
  final bool isXbox;
  final VoidCallback onTap;

  const _HomeGuideButton({
    required this.theme,
    required this.size,
    required this.isXbox,
    required this.onTap,
  });

  @override
  State<_HomeGuideButton> createState() => _HomeGuideButtonState();
}

class _HomeGuideButtonState extends State<_HomeGuideButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onPointerUp: (_) {
        if (_isPressed) {
          setState(() => _isPressed = false);
          widget.onTap();
        }
      },
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 65),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.homeFill,
            border: Border.all(
              color: theme.homeBorder,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.homeBorder.withValues(
                  alpha: _isPressed ? 0.55 : 0.25,
                ),
                blurRadius: _isPressed ? 14 : 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isXbox
              ? CustomPaint(
                  size: Size.square(widget.size * 0.48),
                  painter: _XboxNexusPainter(color: theme.homeIcon),
                )
              : Text(
                  'PS',
                  style: TextStyle(
                    color: theme.homeIcon,
                    fontSize: widget.size * 0.34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Draws the signature curved X emblem inside the Xbox Guide sphere.
class _XboxNexusPainter extends CustomPainter {
  final Color color;

  const _XboxNexusPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 0.14).clamp(2.0, 3.0)
      ..strokeCap = StrokeCap.round;

    final leftCurve = Path()
      ..moveTo(size.width * 0.16, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.45,
        size.width * 0.84,
        size.height * 0.86,
      );

    final rightCurve = Path()
      ..moveTo(size.width * 0.84, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.45,
        size.width * 0.16,
        size.height * 0.86,
      );

    canvas.drawPath(leftCurve, paint);
    canvas.drawPath(rightCurve, paint);
  }

  @override
  bool shouldRepaint(covariant _XboxNexusPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Compact pill control in the top status bar for quick style, theme, and disconnect actions.
class _TopActionChip extends StatelessWidget {
  final GamepadTheme theme;
  final double? width;
  final double height;
  final double borderRadius;
  final double horizontalPadding;
  final Color? borderColorOverride;
  final VoidCallback onTap;
  final Widget child;

  const _TopActionChip({
    required this.theme,
    required this.height,
    required this.borderRadius,
    required this.onTap,
    required this.child,
    this.width,
    this.horizontalPadding = 0,
    this.borderColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: theme.buttonFill,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColorOverride ?? theme.buttonBorder,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Compact 3-segment selector in the top bar for Smaller (S) / Normal (M) / Larger (L) buttons.
class _ButtonSizeSelector extends StatelessWidget {
  final GamepadTheme theme;
  final GamepadButtonSize selected;
  final double height;
  final double borderRadius;
  final double segmentWidth;
  final double fontSize;
  final ValueChanged<GamepadButtonSize> onSelected;

  const _ButtonSizeSelector({
    required this.theme,
    required this.selected,
    required this.height,
    required this.borderRadius,
    required this.segmentWidth,
    required this.fontSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.buttonFill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.buttonBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: GamepadButtonSize.values.map((preset) {
          final isSelected = preset == selected;
          return Tooltip(
            message: preset.label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                width: segmentWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.statusAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(borderRadius - 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  preset.shortLabel,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.textSecondary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
