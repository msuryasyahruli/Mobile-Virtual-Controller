import 'package:flutter/material.dart';

/// Widget bar horizontal analog untuk trigger L2 dan R2 dengan rentang nilai 0.0 sampai 1.0.
class TriggerBarWidget extends StatefulWidget {
  /// Label trigger yang ditampilkan di dalam bar ("L2" atau "R2").
  final String label;

  /// Callback yang dipanggil saat nilai analog trigger berubah.
  final void Function(double value) onChanged;

  /// Jika true, fill bergerak dari kanan ke kiri (digunakan untuk R2).
  final bool isReversed;

  /// Membuat [TriggerBarWidget].
  const TriggerBarWidget({
    super.key,
    required this.label,
    required this.onChanged,
    this.isReversed = false,
  });

  @override
  State<TriggerBarWidget> createState() => _TriggerBarWidgetState();
}

class _TriggerBarWidgetState extends State<TriggerBarWidget> {
  static const Color _minColor = Color(0xFF2A2A5A);
  static const Color _maxColor = Color(0xFF6A6ACC);
  static const Color _labelColor = Color(0xFF7A7AAA);
  static const Color _trackBg = Color(0xFF141428);
  static const Color _trackBorder = Color(0xFF2A2A4A);

  /// Jarak geser vertikal (dp) dari 0.0 ke 1.0 saat drag ke bawah.
  static const double _dragSensitivity = 80.0;

  double _value = 0.0;
  double _lastEmitted = 0.0;
  double _accumulatedDragY = 0.0;
  bool _isDragging = false;

  /// Memperbarui nilai trigger dan mengirim callback hanya saat ada perubahan signifikan.
  void _setValue(double nextValue) {
    final clamped = nextValue.clamp(0.0, 1.0).toDouble();
    final rounded = (clamped * 100).round() / 100.0;
    if (rounded != _value) {
      setState(() {
        _value = rounded;
      });
    }

    final hitBoundary = (rounded == 0.0 || rounded == 1.0) &&
        rounded != _lastEmitted;
    if (hitBoundary || (rounded - _lastEmitted).abs() > 0.01) {
      _lastEmitted = rounded;
      widget.onChanged(rounded);
    }
  }

  /// Menangani sentuhan tekan langsung untuk nilai penuh 1.0.
  void _handleTapDown(TapDownDetails details) {
    _isDragging = false;
    _setValue(1.0);
  }

  /// Mengembalikan nilai trigger ke 0.0 saat tap dilepas.
  void _handleTapRelease() {
    if (_isDragging) return;
    _setValue(0.0);
  }

  /// Memulai mode drag vertikal analog untuk trigger.
  void _handleVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
    _accumulatedDragY = 0.0;
  }

  /// Menambah nilai trigger saat jari diseret ke bawah.
  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    _isDragging = true;
    _accumulatedDragY = (_accumulatedDragY + details.delta.dy)
        .clamp(0.0, _dragSensitivity);
    _setValue(_accumulatedDragY / _dragSensitivity);
  }

  /// Mengembalikan nilai trigger ke 0.0 saat jari diangkat setelah drag.
  void _handleVerticalDragEnd() {
    _isDragging = false;
    _accumulatedDragY = 0.0;
    _setValue(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = Color.lerp(_minColor, _maxColor, _value) ?? _minColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: (_) => _handleTapRelease(),
      onTapCancel: _handleTapRelease,
      onVerticalDragStart: _handleVerticalDragStart,
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: (_) => _handleVerticalDragEnd(),
      onVerticalDragCancel: _handleVerticalDragEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 0.0;
          final fillWidth = maxWidth * _value;

          return Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _trackBg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: _trackBorder,
                width: 0.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: widget.isReversed
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: _isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 80),
                    curve: Curves.easeOut,
                    width: fillWidth,
                    height: 20,
                    color: fillColor,
                  ),
                ),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
