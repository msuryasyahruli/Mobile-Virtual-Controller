import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/gamepad_theme.dart';

/// Multi-touch circular analog thumbstick returning normalized `Offset(-1..1, -1..1)`
/// with smooth spring-back animation and DualSense / Xbox concave styling.
class GamepadThumbstick extends StatefulWidget {
  /// Active theme providing socket, cap, and concave inner ring colors.
  final GamepadTheme theme;

  /// Outer socket diameter (reference: 96dp scaled).
  final double socketSize;

  /// Draggable cap diameter (reference: 64dp scaled).
  final double capSize;

  /// Inner concave indent ring diameter (reference: 36dp scaled).
  final double indentSize;

  /// Emits normalized `(dx, dy)` in `[-1.0, 1.0]` whenever stick position changes.
  final ValueChanged<Offset> onChanged;

  /// When true, pushing up emits `dy = +1.0` to match ViGEmBus / XInput convention.
  final bool invertY;

  /// Optional override for the concave inner ring border (e.g. Joy-Con Neon Blue / Red).
  final Color? indentBorderColor;

  /// Optional override for the active glow / highlight accent color.
  final Color? activeAccentColor;

  /// Radial deadzone fraction (`0.0` to `0.25`) below which output snaps to zero.
  final double deadzone;

  /// Creates a [GamepadThumbstick].
  const GamepadThumbstick({
    super.key,
    required this.theme,
    required this.onChanged,
    this.socketSize = 96,
    this.capSize = 64,
    this.indentSize = 36,
    this.invertY = true,
    this.indentBorderColor,
    this.activeAccentColor,
    this.deadzone = 0.05,
  });

  @override
  State<GamepadThumbstick> createState() => _GamepadThumbstickState();
}

class _GamepadThumbstickState extends State<GamepadThumbstick> {
  static const double _emitThreshold = 0.01;

  int? _activePointerId;
  Offset _capOffset = Offset.zero;
  Offset _lastEmitted = Offset.zero;

  double get _maxTravel => (widget.socketSize - widget.capSize) * 0.58;

  /// Captures the first pointer touching the stick socket and updates immediately.
  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointerId != null) return;
    _activePointerId = event.pointer;
    GamepadHaptics.lightImpact();
    _updateFromLocal(event.localPosition);
  }

  /// Follows only the captured pointer ID so other controls work simultaneously.
  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointerId) return;
    _updateFromLocal(event.localPosition);
  }

  /// Releases the captured pointer and springs the thumbstick back to center.
  void _handlePointerEnd(int pointerId) {
    if (pointerId != _activePointerId) return;
    _activePointerId = null;
    setState(() {
      _capOffset = Offset.zero;
    });
    if (_lastEmitted != Offset.zero) {
      _lastEmitted = Offset.zero;
      widget.onChanged(Offset.zero);
    }
  }

  /// Clamps the touch offset inside the circular socket and emits normalized axes.
  void _updateFromLocal(Offset localPosition) {
    final center = Offset(widget.socketSize / 2, widget.socketSize / 2);
    final delta = localPosition - center;
    final distance = delta.distance;
    final maxTravel = _maxTravel;

    Offset clamped;
    if (distance <= maxTravel || distance == 0) {
      clamped = delta;
    } else {
      final angle = math.atan2(delta.dy, delta.dx);
      clamped = Offset(
        math.cos(angle) * maxTravel,
        math.sin(angle) * maxTravel,
      );
    }

    setState(() {
      _capOffset = clamped;
    });

    final rawNormX = maxTravel > 0
        ? (clamped.dx / maxTravel).clamp(-1.0, 1.0).toDouble()
        : 0.0;
    final rawNormY = maxTravel > 0
        ? (clamped.dy / maxTravel).clamp(-1.0, 1.0).toDouble()
        : 0.0;
    final directedY = widget.invertY ? -rawNormY : rawNormY;
    final magnitude = math.sqrt(rawNormX * rawNormX + directedY * directedY);
    final dz = widget.deadzone.clamp(0.0, 0.25);

    Offset next;
    if (magnitude <= dz || dz >= 1.0) {
      next = Offset.zero;
    } else {
      final rescaled = ((magnitude - dz) / (1.0 - dz)).clamp(0.0, 1.0);
      next = Offset(
        (rawNormX / magnitude) * rescaled,
        (directedY / magnitude) * rescaled,
      );
    }

    if ((next.dx - _lastEmitted.dx).abs() > _emitThreshold ||
        (next.dy - _lastEmitted.dy).abs() > _emitThreshold ||
        (next == Offset.zero && _lastEmitted != Offset.zero)) {
      _lastEmitted = next;
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isActive = _activePointerId != null;
    final baseCenter = (widget.socketSize - widget.capSize) / 2;
    final indentBorder = widget.indentBorderColor ?? theme.stickIndentBorder;
    final accent = widget.activeAccentColor ?? theme.statusAccent;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: (e) => _handlePointerEnd(e.pointer),
      onPointerCancel: (e) => _handlePointerEnd(e.pointer),
      child: SizedBox(
        width: widget.socketSize,
        height: widget.socketSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Recessed circular socket.
            AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: widget.socketSize,
              height: widget.socketSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.stickSocketFill,
                border: Border.all(
                  color: isActive
                      ? accent.withValues(alpha: 0.65)
                      : theme.stickSocketBorder,
                  width: isActive ? 1.5 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),

            // Draggable circular cap with inner concave ring (no text inside).
            AnimatedPositioned(
              duration: isActive
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              left: baseCenter + _capOffset.dx,
              top: baseCenter + _capOffset.dy,
              child: AnimatedScale(
                scale: isActive ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 70),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: widget.capSize,
                  height: widget.capSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.stickCapFill,
                    border: Border.all(
                      color: isActive
                          ? accent.withValues(alpha: 0.8)
                          : theme.stickCapBorder,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: theme.isDark ? 0.55 : 0.14,
                        ),
                        blurRadius: isActive ? 8 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: widget.indentSize,
                    height: widget.indentSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.stickIndentFill,
                      border: Border.all(
                        color: indentBorder,
                        width: theme.stickIndentBorderWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
