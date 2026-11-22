import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';

/// Brand design tokens for the Quick Menu Drawer slide-over overlay
/// (Midnight Navy, Amber, Deep Orange, Gold & Silver) in Dark and Light modes.
class QuickMenuTokens {
  final Color backdrop;
  final Color backdropHint;
  final Color surface;
  final Color leftBorder;
  final Color headerTitle;

  final Color pingFill;
  final Color pingBorder;
  final Color pingText;

  final Color closeFill;
  final Color closeIcon;

  final Color categoryLabel;

  final Color chipIdleFill;
  final Color chipIdleBorder;
  final Color chipIdleText;
  final Color chipActiveFill;
  final Color chipActiveText;

  final Color openWorldBorder;
  final Color openWorldText;
  final Color fpsBorder;
  final Color fpsText;

  final Color toggleFill;
  final Color toggleIdleBorder;
  final Color toggleIdleText;
  final Color hapticsActiveBorder;
  final Color hapticsActiveText;
  final Color gyroActiveBorder;
  final Color gyroActiveText;

  final Color sliderCardFill;
  final Color sliderCardBorder;
  final Color sliderTrack;
  final Color deadzoneFill;
  final Color opacityFill;
  final Color sliderLabel;

  final Color editHudFill;
  final Color editHudBorder;
  final Color editHudText;
  final Color pairingFill;
  final Color pairingBorder;
  final Color pairingText;

  const QuickMenuTokens({
    required this.backdrop,
    required this.backdropHint,
    required this.surface,
    required this.leftBorder,
    required this.headerTitle,
    required this.pingFill,
    required this.pingBorder,
    required this.pingText,
    required this.closeFill,
    required this.closeIcon,
    required this.categoryLabel,
    required this.chipIdleFill,
    required this.chipIdleBorder,
    required this.chipIdleText,
    required this.chipActiveFill,
    required this.chipActiveText,
    required this.openWorldBorder,
    required this.openWorldText,
    required this.fpsBorder,
    required this.fpsText,
    required this.toggleFill,
    required this.toggleIdleBorder,
    required this.toggleIdleText,
    required this.hapticsActiveBorder,
    required this.hapticsActiveText,
    required this.gyroActiveBorder,
    required this.gyroActiveText,
    required this.sliderCardFill,
    required this.sliderCardBorder,
    required this.sliderTrack,
    required this.deadzoneFill,
    required this.opacityFill,
    required this.sliderLabel,
    required this.editHudFill,
    required this.editHudBorder,
    required this.editHudText,
    required this.pairingFill,
    required this.pairingBorder,
    required this.pairingText,
  });

  /// Dark Mode (Primary): Midnight Navy & Gold palette.
  static const QuickMenuTokens dark = QuickMenuTokens(
    backdrop: Color(0xBF060D1A), // #060D1A at 75% opacity
    backdropHint: Color(0xFFC0C0C0),
    surface: Color(0xFF0A1628),
    leftBorder: Color(0xFF001F3F),
    headerTitle: Color(0xFFFFD700),
    pingFill: Color(0xFF001F3F),
    pingBorder: Color(0xFFF59E0B),
    pingText: Color(0xFFFFD700),
    closeFill: Color(0xFF001F3F),
    closeIcon: Color(0xFFC0C0C0),
    categoryLabel: Color(0xFFC0C0C0),
    chipIdleFill: Color(0xFF001F3F),
    chipIdleBorder: Color(0xFFC0C0C0),
    chipIdleText: Color(0xFFC0C0C0),
    chipActiveFill: Color(0xFFF59E0B),
    chipActiveText: Color(0xFF0A1628),
    openWorldBorder: Color(0xFFF59E0B),
    openWorldText: Color(0xFFFFD700),
    fpsBorder: Color(0xFFEA580C),
    fpsText: Color(0xFFEA580C),
    toggleFill: Color(0xFF001F3F),
    toggleIdleBorder: Color(0xFFC0C0C0),
    toggleIdleText: Color(0xFFC0C0C0),
    hapticsActiveBorder: Color(0xFFF59E0B),
    hapticsActiveText: Color(0xFFFFD700),
    gyroActiveBorder: Color(0xFFEA580C),
    gyroActiveText: Color(0xFFF59E0B),
    sliderCardFill: Color(0xFF001F3F),
    sliderCardBorder: Color(0xFFC0C0C0),
    sliderTrack: Color(0xFF0A1628),
    deadzoneFill: Color(0xFFFFD700),
    opacityFill: Color(0xFFF59E0B),
    sliderLabel: Color(0xFFC0C0C0),
    editHudFill: Color(0xFF001F3F),
    editHudBorder: Color(0xFFEA580C),
    editHudText: Color(0xFFFFD700),
    pairingFill: Color(0xFFF59E0B),
    pairingBorder: Color(0xFFFFD700),
    pairingText: Color(0xFF0A1628),
  );

