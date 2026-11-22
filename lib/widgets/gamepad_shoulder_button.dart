import 'package:flutter/material.dart';

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

  /// Optional custom idle fill color (e.g. Switch Pro M1 / M2 macro slots).
  final Color? fillColorOverride;

  /// Optional custom idle border color.
  final Color? borderColorOverride;

  /// Idle border stroke width (default `1.0`; `1.5` for macro slots).
  final double borderWidth;

  /// Optional custom idle text color.
  final Color? textColorOverride;

  /// Optional custom pressed highlight / glow accent color.
  final Color? accentColorOverride;

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
    this.fillColorOverride,
    this.borderColorOverride,
    this.borderWidth = 1.0,
    this.textColorOverride,
    this.accentColorOverride,
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
      GamepadHaptics.lightImpact();
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
    final accent = widget.accentColorOverride ?? theme.statusAccent;
    final idleFill = widget.fillColorOverride ?? theme.buttonFill;
    final idleBorder = widget.borderColorOverride ?? theme.buttonBorder;
    final idleText = widget.textColorOverride ?? theme.textPrimary;
    final pressedFill = widget.fillColorOverride != null
        ? (Color.lerp(idleFill, accent, theme.isDark ? 0.28 : 0.16) ??
            theme.buttonPressedFill)
        : theme.buttonPressedFill;

    return Semantics(
      button: true,
      label: 'Shoulder ${widget.label}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handleDown,
          onPointerUp: (e) => _handleEnd(e.pointer),
          onPointerCancel: (e) => _handleEnd(e.pointer),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              child: AnimatedScale(
                scale: _isPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 65),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: _isPressed ? pressedFill : idleFill,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: _isPressed ? accent : idleBorder,
                      width: _isPressed
                          ? (widget.borderWidth < 1.5
                              ? 1.5
                              : widget.borderWidth)
                          : widget.borderWidth,
                    ),
                    boxShadow: _isPressed
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
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
                      color: _isPressed ? accent : idleText,
                      fontSize: (widget.height * 0.39).clamp(10.0, 14.0),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
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
