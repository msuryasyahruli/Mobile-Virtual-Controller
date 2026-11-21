import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/gamepad_theme.dart';

/// Multi-touch circular recessed D-Pad supporting 8-way / diagonal slide for
/// both PlayStation DualSense and Xbox Series Hybrid dish layouts.
class GamepadDPad extends StatefulWidget {
  /// Active design-token theme.
  final GamepadTheme theme;

  /// Outer circular base diameter (PS: 144dp, Xbox: 132dp, scaled).
  final double size;

  /// Emits directional flags whenever any of up/down/left/right changes.
  final void Function(bool up, bool down, bool left, bool right) onChanged;

  /// Creates a [GamepadDPad].
  const GamepadDPad({
    super.key,
    required this.theme,
    required this.size,
    required this.onChanged,
  });

  @override
  State<GamepadDPad> createState() => _GamepadDPadState();
}

class _GamepadDPadState extends State<GamepadDPad> {
  final Map<int, Offset> _activePointers = {};

  bool _up = false;
  bool _down = false;
  bool _left = false;
  bool _right = false;

  /// Registers a touch point and recalculates 8-way directions.
  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    _recomputeDirections();
  }

  /// Tracks finger slide across the D-Pad dish for smooth diagonal transitions.
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.localPosition;
    _recomputeDirections();
  }

  /// Removes a released touch point and resets directions when no fingers remain.
  void _handlePointerEnd(int pointerId) {
    if (_activePointers.remove(pointerId) == null) return;
    _recomputeDirections();
  }

  /// Evaluates all active pointers into combined 8-way directional booleans.
  void _recomputeDirections() {
    bool nextUp = false;
    bool nextDown = false;
    bool nextLeft = false;
    bool nextRight = false;

    final center = widget.size / 2;
    final deadzone = widget.size * 0.12;

    for (final pos in _activePointers.values) {
      final dx = pos.dx - center;
      final dy = pos.dy - center;
      if (dx.abs() <= deadzone && dy.abs() <= deadzone) continue;

      // 0.42 slope margin gives crisp cardinals while allowing natural diagonals.
      if (dy < -deadzone && dy.abs() >= dx.abs() * 0.42) {
        nextUp = true;
      } else if (dy > deadzone && dy.abs() >= dx.abs() * 0.42) {
        nextDown = true;
      }

      if (dx < -deadzone && dx.abs() >= dy.abs() * 0.42) {
        nextLeft = true;
      } else if (dx > deadzone && dx.abs() >= dy.abs() * 0.42) {
        nextRight = true;
      }
    }

    // Prevent impossible opposite directions from firing simultaneously.
    if (nextUp && nextDown) {
      nextUp = false;
      nextDown = false;
    }
    if (nextLeft && nextRight) {
      nextLeft = false;
      nextRight = false;
    }

    if (nextUp == _up &&
        nextDown == _down &&
        nextLeft == _left &&
        nextRight == _right) {
      return;
    }

    final newlyActivated = (nextUp && !_up) ||
        (nextDown && !_down) ||
        (nextLeft && !_left) ||
        (nextRight && !_right);

    setState(() {
      _up = nextUp;
      _down = nextDown;
      _left = nextLeft;
      _right = nextRight;
    });

    if (newlyActivated) {
      HapticFeedback.lightImpact();
    }

    widget.onChanged(_up, _down, _left, _right);
  }

  /// Renders a single tactile directional arm cap with pressed feedback.
  Widget _buildCap({
    required bool isActive,
    required double width,
    required double height,
    required BorderRadius borderRadius,
    required IconData icon,
    required double iconSize,
  }) {
    final theme = widget.theme;
    final activeBorder = theme.statusAccent;
    final activeFill = Color.lerp(
          theme.dpadCapFill,
          activeBorder,
          theme.isDark ? 0.25 : 0.14,
        ) ??
        theme.dpadCapFill;

    return AnimatedScale(
      scale: isActive ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 65),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isActive ? activeFill : theme.dpadCapFill,
          borderRadius: borderRadius,
          border: Border.all(
            color: isActive ? activeBorder : theme.dpadCapBorder,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: activeBorder.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 0.5,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.isDark ? 0.35 : 0.07,
                ),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: iconSize,
          color: isActive ? activeBorder : theme.dpadArrowColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isXbox = theme.style == GamepadStyle.xbox;
    final size = widget.size;

    // Exact proportional ratios:
    // Xbox Hybrid dish (132): vertical 36x44, horizontal 44x36, hub 34x34.
    // PlayStation recessed (144): vertical 34x44, horizontal 44x34, hub 30x30.
    final double vertW = size * (isXbox ? 36 / 132 : 34 / 144);
    final double vertH = size * (isXbox ? 44 / 132 : 44 / 144);
    final double horizW = size * (isXbox ? 44 / 132 : 44 / 144);
    final double horizH = size * (isXbox ? 36 / 132 : 34 / 144);
    final double hubSize = size * (isXbox ? 34 / 132 : 30 / 144);
    final double edgeInset = size * (isXbox ? 7 / 132 : 10 / 144);
    final double capRadius = size * (isXbox ? 8 / 132 : 7 / 144);
    final double iconSize = size * 0.145;
    final bool anyActive = _up || _down || _left || _right;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: (e) => _handlePointerEnd(e.pointer),
      onPointerCancel: (e) => _handlePointerEnd(e.pointer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.plateFill,
          border: Border.all(
            color: anyActive
                ? theme.statusAccent.withValues(alpha: 0.45)
                : theme.plateBorder,
            width: 1.2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle faceted inner dish ring for Xbox Hybrid D-Pad.
            if (isXbox)
              Container(
                width: size * 0.80,
                height: size * 0.80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.plateBorder.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                ),
              ),

            // Center hub.
            Container(
              width: hubSize,
              height: hubSize,
              decoration: BoxDecoration(
                shape: isXbox ? BoxShape.circle : BoxShape.rectangle,
                borderRadius:
                    isXbox ? null : BorderRadius.circular(capRadius * 0.6),
                color: theme.dpadCapFill,
                border: Border.all(
                  color: theme.dpadCapBorder,
                  width: 1.0,
                ),
              ),
            ),

            // Up directional cap.
            Positioned(
              top: edgeInset,
              child: _buildCap(
                isActive: _up,
                width: vertW,
                height: vertH,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(capRadius),
                  bottom: Radius.circular(capRadius * 0.45),
                ),
                icon: Icons.arrow_drop_up_rounded,
                iconSize: iconSize,
              ),
            ),

            // Down directional cap.
            Positioned(
              bottom: edgeInset,
              child: _buildCap(
                isActive: _down,
                width: vertW,
                height: vertH,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(capRadius * 0.45),
                  bottom: Radius.circular(capRadius),
                ),
                icon: Icons.arrow_drop_down_rounded,
                iconSize: iconSize,
              ),
            ),

            // Left directional cap.
            Positioned(
              left: edgeInset,
              child: _buildCap(
                isActive: _left,
                width: horizW,
                height: horizH,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(capRadius),
                  right: Radius.circular(capRadius * 0.45),
                ),
                icon: Icons.arrow_left_rounded,
                iconSize: iconSize,
              ),
            ),

            // Right directional cap.
            Positioned(
              right: edgeInset,
              child: _buildCap(
                isActive: _right,
                width: horizW,
                height: horizH,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(capRadius * 0.45),
                  right: Radius.circular(capRadius),
                ),
                icon: Icons.arrow_right_rounded,
                iconSize: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
