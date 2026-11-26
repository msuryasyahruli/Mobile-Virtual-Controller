import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/gamepad_layout_parts.dart';
import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';
import '../theme/pc_suite_theme.dart';

/// Shared configuration passed to all Trackpad, Mouse & Keyboard Suite screens.
class PcSuiteScreenConfig {
  final GamepadTheme theme;
  final double hudOpacity;
  final GamepadStatusBadge status;
  final VoidCallback onOpenMenu;
  final ValueChanged<GamepadStyle> onSwitchStyle;

  const PcSuiteScreenConfig({
    required this.theme,
    required this.hudOpacity,
    required this.status,
    required this.onOpenMenu,
    required this.onSwitchStyle,
  });

  PcSuiteTheme get palette => PcSuiteTheme.resolve(theme.isDark);
}

/// Visual role of a key or button in the Trackpad, Mouse & Keyboard Suite.
enum PcKeyVariant {
  standard,
  modifier,
  highlight,
  cta,
  alert,
  modeSwitch,
  shortcut,
}

/// Multi-touch key / mouse button with `0.94x` press scale, haptic feedback,
/// optional `350ms` key-repeat, and optional latched state border.
class PcSuiteKeyButton extends StatefulWidget {
  final PcSuiteTheme palette;
  final String label;
  final String? subLabel;
  final double width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final PcKeyVariant variant;
  final bool isLatched;
  final bool enableRepeat;
  final VoidCallback? onTap;
  final VoidCallback? onRepeatTick;
  final ValueChanged<bool>? onPressChanged;

  const PcSuiteKeyButton({
    super.key,
    required this.palette,
    required this.label,
    required this.width,
    required this.height,
    this.subLabel,
    this.borderRadius = 8.0,
    this.fontSize = 11.0,
    this.variant = PcKeyVariant.standard,
    this.isLatched = false,
    this.enableRepeat = false,
    this.onTap,
    this.onRepeatTick,
    this.onPressChanged,
  });

  @override
  State<PcSuiteKeyButton> createState() => _PcSuiteKeyButtonState();
}

class _PcSuiteKeyButtonState extends State<PcSuiteKeyButton> {
  final Set<int> _activePointers = {};
  Timer? _repeatDelayTimer;
  Timer? _repeatIntervalTimer;
  bool _didRepeat = false;

  bool get _isPressed => _activePointers.isNotEmpty;

  @override
  void dispose() {
    _cancelRepeat();
    super.dispose();
  }

  void _cancelRepeat() {
    _repeatDelayTimer?.cancel();
    _repeatDelayTimer = null;
    _repeatIntervalTimer?.cancel();
    _repeatIntervalTimer = null;
  }

