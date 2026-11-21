import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/gamepad_theme.dart';

/// PlayStation DualSense interactive Touchpad (`280x160` reference, radius `16`)
/// with glowing blue top lightbar (`180x4`) and multi-touch press/drag feedback.
class GamepadTouchpad extends StatefulWidget {
  /// Active design-token theme.
  final GamepadTheme theme;

  /// Width in logical pixels (reference: 280dp scaled).
  final double width;

  /// Height in logical pixels (reference: 160dp scaled).
  final double height;

  /// Corner radius (reference: 16dp scaled).
  final double borderRadius;

  /// Invoked when the touchpad is pressed (`true`) or released (`false`).
  final ValueChanged<bool> onPressed;

  /// Optional normalized touch coordinates `(0..1, 0..1)` while dragging.
  final ValueChanged<Offset?>? onTouchPositionChanged;

  /// Creates a [GamepadTouchpad].
  const GamepadTouchpad({
    super.key,
    required this.theme,
    required this.onPressed,
    this.onTouchPositionChanged,
    this.width = 280,
    this.height = 160,
    this.borderRadius = 16,
  });

  @override
  State<GamepadTouchpad> createState() => _GamepadTouchpadState();
}

class _GamepadTouchpadState extends State<GamepadTouchpad> {
  final Set<int> _activePointers = {};
  Offset? _localTouchPos;

  bool get _isPressed => _activePointers.isNotEmpty;

  /// Captures pointer press and records touch position for visual ripple feedback.
  void _handleDown(PointerDownEvent event) {
    final wasPressed = _isPressed;
    _activePointers.add(event.pointer);
    _updateTouchPosition(event.localPosition);

    if (!wasPressed) {
      HapticFeedback.lightImpact();
      widget.onPressed(true);
    }
  }

  /// Tracks finger drag inside the touchpad bounds.
  void _handleMove(PointerMoveEvent event) {
    if (!_activePointers.contains(event.pointer)) return;
    _updateTouchPosition(event.localPosition);
  }

  /// Releases pointer and clears touch indicator when all fingers lift.
  void _handleEnd(int pointerId) {
    if (!_activePointers.remove(pointerId)) return;
    if (!_isPressed) {
      setState(() {
        _localTouchPos = null;
      });
      widget.onTouchPositionChanged?.call(null);
      widget.onPressed(false);
    }
  }

  /// Clamps touch coordinates inside the pad and notifies optional drag listener.
  void _updateTouchPosition(Offset localPos) {
    final clamped = Offset(
      localPos.dx.clamp(0.0, widget.width),
      localPos.dy.clamp(0.0, widget.height),
    );
    setState(() {
      _localTouchPos = clamped;
    });
    if (widget.onTouchPositionChanged != null &&
        widget.width > 0 &&
        widget.height > 0) {
      widget.onTouchPositionChanged!(
        Offset(clamped.dx / widget.width, clamped.dy / widget.height),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final lightbarWidth = widget.width * (180 / 280);
    final lightbarHeight = (widget.height * (4 / 160)).clamp(3.0, 5.0);
    final lightbarTop = widget.height * (10 / 160);
    final dotSize = (widget.height * 0.16).clamp(18.0, 28.0);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleDown,
      onPointerMove: _handleMove,
      onPointerUp: (e) => _handleEnd(e.pointer),
      onPointerCancel: (e) => _handleEnd(e.pointer),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.touchpadFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed
                  ? theme.touchpadLightbar
                  : theme.touchpadBorder,
              width: _isPressed ? 1.5 : 1.0,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: theme.touchpadLightbar.withValues(alpha: 0.22),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glowing blue DualSense top lightbar (180x4 reference).
              Positioned(
                top: lightbarTop,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: lightbarWidth,
                  height: lightbarHeight,
                  decoration: BoxDecoration(
                    color: theme.touchpadLightbar,
                    borderRadius: BorderRadius.circular(lightbarHeight),
                    boxShadow: [
                      BoxShadow(
                        color: theme.touchpadLightbar.withValues(
                          alpha: _isPressed ? 0.85 : 0.55,
                        ),
                        blurRadius: _isPressed ? 12 : 8,
                        spreadRadius: _isPressed ? 1.5 : 0.5,
                      ),
                    ],
                  ),
                ),
              ),

              // Subtle TOUCHPAD caption.
              Text(
                'TOUCHPAD',
                style: TextStyle(
                  color: theme.touchpadLabel,
                  fontSize: (widget.height * 0.072).clamp(9.0, 12.0),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.2,
                ),
              ),

              // Live luminous contact point while touching/dragging the pad.
              if (_localTouchPos != null)
                Positioned(
                  left: _localTouchPos!.dx - dotSize / 2,
                  top: _localTouchPos!.dy - dotSize / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.touchpadLightbar.withValues(alpha: 0.25),
                        border: Border.all(
                          color: theme.touchpadLightbar.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
