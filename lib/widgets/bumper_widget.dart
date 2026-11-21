import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// Tombol bumper L1 dan R1 gaya PlayStation dengan animasi warna dan vibrasi 15ms.
class BumperWidget extends StatefulWidget {
  /// Label bumper ("L1" atau "R1").
  final String label;

  /// Callback saat bumper ditekan (`true`) atau dilepas (`false`).
  final void Function(bool isDown) onPressed;

  /// Membuat [BumperWidget].
  const BumperWidget({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<BumperWidget> createState() => _BumperWidgetState();
}

class _BumperWidgetState extends State<BumperWidget> {
  static const Color _normalBg = Color(0xFF181830);
  static const Color _normalBorder = Color(0xFF2A2A4A);
  static const Color _activeBg = Color(0xFF252545);
  static const Color _activeBorder = Color(0xFF3A3A6A);

  bool _isPressed = false;

  /// Memperbarui status tekan bumper dan memicu getaran 15ms saat ditekan.
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

  /// Memicu vibrasi singkat 15ms secara aman.
  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 15);
      }
    } catch (_) {
      // Abaikan jika perangkat tidak mendukung getaran.
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width: 90,
        height: 24,
        decoration: BoxDecoration(
          color: _isPressed ? _activeBg : _normalBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isPressed ? _activeBorder : _normalBorder,
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: _isPressed
                ? Colors.white
                : const Color(0xFF9A9ACC),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
