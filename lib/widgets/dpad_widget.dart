import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// D-Pad berbentuk plus (100dp x 100dp) dari dua persegi panjang saling overlap.
class DpadWidget extends StatefulWidget {
  /// Callback yang dipanggil saat status arah Up/Down/Left/Right berubah.
  final void Function(bool up, bool down, bool left, bool right) onChanged;

  /// Ukuran kotak total D-Pad (default 100dp).
  final double size;

  /// Membuat [DpadWidget].
  const DpadWidget({
    super.key,
    required this.onChanged,
    this.size = 100,
  });

  @override
  State<DpadWidget> createState() => _DpadWidgetState();
}

class _DpadWidgetState extends State<DpadWidget> {
  static const Color _dpadBg = Color(0xFF181830);
  static const Color _dpadBorder = Color(0xFF2A2A4A);
  static const Color _activeHighlight = Color(0xFF3A3A6A);

  bool _up = false;
  bool _down = false;
  bool _left = false;
  bool _right = false;

  /// Menentukan arah berdasarkan posisi sentuhan terhadap pembagian sepertiga area.
  void _updateDirection(Offset localPosition) {
    final third = widget.size / 3.0;
    final twoThirds = third * 2.0;

    final nextUp = localPosition.dy < third;
    final nextDown = localPosition.dy > twoThirds;
    final nextLeft = localPosition.dx < third;
    final nextRight = localPosition.dx > twoThirds;

    _applyDirections(nextUp, nextDown, nextLeft, nextRight);
  }

  /// Mereset seluruh arah D-Pad menjadi false saat jari diangkat.
  void _clearDirections() {
    _applyDirections(false, false, false, false);
  }

  /// Memperbarui state arah dan memanggil callback hanya jika ada perubahan.
  void _applyDirections(bool up, bool down, bool left, bool right) {
    if (up == _up && down == _down && left == _left && right == _right) {
      return;
    }

    final newlyPressed = (up && !_up) ||
        (down && !_down) ||
        (left && !_left) ||
        (right && !_right);

    setState(() {
      _up = up;
      _down = down;
      _left = left;
      _right = right;
    });

    if (newlyPressed) {
      _vibrateLight();
    }

    widget.onChanged(_up, _down, _left, _right);
  }

  /// Memicu vibrasi ringan 15ms saat arah baru ditekan.
  Future<void> _vibrateLight() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 15);
      }
    } catch (_) {
      // Abaikan jika perangkat tidak mendukung getaran.
    }
  }

  /// Membangun indikator highlight tipis pada lengan D-Pad yang aktif.
  Widget _buildActiveIndicator({
    required bool active,
    required double width,
    required double height,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: active ? _activeHighlight : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 16,
        color: active ? Colors.white : const Color(0xFF5A5A88),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final barThickness = 32.0 * (size / 100.0);
    final armLength = (size - barThickness) / 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (details) => _updateDirection(details.localPosition),
      onPanUpdate: (details) => _updateDirection(details.localPosition),
      onPanEnd: (_) => _clearDirections(),
      onPanCancel: _clearDirections,
      onTapUp: (_) => _clearDirections(),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Persegi panjang horizontal 100x32dp.
            Container(
              width: size,
              height: barThickness,
              decoration: BoxDecoration(
                color: _dpadBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _dpadBorder,
                  width: 1,
                ),
              ),
            ),

            // Persegi panjang vertikal 32x100dp.
            Container(
              width: barThickness,
              height: size,
              decoration: BoxDecoration(
                color: _dpadBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _dpadBorder,
                  width: 1,
                ),
              ),
            ),

            // Penutup sambungan tengah agar bentuk plus tampak menyatu bersih.
            Container(
              width: barThickness - 2,
              height: barThickness - 2,
              color: _dpadBg,
            ),

            // Indikator arah Atas.
            Positioned(
              top: 1,
              child: _buildActiveIndicator(
                active: _up,
                width: barThickness - 2,
                height: armLength,
                icon: Icons.arrow_drop_up_rounded,
              ),
            ),

            // Indikator arah Bawah.
            Positioned(
              bottom: 1,
              child: _buildActiveIndicator(
                active: _down,
                width: barThickness - 2,
                height: armLength,
                icon: Icons.arrow_drop_down_rounded,
              ),
            ),

            // Indikator arah Kiri.
            Positioned(
              left: 1,
              child: _buildActiveIndicator(
                active: _left,
                width: armLength,
                height: barThickness - 2,
                icon: Icons.arrow_left_rounded,
              ),
            ),

            // Indikator arah Kanan.
            Positioned(
              right: 1,
              child: _buildActiveIndicator(
                active: _right,
                width: armLength,
                height: barThickness - 2,
                icon: Icons.arrow_right_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
