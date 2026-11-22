import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';

/// Proportional artboard scaler function (`logicalPx * scale`).
typedef GamepadScale = double Function(double value);

/// Minimum touch target dimension in logical pixels (R-03).
const double kGamepadMinTapTarget = 44.0;

/// Reference landscape artboard dimensions (`852 x 393`).
const double kGamepadArtboardWidth = 852.0;
const double kGamepadArtboardHeight = 393.0;

/// Connection status display data for the top status/settings pill.
typedef GamepadStatusBadge = ({Color color, String label});

/// Places a control centered on artboard coordinates `(cx, cy)`, accounting
/// for expanded 44dp minimum hitboxes so visuals never shift off-center.
Widget centeredGamepadControl({
  required GamepadScale s,
  required double cx,
  required double cy,
  required double width,
  required double height,
  required Widget child,
  bool enforceMinHitTarget = false,
}) {
  final boxW =
      enforceMinHitTarget ? math.max(width, kGamepadMinTapTarget) : width;
  final boxH =
      enforceMinHitTarget ? math.max(height, kGamepadMinTapTarget) : height;
  return Positioned(
    left: s(cx) - boxW / 2,
    top: s(cy) - boxH / 2,
    child: child,
  );
}

/// Responsive landscape canvas that applies symmetric notch-safe horizontal
/// padding, proportional `852 x 393` artboard scaling, live HUD opacity, and bottom grip trims.
class GamepadCanvasShell extends StatelessWidget {
  final GamepadTheme theme;
  final double hudOpacity;
  final List<Widget> Function(GamepadScale s) builder;

