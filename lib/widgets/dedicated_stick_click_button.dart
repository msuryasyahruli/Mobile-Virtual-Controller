import 'package:flutter/material.dart';

import '../theme/gamepad_theme.dart';

/// Dedicated multi-touch pill button (`48x36` reference, radius `10`) for
/// stick click actions (`L3`/`R3` on PlayStation, `LS`/`RS` on Xbox).
class DedicatedStickClickButton extends StatefulWidget {
  /// Active theme providing surface, border, and accent colors.
  final GamepadTheme theme;

  /// Bold centered label (`L3`, `R3`, `LS`, or `RS`).
  final String label;

  /// Width in logical pixels (reference: 48dp scaled).
  final double width;

  /// Height in logical pixels (reference: 36dp scaled).
  final double height;

  /// Corner radius (reference: 10dp scaled).
  final double borderRadius;

  /// Callback triggered on press (`true`) and release (`false`).
  final ValueChanged<bool> onPressed;

  /// Creates a [DedicatedStickClickButton].
  const DedicatedStickClickButton({
    super.key,
    required this.theme,
    required this.label,
    required this.onPressed,
    this.width = 48,
    this.height = 36,
    this.borderRadius = 10,
  });

  @override
  State<DedicatedStickClickButton> createState() =>
      _DedicatedStickClickButtonState();
}

class _DedicatedStickClickButtonState extends State<DedicatedStickClickButton> {
  final Set<int> _activePointers = {};

  bool get _isPressed => _activePointers.isNotEmpty;

  /// Captures touch down by pointer ID without blocking simultaneous stick drags.
  void _handleDown(PointerDownEvent event) {
    final wasPressed = _isPressed;
    _activePointers.add(event.pointer);
    if (!wasPressed) {
      setState(() {});
      GamepadHaptics.lightImpact();
      widget.onPressed(true);
    }
  }

  /// Releases touch point and triggers release callback when all fingers lift.
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
      label: 'Stick click ${widget.label}',
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
                    color: _isPressed
                        ? theme.buttonPressedFill
                        : theme.buttonFill,
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
                      fontSize: (widget.height * 0.36).clamp(10.0, 14.0),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
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
