import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// Tombol shapes bulat PlayStation (△, □, ○, ✕) diameter 48dp dengan vibrasi 20ms.
class ButtonWidget extends StatefulWidget {
  /// Simbol tombol PlayStation ("△", "□", "○", atau "✕").
  final String label;

  /// Callback saat tombol ditekan (`true`) atau dilepas (`false`).
  final void Function(bool isDown) onPressed;

  /// Warna latar belakang tombol saat normal.
  final Color backgroundColor;

  /// Warna garis tepi tombol.
  final Color borderColor;

  /// Warna simbol di dalam tombol.
  final Color textColor;

  /// Diameter tombol bulat (default 48dp).
  final double size;

  /// Membuat [ButtonWidget].
  const ButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.size = 48,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  bool _isPressed = false;

  /// Memperbarui status tekan tombol dan memicu getaran 20ms saat ditekan.
  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;

    setState(() {
      _isPressed = pressed;
    });

    if (pressed) {
      _vibrate();
    }

    widget.onPressed(pressed);
  }

  /// Memicu getaran singkat 20ms menggunakan package vibration.
  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 20);
      }
    } catch (_) {
      // Abaikan jika perangkat tidak mendukung getaran.
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBg = Color.lerp(
          widget.backgroundColor,
          widget.borderColor,
          0.45,
        ) ??
        widget.backgroundColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: _isPressed ? 0.92 : 1.0),
        duration: const Duration(milliseconds: 65),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 75),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed ? activeBg : widget.backgroundColor,
            border: Border.all(
              color: widget.borderColor,
              width: 1.5,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.borderColor.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.size * 0.44,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
