import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/gamepad_theme.dart';

/// Circular face-button cluster (`144x144` reference plate) containing 4
/// multi-touch circular `44x44` buttons in diamond formation for PlayStation
/// (`△`, `○`, `✕`, `□`) and Xbox (`Y`, `B`, `A`, `X`).
class GamepadFaceButtons extends StatelessWidget {
  /// Active theme providing plate, cap, and per-button accent colors.
  final GamepadTheme theme;

  /// Diameter of the circular recessed base plate (reference: 144dp scaled).
  final double plateSize;

  /// Diameter of each individual face button (reference: 44dp scaled).
  final double buttonSize;

  /// Callbacks mapped to canonical controller buttons (`A`=bottom, `B`=right, `X`=left, `Y`=top).
  final ValueChanged<bool> onTopChanged;
  final ValueChanged<bool> onRightChanged;
  final ValueChanged<bool> onBottomChanged;
  final ValueChanged<bool> onLeftChanged;

  /// Creates [GamepadFaceButtons].
  const GamepadFaceButtons({
    super.key,
    required this.theme,
    required this.onTopChanged,
    required this.onRightChanged,
    required this.onBottomChanged,
    required this.onLeftChanged,
    this.plateSize = 144,
    this.buttonSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    final inset = plateSize * (8 / 144);
    final isPlayStation = theme.style == GamepadStyle.playstation;

    return Container(
      width: plateSize,
      height: plateSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.plateFill,
        border: Border.all(
          color: theme.plateBorder,
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top: △ (PS) / Y (Xbox)
          Positioned(
            top: inset,
            child: _FaceActionButton(
              theme: theme,
              token: theme.actionTop,
              size: buttonSize,
              shape: isPlayStation ? _PlayStationShape.triangle : null,
              onChanged: onTopChanged,
            ),
          ),

          // Right: ○ (PS) / B (Xbox)
          Positioned(
            right: inset,
            child: _FaceActionButton(
              theme: theme,
              token: theme.actionRight,
              size: buttonSize,
              shape: isPlayStation ? _PlayStationShape.circle : null,
              onChanged: onRightChanged,
            ),
          ),

          // Bottom: ✕ (PS) / A (Xbox)
          Positioned(
            bottom: inset,
            child: _FaceActionButton(
              theme: theme,
              token: theme.actionBottom,
              size: buttonSize,
              shape: isPlayStation ? _PlayStationShape.cross : null,
              onChanged: onBottomChanged,
            ),
          ),

          // Left: □ (PS) / X (Xbox)
          Positioned(
            left: inset,
            child: _FaceActionButton(
              theme: theme,
              token: theme.actionLeft,
              size: buttonSize,
              shape: isPlayStation ? _PlayStationShape.square : null,
              onChanged: onLeftChanged,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlayStationShape { triangle, circle, cross, square }

/// Single multi-touch circular face button with pointer-ID tracking and haptic impact.
class _FaceActionButton extends StatefulWidget {
  final GamepadTheme theme;
  final GamepadActionToken token;
  final double size;
  final _PlayStationShape? shape;
  final ValueChanged<bool> onChanged;

  const _FaceActionButton({
    required this.theme,
    required this.token,
    required this.size,
    required this.shape,
    required this.onChanged,
  });

  @override
  State<_FaceActionButton> createState() => _FaceActionButtonState();
}

class _FaceActionButtonState extends State<_FaceActionButton> {
  final Set<int> _activePointers = {};

  bool get _isPressed => _activePointers.isNotEmpty;

  /// Tracks pointer down independently for true simultaneous chord presses.
  void _handleDown(PointerDownEvent event) {
    final wasPressed = _isPressed;
    _activePointers.add(event.pointer);
    if (!wasPressed) {
      setState(() {});
      GamepadHaptics.lightImpact();
      widget.onChanged(true);
    }
  }

  /// Releases pointer and notifies when the last finger lifts off this button.
  void _handleEnd(int pointerId) {
    if (!_activePointers.remove(pointerId)) return;
    if (!_isPressed) {
      setState(() {});
      widget.onChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final accent = widget.token.accentColor;
    final pressedFill = Color.lerp(
          theme.faceCapFill,
          accent,
          theme.isDark ? 0.28 : 0.16,
        ) ??
        theme.faceCapFill;

    return Semantics(
      button: true,
      label: 'Button ${widget.token.label}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handleDown,
          onPointerUp: (e) => _handleEnd(e.pointer),
          onPointerCancel: (e) => _handleEnd(e.pointer),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 65),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPressed ? pressedFill : theme.faceCapFill,
                border: Border.all(
                  color: accent,
                  width: widget.token.borderWidth,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: widget.shape != null
                  ? CustomPaint(
                      size: Size.square(widget.size * 0.44),
                      painter: _PlayStationGlyphPainter(
                        shape: widget.shape!,
                        color: accent,
                        strokeWidth: (widget.size * 0.055).clamp(1.6, 2.4),
                      ),
                    )
                  : Text(
                      widget.token.label,
                      style: TextStyle(
                        color: widget.token.effectiveTextColor,
                        fontSize: widget.size * 0.44,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders crisp geometric PlayStation symbols with uniform stroke weight.
class _PlayStationGlyphPainter extends CustomPainter {
  final _PlayStationShape shape;
  final Color color;
  final double strokeWidth;

  const _PlayStationGlyphPainter({
    required this.shape,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    switch (shape) {
      case _PlayStationShape.triangle:
        final path = Path()
          ..moveTo(w * 0.5, h * 0.1)
          ..lineTo(w * 0.92, h * 0.86)
          ..lineTo(w * 0.08, h * 0.86)
          ..close();
        canvas.drawPath(path, paint);
      case _PlayStationShape.circle:
        final radius = math.min(w, h) * 0.41;
        canvas.drawCircle(Offset(w / 2, h / 2), radius, paint);
      case _PlayStationShape.cross:
        final inset = w * 0.16;
        canvas.drawLine(
          Offset(inset, inset),
          Offset(w - inset, h - inset),
          paint,
        );
        canvas.drawLine(
          Offset(w - inset, inset),
          Offset(inset, h - inset),
          paint,
        );
      case _PlayStationShape.square:
        final inset = w * 0.15;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(inset, inset, w - inset, h - inset),
            const Radius.circular(1.5),
          ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _PlayStationGlyphPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