  const GamepadCanvasShell({
    super.key,
    required this.theme,
    required this.builder,
    this.hudOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
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
      value: theme.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.chassisBg,
        body: SafeArea(
          left: false,
          right: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalSafePadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.min(
                  constraints.maxWidth / kGamepadArtboardWidth,
                  constraints.maxHeight / kGamepadArtboardHeight,
                );
                final boardW = kGamepadArtboardWidth * scale;
                final boardH = kGamepadArtboardHeight * scale;
                double s(double v) => v * scale;

                return Center(
                  child: Opacity(
                    opacity: hudOpacity.clamp(0.20, 1.0),
                    child: SizedBox(
                      width: boardW,
                      height: boardH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ...builder(s),

                          // Bottom ergonomic grip trim bars (140x6, radius 3).
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared top bar hosting layout-specific shoulder buttons and the center
/// Status + Controller Settings trigger pill (`>= 44dp` touch height).
class GamepadTopStatusBar extends StatelessWidget {
  final GamepadTheme theme;
  final GamepadScale s;
  final GamepadStatusBadge status;
  final double statusPillWidth;
  final List<Widget> leftShoulders;
  final List<Widget> rightShoulders;
  final VoidCallback onOpenMenu;

  const GamepadTopStatusBar({
    super.key,
    required this.theme,
    required this.s,
    required this.status,
    required this.statusPillWidth,
    required this.leftShoulders,
    required this.rightShoulders,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight = math.max(s(44), kGamepadMinTapTarget);

    return Positioned(
      top: s(4),
      left: s(20),
      right: s(20),
      height: barHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...leftShoulders,
          Expanded(
            child: Center(
              child: Semantics(
                button: true,
                label: 'Open controller settings (${status.label})',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpenMenu,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: kGamepadMinTapTarget,
                        minHeight: kGamepadMinTapTarget,
                      ),
                      child: Center(
                        child: Container(
                          width: s(statusPillWidth),
                          height: s(24),
                          padding: EdgeInsets.symmetric(horizontal: s(10)),
                          decoration: BoxDecoration(
                            color: theme.effectiveStatusBadgeFill,
                            borderRadius: BorderRadius.circular(s(12)),
                            border: Border.all(
                              color: theme.effectiveStatusBadgeBorder,
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
                                SizedBox(width: s(6)),
                                Text(
                                  '☰',
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: s(11.5),
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ...rightShoulders,
        ],
      ),
    );
  }
}

/// Subtle connected `ip:port` caption shown below center navigation controls.
class GamepadEndpointCaption extends StatelessWidget {
  final GamepadTheme theme;
  final GamepadScale s;
  final double top;
  final String? ip;
  final int port;

  const GamepadEndpointCaption({
    super.key,
    required this.theme,
    required this.s,
    required this.top,
    required this.ip,
    this.port = ConnectionService.serverPort,
  });

  @override
  Widget build(BuildContext context) {
    if (ip == null || ip!.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: s(326),
      right: s(326),
      top: s(top),
      child: Text(
        '$ip:$port',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.textMuted,
          fontSize: s(10),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Multi-touch utility button with a minimum 44x44dp touch area for
/// SHARE, OPT, View, Menu, Share, Minus, Plus, and Capture controls.
class GamepadUtilityButton extends StatefulWidget {
  final GamepadTheme theme;
  final String semanticLabel;
  final double width;
  final double height;
  final double borderRadius;
  final ValueChanged<bool> onPressed;
  final Widget child;

  const GamepadUtilityButton({
    super.key,
    required this.theme,
    required this.semanticLabel,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.onPressed,
    required this.child,
  });

  @override
  State<GamepadUtilityButton> createState() => _GamepadUtilityButtonState();
}

class _GamepadUtilityButtonState extends State<GamepadUtilityButton> {
  final Set<int> _activePointers = {};

  bool get _isPressed => _activePointers.isNotEmpty;

  void _handleDown(PointerDownEvent event) {
    final wasPressed = _isPressed;
    _activePointers.add(event.pointer);
    if (!wasPressed) {
      setState(() {});
      GamepadHaptics.lightImpact();
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

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handleDown,
          onPointerUp: (e) => _handleEnd(e.pointer),
          onPointerCancel: (e) => _handleEnd(e.pointer),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kGamepadMinTapTarget,
              minHeight: kGamepadMinTapTarget,
            ),
            child: Center(
              child: AnimatedScale(
                scale: _isPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 65),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color:
                        _isPressed ? theme.buttonPressedFill : theme.buttonFill,
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
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular PlayStation Home, Xbox Guide / Nexus, or Switch Pro Home button
/// (`40x40` reference visual inside a `>= 44x44dp` hitbox).
class GamepadHomeButton extends StatefulWidget {
  final GamepadTheme theme;
  final double size;
  final GamepadStyle style;
  final VoidCallback onTap;

  const GamepadHomeButton({
    super.key,
    required this.theme,
    required this.size,
    required this.style,
    required this.onTap,
  });

  @override
  State<GamepadHomeButton> createState() => _GamepadHomeButtonState();
}

class _GamepadHomeButtonState extends State<GamepadHomeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final borderWidth =
        widget.style == GamepadStyle.nintendoSwitch ? 1.5 : 1.8;

    return Semantics(
      button: true,
      label:
          '${widget.style.displayName} Home button, opens controller settings',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            setState(() => _isPressed = true);
            GamepadHaptics.lightImpact();
          },
          onPointerUp: (_) {
            if (_isPressed) {
              setState(() => _isPressed = false);
              widget.onTap();
            }
          },
          onPointerCancel: (_) => setState(() => _isPressed = false),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kGamepadMinTapTarget,
              minHeight: kGamepadMinTapTarget,
            ),
            child: Center(
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
                      width: borderWidth,
                    ),
                    boxShadow: _isPressed
                        ? [
                            BoxShadow(
                              color: theme.homeBorder.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: switch (widget.style) {
                    GamepadStyle.xbox => CustomPaint(
                        size: Size.square(widget.size * 0.48),
                        painter: _XboxNexusPainter(color: theme.homeIcon),
                      ),
                    GamepadStyle.nintendoSwitch => Icon(
                        Icons.home_rounded,
                        size: widget.size * 0.52,
                        color: theme.homeIcon,
                      ),
                    GamepadStyle.playstation => Text(
                        'PS',
                        style: TextStyle(
                          color: theme.homeIcon,
                          fontSize: widget.size * 0.34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                  },
                ),
              ),
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
