import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/gamepad_theme.dart';

/// Multi-touch shoulder / trigger button (`L2`/`LT`, `L1`/`LB`, `R1`/`RB`, `R2`/`RT`)
/// with crisp pressed scale (`0.94`), border glow, and `HapticFeedback.lightImpact()`.
class GamepadShoulderButton extends StatefulWidget {
  /// Active theme providing fill, border, and accent colors.
  final GamepadTheme theme;

  /// Button label (e.g. `L2`, `L1`, `R1`, `R2` or `LT`, `LB`, `RB`, `RT`).
  final String label;

  /// Width in logical pixels (reference: `72` for triggers, `64` for bumpers).
  final double width;

  /// Height in logical pixels (reference: `32`).
  final double height;

  /// Corner radius (reference: `8`).
  final double borderRadius;

  /// Callback invoked when pressed (`true`) or released (`false`).
  final ValueChanged<bool> onPressed;

  /// Creates a [GamepadShoulderButton].
  const GamepadShoulderButton({
    super.key,
    required this.theme,
    required this.label,
    required this.onPressed,
    this.width = 64,
    this.height = 32,
    this.borderRadius = 8,
  });

  @override
  State<GamepadShoulderButton> createState() => _GamepadShoulderButtonState();
}

class _GamepadShoulderButtonState extends State<GamepadShoulderButton> {
  final Set<int> _activePointers = {};

  bool get _isPressed => _activePointers.isNotEmpty;

  /// Tracks touch down by pointer ID for conflict-free multi-touch holds.
  void _handleDown(PointerDownEvent event) {
    final wasPressed = _isPressed;
    _activePointers.add(event.pointer);
    if (!wasPressed) {
      setState(() {});
      HapticFeedback.lightImpact();
      widget.onPressed(true);
    }
  }

  /// Releases the pointer and notifies when no fingers remain on the button.
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
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isPressed ? theme.buttonPressedFill : theme.buttonFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed ? accent : theme.buttonBorder,
              width: _isPressed ? 1.4 : 1.0,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: _isPressed ? accent : theme.textPrimary,
              fontSize: (widget.height * 0.39).clamp(10.0, 14.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