  /// Light Mode: Silver & Navy Accent palette.
  static const QuickMenuTokens light = QuickMenuTokens(
    backdrop: Color(0xBFE2E7F0), // #E2E7F0 at 75% opacity
    backdropHint: Color(0xFF475569),
    surface: Color(0xFFFFFFFF),
    leftBorder: Color(0xFFD2D8E4),
    headerTitle: Color(0xFF1E293B),
    pingFill: Color(0xFF001F3F),
    pingBorder: Color(0xFFF59E0B),
    pingText: Color(0xFFFFD700),
    closeFill: Color(0xFFF1F4FA),
    closeIcon: Color(0xFF475569),
    categoryLabel: Color(0xFF475569),
    chipIdleFill: Color(0xFFF1F4FA),
    chipIdleBorder: Color(0xFFD5DBE8),
    chipIdleText: Color(0xFF475569),
    chipActiveFill: Color(0xFF001F3F),
    chipActiveText: Color(0xFFFFD700),
    openWorldBorder: Color(0xFFF59E0B),
    openWorldText: Color(0xFFB45309),
    fpsBorder: Color(0xFFEA580C),
    fpsText: Color(0xFFC2410C),
    toggleFill: Color(0xFFF1F4FA),
    toggleIdleBorder: Color(0xFFD5DBE8),
    toggleIdleText: Color(0xFF475569),
    hapticsActiveBorder: Color(0xFFF59E0B),
    hapticsActiveText: Color(0xFF001F3F),
    gyroActiveBorder: Color(0xFFEA580C),
    gyroActiveText: Color(0xFFC2410C),
    sliderCardFill: Color(0xFFF1F4FA),
    sliderCardBorder: Color(0xFFD5DBE8),
    sliderTrack: Color(0xFFCBD2E0),
    deadzoneFill: Color(0xFF001F3F),
    opacityFill: Color(0xFFF59E0B),
    sliderLabel: Color(0xFF475569),
    editHudFill: Color(0xFF001F3F),
    editHudBorder: Color(0xFFEA580C),
    editHudText: Color(0xFFFFD700),
    pairingFill: Color(0xFFF59E0B),
    pairingBorder: Color(0xFFEA580C),
    pairingText: Color(0xFF0A1628),
  );

  static QuickMenuTokens resolve(bool isDark) => isDark ? dark : light;
}

/// Slide-over Quick Menu Drawer overlay for landscape gamepad screens.
/// Slides smoothly from the right edge (`220ms`, `Curves.easeOutCubic`) over a
/// dimmed backdrop of the active controller and wires every control to live state.
class QuickMenuDrawer extends StatefulWidget {
  final bool isOpen;
  final bool isDark;
  final GamepadStyle activeStyle;
  final ConnectionStatus connectionStatus;
  final bool hapticsEnabled;
  final bool gyroEnabled;
  final double deadzone;
  final double hudOpacity;

  final VoidCallback onClose;
  final ValueChanged<GamepadStyle> onSelectStyle;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleHaptics;
  final VoidCallback onToggleGyro;
  final ValueChanged<double> onDeadzoneChanged;
  final ValueChanged<double> onHudOpacityChanged;
  final VoidCallback onEditHudLayout;
  final VoidCallback onOpenPcPairing;