  void _startRepeatIfEnabled() {
    final tick = widget.onRepeatTick ?? widget.onTap;
    if (!widget.enableRepeat || tick == null) return;
    _cancelRepeat();
    _repeatDelayTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || !_isPressed) return;
      _didRepeat = true;
      tick();
      _repeatIntervalTimer = Timer.periodic(
        const Duration(milliseconds: 55),
        (_) {
          if (!mounted || !_isPressed) {
            _cancelRepeat();
            return;
          }
          tick();
        },
      );
    });
  }

  void _handleDown(PointerDownEvent event) {
    final wasPressed = _isPressed;
    _activePointers.add(event.pointer);
    if (!wasPressed) {
      _didRepeat = false;
      setState(() {});
      GamepadHaptics.lightImpact();
      widget.onPressChanged?.call(true);
      _startRepeatIfEnabled();
    }
  }

  void _handleUp(int pointerId, {required bool triggerTap}) {
    if (!_activePointers.remove(pointerId)) return;
    if (!_isPressed) {
      _cancelRepeat();
      setState(() {});
      widget.onPressChanged?.call(false);
      // Only fire onTap when onPressChanged is not handling down/up edges
      // and key-repeat did not already emit ticks.
      if (triggerTap && widget.onPressChanged == null && !_didRepeat) {
        widget.onTap?.call();
      }
      _didRepeat = false;
    }
  }

  ({Color fill, Color border, Color text, double borderWidth, FontWeight weight})
      _resolveColors() {
    final p = widget.palette;
    if (widget.isLatched) {
      return (
        fill: p.highlightFill,
        border: p.highlightBorder,
        text: p.highlightText,
        borderWidth: 2.0,
        weight: FontWeight.w800,
      );
    }

    return switch (widget.variant) {
      PcKeyVariant.standard => (
          fill: _isPressed ? p.keyPressedFill : p.keyFill,
          border: _isPressed ? p.highlightBorder : p.keyBorder,
          text: p.keyText,
          borderWidth: _isPressed ? 1.5 : 1.0,
          weight: FontWeight.w700,
        ),
      PcKeyVariant.modifier => (
          fill: _isPressed ? p.keyPressedFill : p.modifierFill,
          border: _isPressed ? p.highlightBorder : p.modifierBorder,
          text: p.modifierText,
          borderWidth: _isPressed ? 1.5 : 1.0,
          weight: FontWeight.w700,
        ),
      PcKeyVariant.highlight => (
          fill: p.highlightFill,
          border: p.highlightBorder,
          text: p.highlightText,
          borderWidth: _isPressed ? 2.2 : 1.6,
          weight: FontWeight.w800,
        ),
      PcKeyVariant.cta => (
          fill: _isPressed ? p.ctaPressedFill : p.ctaFill,
          border: p.ctaBorder,
          text: p.ctaText,
          borderWidth: 1.5,
          weight: FontWeight.w800,
        ),
      PcKeyVariant.alert => (
          fill: _isPressed ? p.keyPressedFill : p.alertFill,
          border: p.alertBorder,
          text: p.alertText,
          borderWidth: 1.5,
          weight: FontWeight.w800,
        ),
      PcKeyVariant.modeSwitch => (
          fill: p.modeSwitchFill,
          border: p.modeSwitchBorder,
          text: p.modeSwitchText,
          borderWidth: 1.5,
          weight: FontWeight.w800,
        ),
      PcKeyVariant.shortcut => (
          fill: p.shortcutFill,
          border: _isPressed ? p.highlightBorder : p.shortcutBorder,
          text: p.shortcutText,
          borderWidth: _isPressed ? 1.5 : 1.0,
          weight: FontWeight.w700,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveColors();

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handleDown,
          onPointerUp: (e) => _handleUp(e.pointer, triggerTap: true),
          onPointerCancel: (e) => _handleUp(e.pointer, triggerTap: false),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 55),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 65),
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: style.fill,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: style.border,
                  width: style.borderWidth,
                ),
                boxShadow: (_isPressed || widget.isLatched)
                    ? [
                        BoxShadow(
                          color: style.border.withValues(alpha: 0.28),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.subLabel != null)
                      Text(
                        widget.subLabel!,
                        style: TextStyle(
                          color: style.text.withValues(alpha: 0.78),
                          fontSize: (widget.fontSize * 0.72).clamp(7.0, 10.0),
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    Text(
                      widget.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: style.text,
                        fontSize: widget.fontSize,
                        fontWeight: style.weight,
                        letterSpacing: 0.3,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Center status pill for the Trackpad, Mouse & Keyboard Suite.
class PcSuiteStatusPill extends StatelessWidget {
  final PcSuiteTheme palette;
  final String label;
  final Color dotColor;
  final double width;
  final double height;
  final double fontSize;
  final VoidCallback? onTap;

  const PcSuiteStatusPill({
    super.key,
    required this.palette,
    required this.label,
    required this.dotColor,
    required this.width,
    required this.height,
    required this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: MouseRegion(
        cursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: palette.statusPillFill,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: palette.statusPillBorder, width: 1.5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: palette.statusPillText,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-touch trackpad surface supporting:
/// - 1-finger drag: relative mouse delta scaled by [dpi]
/// - 1-finger tap: Left Click
/// - Double-tap & hold: Drag Lock (`LMB` held until lift)
/// - 2-finger tap: Right Click
/// - 2-finger drag: Scroll wheel (priority)
class PcMultiTouchTrackpad extends StatefulWidget {
  final PcSuiteTheme palette;
  final double width;
  final double height;
  final double borderRadius;
  final double crosshairSize;
  final double captionFontSize;
  final String caption;
  final double dpi;
  final void Function(double dx, double dy) onMouseMove;
  final void Function(MouseButton button, bool pressed) onMouseButton;
  final void Function(double dx, double dy) onMouseScroll;

  const PcMultiTouchTrackpad({
    super.key,
    required this.palette,
    required this.width,
    required this.height,
    required this.caption,
    required this.onMouseMove,
    required this.onMouseButton,
    required this.onMouseScroll,
    this.borderRadius = 18.0,
    this.crosshairSize = 24.0,
    this.captionFontSize = 10.0,
    this.dpi = 1.2,
  });

  @override
  State<PcMultiTouchTrackpad> createState() => _PcMultiTouchTrackpadState();
}

class _PcMultiTouchTrackpadState extends State<PcMultiTouchTrackpad> {
  final Map<int, Offset> _pointers = {};
  final Map<int, Offset> _downPositions = {};
  DateTime? _gestureStart;
  int _maxPointersInGesture = 0;
  double _maxTravel = 0.0;
  Offset? _lastTwoFingerCentroid;
  DateTime? _lastSingleTapAt;
  bool _isDragLocked = false;

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    if (_pointers.isEmpty) {
      _gestureStart = now;
      _maxPointersInGesture = 1;
      _maxTravel = 0.0;

      // Double-tap & hold engages drag lock (LMB held down).
      if (_lastSingleTapAt != null &&
          now.difference(_lastSingleTapAt!).inMilliseconds <= 280) {
        _isDragLocked = true;
        _lastSingleTapAt = null;
        GamepadHaptics.lightImpact();
        widget.onMouseButton(MouseButton.left, true);
      }
    } else {
      _maxPointersInGesture = math.max(_maxPointersInGesture, _pointers.length + 1);
    }

    _pointers[event.pointer] = event.localPosition;
    _downPositions[event.pointer] = event.localPosition;

    if (_pointers.length == 2) {
      final pts = _pointers.values.toList();
      _lastTwoFingerCentroid = (pts[0] + pts[1]) / 2.0;
    }

    setState(() {});
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final prev = _pointers[event.pointer];
    if (prev == null) return;

    final delta = event.localPosition - prev;
    _pointers[event.pointer] = event.localPosition;

    final startPos = _downPositions[event.pointer];
    if (startPos != null) {
      _maxTravel = math.max(_maxTravel, (event.localPosition - startPos).distance);
    }

    if (_pointers.length == 1) {
      widget.onMouseMove(delta.dx * widget.dpi, delta.dy * widget.dpi);
    } else if (_pointers.length >= 2) {
      final pts = _pointers.values.take(2).toList();
      final centroid = (pts[0] + pts[1]) / 2.0;
      final centroidDelta = _lastTwoFingerCentroid != null
          ? centroid - _lastTwoFingerCentroid!
          : Offset.zero;
      _lastTwoFingerCentroid = centroid;

      if (centroidDelta != Offset.zero) {
        widget.onMouseScroll(centroidDelta.dx * 0.5, centroidDelta.dy * 0.5);
      }
    }

    setState(() {});
  }

  void _handlePointerEnd(int pointerId, {required bool canceled}) {
    _pointers.remove(pointerId);
    _downPositions.remove(pointerId);
    if (_pointers.length < 2) {
      _lastTwoFingerCentroid = null;
    }

    if (_pointers.isEmpty) {
      if (_isDragLocked) {
        _isDragLocked = false;
        widget.onMouseButton(MouseButton.left, false);
      } else if (!canceled && _gestureStart != null) {
        final elapsedMs = DateTime.now().difference(_gestureStart!).inMilliseconds;
        final isTap = elapsedMs <= 250 && _maxTravel < 10.0;
        if (isTap) {
          GamepadHaptics.lightImpact();
          if (_maxPointersInGesture >= 2) {
            widget.onMouseButton(MouseButton.right, true);
            widget.onMouseButton(MouseButton.right, false);
            _lastSingleTapAt = null;
          } else {
            widget.onMouseButton(MouseButton.left, true);
            widget.onMouseButton(MouseButton.left, false);
            _lastSingleTapAt = DateTime.now();
          }
        }
      }
      _gestureStart = null;
      _maxPointersInGesture = 0;
      _maxTravel = 0.0;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final active = _pointers.isNotEmpty;

    return Semantics(
      label: widget.caption,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: (e) => _handlePointerEnd(e.pointer, canceled: false),
        onPointerCancel: (e) => _handlePointerEnd(e.pointer, canceled: true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: p.trackpadFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: active ? p.highlightBorder : p.trackpadBorder,
              width: active ? 1.5 : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // Subtle center crosshair
                Center(
                  child: SizedBox(
                    width: widget.crosshairSize,
                    height: widget.crosshairSize,
                    child: CustomPaint(
                      painter: _CrosshairPainter(color: p.trackpadCrosshair),
                    ),
                  ),
                ),

                // Live multi-touch finger indicators
                for (final pos in _pointers.values)
                  Positioned(
                    left: pos.dx - 16,
                    top: pos.dy - 16,
                    child: IgnorePointer(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.highlightBorder.withValues(alpha: 0.22),
                          border: Border.all(
                            color: p.highlightBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom caption
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    _isDragLocked
                        ? 'DRAG LOCK ACTIVE'
                        : widget.caption,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isDragLocked
                          ? p.highlightText
                          : p.trackpadCaption.withValues(alpha: 0.78),
                      fontSize: widget.captionFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  const _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Proportional artboard canvas for the PC suite (`852x393` landscape or `393x852` portrait).
class PcArtboardShell extends StatelessWidget {
  final PcSuiteTheme palette;
  final double artboardWidth;
  final double artboardHeight;
  final double hudOpacity;
  final bool symmetricNotchPadding;
  final List<Widget> Function(double Function(double) s) builder;

  const PcArtboardShell({
    super.key,
    required this.palette,
    required this.builder,
    this.artboardWidth = kGamepadArtboardWidth,
    this.artboardHeight = kGamepadArtboardHeight,
    this.hudOpacity = 1.0,
    this.symmetricNotchPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    return ArtboardCanvasShell(
      artboardWidth: artboardWidth,
      artboardHeight: artboardHeight,
      backgroundColor: palette.chassisBg,
      isDark: palette.isDark,
      hudOpacity: hudOpacity,
      symmetricNotchPadding: symmetricNotchPadding,
      builder: builder,
    );
  }
}