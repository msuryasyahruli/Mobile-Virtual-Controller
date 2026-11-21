import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// Analog stick gaya PlayStation (130dp x 130dp) dengan output X/Y -1.0 sampai 1.0.
class JoystickWidget extends StatefulWidget {
  /// Callback yang dipanggil saat nilai X atau Y berubah lebih dari 0.01.
  final void Function(double x, double y) onChanged;

  /// Callback opsional saat stick diketuk singkat (untuk L3/R3).
  final VoidCallback? onTap;

  /// Diameter lingkaran base joystick (default 130dp).
  final double size;

  /// Jika true, geser ke atas menghasilkan +1.0 sesuai konvensi XInput/ViGEmBus.
  final bool invertY;

  /// Membuat [JoystickWidget].
  const JoystickWidget({
    super.key,
    required this.onChanged,
    this.onTap,
    this.size = 130,
    this.invertY = true,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  static const Color _baseColor = Color(0xFF111124);
  static const Color _baseBorderColor = Color(0xFF202040);
  static const Color _thumbColor = Color(0xFF1A1A35);
  static const Color _thumbBorderIdle = Color(0xFF2A2A55);
  static const Color _thumbBorderActive = Color(0xFF4A4A88);
  static const double _defaultThumbSize = 56.0;
  static const double _changeThreshold = 0.01;

  Offset _thumbOffset = Offset.zero;
  bool _isActive = false;
  bool _isClickFlashing = false;
  double _lastX = 0.0;
  double _lastY = 0.0;
  Timer? _flashTimer;

  double get _thumbSize => _defaultThumbSize * (widget.size / 130.0);
  double get _maxRadius => (widget.size - _thumbSize) / 2;

  /// Memperbarui posisi thumb dalam radius base dan mengirim nilai X/Y ternormalisasi.
  void _updateFromLocalPosition(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = localPosition - center;
    final distance = delta.distance;

    Offset clampedOffset;
    if (distance <= _maxRadius || distance == 0) {
      clampedOffset = delta;
    } else {
      final angle = math.atan2(delta.dy, delta.dx);
      clampedOffset = Offset(
        math.cos(angle) * _maxRadius,
        math.sin(angle) * _maxRadius,
      );
    }

    final rawX = _maxRadius > 0
        ? (clampedOffset.dx / _maxRadius).clamp(-1.0, 1.0).toDouble()
        : 0.0;
    final rawY = _maxRadius > 0
        ? (clampedOffset.dy / _maxRadius).clamp(-1.0, 1.0).toDouble()
        : 0.0;
    final outputY = widget.invertY ? -rawY : rawY;

    setState(() {
      _isActive = true;
      _thumbOffset = clampedOffset;
    });

    _emitIfChanged(rawX, outputY);
  }

  /// Mengembalikan thumb ke tengah (0, 0) saat jari diangkat.
  void _resetJoystick() {
    setState(() {
      _isActive = false;
      _thumbOffset = Offset.zero;
    });

    if (_lastX != 0.0 || _lastY != 0.0) {
      _lastX = 0.0;
      _lastY = 0.0;
      widget.onChanged(0.0, 0.0);
    }
  }

  /// Memanggil [widget.onChanged] hanya jika nilai X atau Y berubah lebih dari 0.01.
  void _emitIfChanged(double x, double y) {
    final dx = (x - _lastX).abs();
    final dy = (y - _lastY).abs();
    if (dx <= _changeThreshold && dy <= _changeThreshold) return;

    _lastX = x;
    _lastY = y;
    widget.onChanged(x, y);
  }

  /// Menangani ketukan singkat pada stick untuk memicu L3/R3 dengan feedback visual dan getar.
  void _handleTap() {
    if (widget.onTap == null) return;
    _flashTimer?.cancel();
    setState(() {
      _isClickFlashing = true;
    });
    _vibrateClick();
    widget.onTap!();

    _flashTimer = Timer(const Duration(milliseconds: 110), () {
      if (!mounted) return;
      setState(() {
        _isClickFlashing = false;
      });
    });
  }

  /// Memicu getaran singkat 15ms saat stick diketuk (L3/R3).
  Future<void> _vibrateClick() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 15);
      }
    } catch (_) {
      // Abaikan jika perangkat tidak mendukung getaran.
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseCenter = (widget.size - _thumbSize) / 2;
    final isHighlighted = _isActive || _isClickFlashing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onPanStart: (details) => _updateFromLocalPosition(details.localPosition),
      onPanUpdate: (details) => _updateFromLocalPosition(details.localPosition),
      onPanEnd: (_) => _resetJoystick(),
      onPanCancel: _resetJoystick,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lingkaran base diameter 130dp.
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _baseColor,
                border: Border.all(
                  color: _baseBorderColor,
                  width: 1.5,
                ),
              ),
            ),

            // Lingkaran thumb diameter 56dp yang mengikuti jari.
            AnimatedPositioned(
              duration: _isActive
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              left: baseCenter + _thumbOffset.dx,
              top: baseCenter + _thumbOffset.dy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _thumbColor,
                  border: Border.all(
                    color: isHighlighted
                        ? _thumbBorderActive
                        : _thumbBorderIdle,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