  const QuickMenuDrawer({
    super.key,
    required this.isOpen,
    required this.isDark,
    required this.activeStyle,
    required this.connectionStatus,
    required this.hapticsEnabled,
    required this.gyroEnabled,
    required this.deadzone,
    required this.hudOpacity,
    required this.onClose,
    required this.onSelectStyle,
    required this.onToggleTheme,
    required this.onToggleHaptics,
    required this.onToggleGyro,
    required this.onDeadzoneChanged,
    required this.onHudOpacityChanged,
    required this.onEditHudLayout,
    required this.onOpenPcPairing,
  });

  @override
  State<QuickMenuDrawer> createState() => _QuickMenuDrawerState();
}

class _QuickMenuDrawerState extends State<QuickMenuDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.isOpen ? 1.0 : 0.0,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant QuickMenuDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns honest connection state text and dot color for the live status pill.
  ({Color dotColor, String label}) _connectionBadgeMeta() {
    switch (widget.connectionStatus) {
      case ConnectionStatus.connected:
        return (dotColor: const Color(0xFF22C55E), label: 'LIVE OK');
      case ConnectionStatus.reconnecting:
        return (dotColor: const Color(0xFFF59E0B), label: 'SYNCING');
      case ConnectionStatus.disconnected:
        return (dotColor: const Color(0xFFEF4444), label: 'OFFLINE');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isDismissed && !widget.isOpen) {
          return const SizedBox.shrink();
        }

        final tokens = QuickMenuTokens.resolve(widget.isDark);
        final statusBadge = _connectionBadgeMeta();

        return IgnorePointer(
          ignoring: !widget.isOpen,
          child: Material(
            type: MaterialType.transparency,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape):
                    widget.onClose,
              },
              child: Focus(
                autofocus: widget.isOpen,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenW = constraints.maxWidth;
                    final minW = screenW * 0.52;
                    final maxW = screenW * 0.60;
                    final drawerWidth = 440.0.clamp(minW, maxW);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Dimmed left backdrop (tap outside to resume gamepad).
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onClose,
                            child: Container(
                              color: tokens.backdrop,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: (screenW - drawerWidth).clamp(
                                    0.0,
                                    screenW,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        'TAP OUTSIDE TO RESUME GAMEPAD',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: tokens.backdropHint,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right-edge slide-over panel.
                        Align(
                          alignment: Alignment.centerRight,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              width: drawerWidth,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: tokens.surface,
                                border: Border(
                                  left: BorderSide(
                                    color: tokens.leftBorder,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: SafeArea(
                                left: false,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // 1. Header Row
                                      _buildHeader(tokens, statusBadge),
                                      const SizedBox(height: 10),

                                      // 2. Category 1: CONSOLES & ACTION
                                      _buildCategoryTitle(
                                        'CONSOLES & ACTION',
                                        tokens,
                                      ),
                                      const SizedBox(height: 6),
                                      _buildConsolesRow(tokens),
                                      const SizedBox(height: 10),

                                      // 3. Category 2: SIMULATORS (2x3 grid, coming soon)
                                      _buildCategoryTitle(
                                        'SIMULATORS (COMING SOON)',
                                        tokens,
                                      ),
                                      const SizedBox(height: 6),
                                      _buildSimulatorsGrid(tokens),
                                      const SizedBox(height: 10),

                                      // 4. Quick Toggles Row (Theme, Haptics, Gyro)
                                      _buildQuickTogglesRow(tokens),
                                      const SizedBox(height: 10),

                                      // 5. Sliders Card (Deadzone + Opacity)
                                      _buildSlidersCard(tokens),
                                      const SizedBox(height: 10),

                                      // 6. Bottom Action Row (Edit HUD Layout + PC Pairing)
                                      _buildBottomActionsRow(tokens),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Section 1: CONTROLLER STUDIO | live status pill | close button (`26x26` inside 44x44 hit target).
  Widget _buildHeader(
    QuickMenuTokens tokens,
    ({Color dotColor, String label}) statusBadge,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'CONTROLLER STUDIO',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.headerTitle,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Live connection pill
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: tokens.pingFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.pingBorder, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusBadge.dotColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                statusBadge.label,
                style: TextStyle(
                  color: tokens.pingText,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Close button (visual 26x26 radius 6 inside accessible 44x36 tap zone).
        Semantics(
          button: true,
          label: 'Close Quick Menu',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: tokens.closeFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: tokens.closeIcon,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Section label (`9px Bold`).
  Widget _buildCategoryTitle(String title, QuickMenuTokens tokens) {
    return Text(
      title,
      style: TextStyle(
        color: tokens.categoryLabel,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  /// Section 2: Horizontal row of 5 chips (PS5, Xbox, Switch enabled; Open World & FPS Tact. disabled coming soon).
  Widget _buildConsolesRow(QuickMenuTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: _PresetChip(
            label: 'PS5',
            tokens: tokens,
            isActive: widget.activeStyle == GamepadStyle.playstation,
            onTap: () => widget.onSelectStyle(GamepadStyle.playstation),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _PresetChip(
            label: 'Xbox',
            tokens: tokens,
            isActive: widget.activeStyle == GamepadStyle.xbox,
            onTap: () => widget.onSelectStyle(GamepadStyle.xbox),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _PresetChip(
            label: 'Switch',
            tokens: tokens,
            isActive: widget.activeStyle == GamepadStyle.nintendoSwitch,
            onTap: () => widget.onSelectStyle(GamepadStyle.nintendoSwitch),
          ),
        ),
        const SizedBox(width: 5),
        // TODO: Implement Open World controller preset.
        Expanded(
          child: _PresetChip(
            label: 'Open World',
            tokens: tokens,
            isActive: false,
            comingSoon: true,
            borderOverride: tokens.openWorldBorder,
            textOverride: tokens.openWorldText,
            onTap: null,
          ),
        ),
        const SizedBox(width: 5),
        // TODO: Implement FPS Tactical controller preset.
        Expanded(
          child: _PresetChip(
            label: 'FPS Tact.',
            tokens: tokens,
            isActive: false,
            comingSoon: true,
            borderOverride: tokens.fpsBorder,
            textOverride: tokens.fpsText,
            onTap: null,
          ),
        ),
      ],
    );
  }

  /// Section 3: 2x3 grid of 6 simulator presets clearly marked Coming Soon until built.
  Widget _buildSimulatorsGrid(QuickMenuTokens tokens) {
    // TODO: Implement dedicated simulator layouts when HID/steering bindings ship.
    const row1 = ['Car Wheel Sim', 'ETS2 / ATS Truck', 'Train Sim'];
    const row2 = ['Flight Sim', 'HOTAS 6-DOF', 'Heavy Machinery'];

    Widget buildRow(List<String> items) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: _PresetChip(
                label: items[i],
                tokens: tokens,
                isActive: false,
                comingSoon: true,
                onTap: null,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        buildRow(row1),
        const SizedBox(height: 5),
        buildRow(row2),
      ],
    );
  }

  /// Section 4: 3 equal Quick Toggle pills (`height: 38`, `radius: 10`).
  Widget _buildQuickTogglesRow(QuickMenuTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: _QuickTogglePill(
            tokens: tokens,
            label: widget.isDark ? 'DARK MODE' : 'LIGHT MODE',
            icon: widget.isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            borderColor: tokens.toggleIdleBorder,
            borderWidth: 1.0,
            textColor: tokens.toggleIdleText,
            onTap: widget.onToggleTheme,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickTogglePill(
            tokens: tokens,
            label: widget.hapticsEnabled ? 'HAPTICS: ON' : 'HAPTICS: OFF',
            dotColor: widget.hapticsEnabled
                ? tokens.hapticsActiveBorder
                : tokens.toggleIdleText,
            borderColor: widget.hapticsEnabled
                ? tokens.hapticsActiveBorder
                : tokens.toggleIdleBorder,
            borderWidth: widget.hapticsEnabled ? 1.5 : 1.0,
            textColor: widget.hapticsEnabled
                ? tokens.hapticsActiveText
                : tokens.toggleIdleText,
            onTap: widget.onToggleHaptics,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickTogglePill(
            tokens: tokens,
            label: widget.gyroEnabled ? 'GYRO: ON' : 'GYRO: OFF',
            dotColor: widget.gyroEnabled
                ? tokens.gyroActiveBorder
                : tokens.toggleIdleText,
            borderColor: widget.gyroEnabled
                ? tokens.gyroActiveBorder
                : tokens.toggleIdleBorder,
            borderWidth: widget.gyroEnabled ? 1.5 : 1.0,
            textColor: widget.gyroEnabled
                ? tokens.gyroActiveText
                : tokens.toggleIdleText,
            onTap: widget.onToggleGyro,
          ),
        ),
      ],
    );
  }

  /// Section 5: Sliders Card (`radius: 12`, `padding: 12`) for Deadzone & HUD Opacity.
  Widget _buildSlidersCard(QuickMenuTokens tokens) {
    final deadzonePct = (widget.deadzone * 100).round();
    final opacityPct = (widget.hudOpacity * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.sliderCardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.sliderCardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabeledSlider(
            label: 'DEADZONE: $deadzonePct%',
            value: widget.deadzone,
            min: 0.0,
            max: 0.25,
            divisions: 25,
            activeColor: tokens.deadzoneFill,
            trackColor: tokens.sliderTrack,
            labelColor: tokens.sliderLabel,
            onChanged: widget.onDeadzoneChanged,
          ),
          const SizedBox(height: 6),
          _buildLabeledSlider(
            label: 'OPACITY: $opacityPct%',
            value: widget.hudOpacity,
            min: 0.20,
            max: 1.0,
            divisions: 16,
            activeColor: tokens.opacityFill,
            trackColor: tokens.sliderTrack,
            labelColor: tokens.sliderLabel,
            onChanged: widget.onHudOpacityChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required Color trackColor,
    required Color labelColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(
          height: 28,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: activeColor,
              inactiveTrackColor: trackColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Section 6: Bottom Action Row (`height: 42`, `radius: 10`).
  Widget _buildBottomActionsRow(QuickMenuTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: widget.onEditHudLayout,
              style: OutlinedButton.styleFrom(
                backgroundColor: tokens.editHudFill,
                foregroundColor: tokens.editHudText,
                side: BorderSide(color: tokens.editHudBorder, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'EDIT HUD LAYOUT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: widget.onOpenPcPairing,
              style: OutlinedButton.styleFrom(
                backgroundColor: tokens.pairingFill,
                foregroundColor: tokens.pairingText,
                side: BorderSide(color: tokens.pairingBorder, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'PC PAIRING (WI-FI / BT)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact preset chip (`height: 30`, `radius: 8`) supporting active highlight
/// and honest disabled/coming-soon presentation for unbuilt presets.
class _PresetChip extends StatelessWidget {
  final String label;
  final QuickMenuTokens tokens;
  final bool isActive;
  final bool comingSoon;
  final Color? borderOverride;
  final Color? textOverride;
  final VoidCallback? onTap;

  const _PresetChip({
    required this.label,
    required this.tokens,
    required this.isActive,
    required this.onTap,
    this.comingSoon = false,
    this.borderOverride,
    this.textOverride,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? tokens.chipActiveFill : tokens.chipIdleFill;
    final borderColor = isActive
        ? tokens.chipActiveFill
        : (borderOverride ?? tokens.chipIdleBorder);
    final textColor = isActive
        ? tokens.chipActiveText
        : (textOverride ?? tokens.chipIdleText);

    return Tooltip(
      message: comingSoon ? '$label (Coming soon)' : label,
      child: Semantics(
        button: !comingSoon,
        enabled: !comingSoon,
        label: comingSoon ? '$label, coming soon' : '$label layout preset',
        child: MouseRegion(
          cursor: comingSoon
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Opacity(
              opacity: comingSoon ? 0.58 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick toggle pill (`height: 38`, `radius: 10`) for Theme, Haptics, and Gyro.
class _QuickTogglePill extends StatelessWidget {
  final QuickMenuTokens tokens;
  final String label;
  final IconData? icon;
  final Color? dotColor;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickTogglePill({
    required this.tokens,
    required this.label,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
    required this.onTap,
    this.icon,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: tokens.toggleFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 12, color: textColor),
                    const SizedBox(width: 5),
                  ] else if (dotColor != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
