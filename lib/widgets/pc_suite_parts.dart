import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../screens/gamepad_layout_parts.dart';
import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';
import '../theme/pc_suite_theme.dart';

/// Shared configuration passed to Trackpad, Mouse, and Keyboard Suite screens.
class PcSuiteScreenConfig {
  /// The resolved controller theme used to determine brightness.
  final GamepadTheme theme;

  /// The HUD overlay opacity between `0.20` and `1.0`.
  final double hudOpacity;

  /// The connection badge color and label displayed in the top bar.
  final GamepadStatusBadge status;

  /// Called when the user opens the Quick Menu Drawer.
  final VoidCallback onOpenMenu;

  /// Called when the user switches to another [GamepadStyle].
  final ValueChanged<GamepadStyle> onSwitchStyle;

  /// Creates a [PcSuiteScreenConfig].
  const PcSuiteScreenConfig({
    required this.theme,
    required this.hudOpacity,
    required this.status,
    required this.onOpenMenu,
    required this.onSwitchStyle,
  });

  /// The resolved [PcSuiteTheme] matching [theme].
  PcSuiteTheme get palette => PcSuiteTheme.resolve(theme.isDark);
}

/// Visual styling roles for a [PcSuiteKeyButton].
enum PcKeyVariant {
  /// A standard alphanumeric key or mouse button.
  standard,

  /// A modifier or utility key.
  modifier,

  /// An amber-highlighted gaming, arrow, or command key.
  highlight,

  /// A primary call-to-action key such as Enter or Space.
  cta,

  /// An orange-bordered alert or destructive key such as Esc or Backspace.
  alert,

  /// A top-bar mode switch button.
  modeSwitch,

  /// A bottom-row OS shortcut pill.
  shortcut,
}

/// Multi-touch key or mouse button with press scaling, haptics, and repeat.
///
/// Scales to `0.94` while pressed, triggers [GamepadHaptics.lightImpact], and
/// optionally repeats [onRepeatTick] (or [onTap]) every `55ms` after a `350ms`
/// hold when [enableRepeat] is `true`.
class PcSuiteKeyButton extends StatefulWidget {
  /// The color palette used to render the button.
  final PcSuiteTheme palette;

  /// The primary text label shown inside the button.
  final String label;

  /// An optional secondary label shown above [label] (such as an `F`-key hint).
  final String? subLabel;

  /// The button width in logical pixels.
  final double width;

  /// The button height in logical pixels.
  final double height;

  /// The corner radius of the button in logical pixels.
  final double borderRadius;

  /// The font size of [label] in logical pixels.
  final double fontSize;

  /// The visual [PcKeyVariant] applied when not latched.
  final PcKeyVariant variant;

  /// Whether the button is currently latched in an active modifier state.
  final bool isLatched;

  /// Whether holding the button repeats after `350ms`.
  final bool enableRepeat;

  /// Called on tap release when [onPressChanged] is `null`.
  final VoidCallback? onTap;

  /// Called on each repeat tick after the initial `350ms` hold delay.
  final VoidCallback? onRepeatTick;

  /// Called when the pressed state transitions between down (`true`) and up (`false`).
  final ValueChanged<bool>? onPressChanged;

  /// Creates a [PcSuiteKeyButton].
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

/// Multi-touch precision trackpad surface for cursor, scroll, and gestures.
///
/// Supports:
/// - 1-finger drag: ballistic cursor movement scaled by [dpi].
/// - 1-finger tap: [MouseButton.left] click.
/// - Double-tap and hold: drag lock holding [MouseButton.left] until lift.
/// - 2-finger tap: [MouseButton.right] click.
/// - 2-finger drag: axis-stabilized scrolling with kinetic inertia.
/// - 3-finger tap: [MouseButton.middle] click.
/// - 3-finger swipe up/down/left/right: dispatches OS shortcuts via [onShortcut].
class PcMultiTouchTrackpad extends StatefulWidget {
  /// The color palette used to paint the trackpad surface and indicators.
  final PcSuiteTheme palette;

  /// The trackpad width in logical pixels.
  final double width;

  /// The trackpad height in logical pixels.
  final double height;

  /// The corner radius of the trackpad surface.
  final double borderRadius;

  /// The size of the subtle center crosshair in logical pixels.
  final double crosshairSize;

  /// The font size of the bottom [caption].
  final double captionFontSize;

  /// The hint text shown along the bottom edge when idle.
  final String caption;

  /// The sensitivity multiplier applied to 1-finger cursor deltas.
  final double dpi;

  /// Called with relative cursor deltas `(dx, dy)` during 1-finger drags.
  final void Function(double dx, double dy) onMouseMove;

  /// Called when a tap or drag-lock presses or releases a [MouseButton].
  final void Function(MouseButton button, bool pressed) onMouseButton;

  /// Called with scroll deltas `(dx, dy)` during 2-finger drags and inertia.
  final void Function(double dx, double dy) onMouseScroll;

  /// Called with a shortcut key sequence for 3-finger swipe gestures.
  final void Function(List<String> keys)? onShortcut;

  /// Creates a [PcMultiTouchTrackpad].
  const PcMultiTouchTrackpad({
    super.key,
    required this.palette,
    required this.width,
    required this.height,
    required this.caption,
    required this.onMouseMove,
    required this.onMouseButton,
    required this.onMouseScroll,
    this.onShortcut,
    this.borderRadius = 18.0,
    this.crosshairSize = 24.0,
    this.captionFontSize = 10.0,
    this.dpi = 1.2,
  });

  @override
  State<PcMultiTouchTrackpad> createState() => _PcMultiTouchTrackpadState();
}

class _PcMultiTouchTrackpadState extends State<PcMultiTouchTrackpad>
    with SingleTickerProviderStateMixin {
  static const Duration _coalesceInterval = Duration(milliseconds: 8);
  static const double _inertiaFriction = 5.2;
  static const double _inertiaStartSpeed = 80.0; // px/s
  static const double _inertiaStopSpeed = 10.0; // px/s
  static const double _threeFingerSwipeThreshold = 42.0; // logical px

  final Map<int, Offset> _pointers = {};
  final Map<int, Offset> _downPositions = {};
  final ValueNotifier<List<Offset>> _fingerPositions =
      ValueNotifier<List<Offset>>(const []);

  DateTime? _gestureStart;
  int _maxPointersInGesture = 0;
  double _maxTravel = 0.0;
  Offset? _lastTwoFingerCentroid;
  Offset? _threeFingerStartCentroid;
  bool _threeFingerSwipeTriggered = false;
  DateTime? _lastSingleTapAt;
  bool _isDragLocked = false;
  bool _wasMultiFingerGesture = false;
  bool _stoppedInertiaOnDown = false;

  // Brief visual feedback label for 3-finger gestures.
  String? _gestureFeedback;
  Timer? _feedbackTimer;

  // Precision pointer acceleration & One-Euro style smoothing state.
  Duration? _lastMoveTimestamp;
  Offset _smoothedMoveDelta = Offset.zero;

  // Precision 2-finger scroll & kinetic inertia state.
  Duration? _lastScrollTimestamp;
  Offset _scrollFrameDelta = Offset.zero;
  Offset _scrollVelocity = Offset.zero; // px/s
  late final Ticker _inertiaTicker;
  Duration _lastInertiaTick = Duration.zero;

  // Leading-edge 8ms packet coalescing buffers.
  Offset _pendingMove = Offset.zero;
  Offset _pendingScroll = Offset.zero;
  DateTime? _lastFlushAt;
  Timer? _flushTimer;

  @override
  void initState() {
    super.initState();
    _inertiaTicker = createTicker(_onInertiaTick);
  }

  @override
  void dispose() {
    _inertiaTicker.dispose();
    _flushTimer?.cancel();
    _feedbackTimer?.cancel();
    _fingerPositions.dispose();
    super.dispose();
  }

  void _showGestureFeedback(String label) {
    _feedbackTimer?.cancel();
    if (mounted) {
      setState(() => _gestureFeedback = label);
    }
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _gestureFeedback = null);
      }
    });
  }

  void _syncFingerDots() {
    _fingerPositions.value = _pointers.values.toList(growable: false);
  }

  bool _stopInertia() {
    final wasActive = _inertiaTicker.isActive;
    if (wasActive) {
      _inertiaTicker.stop();
    }
    _scrollVelocity = Offset.zero;
    _lastInertiaTick = Duration.zero;
    return wasActive;
  }

  void _startInertiaIfFastEnough() {
    if (_scrollVelocity.distance < _inertiaStartSpeed) {
      _scrollVelocity = Offset.zero;
      return;
    }
    _lastInertiaTick = Duration.zero;
    if (!_inertiaTicker.isActive) {
      _inertiaTicker.start();
    }
  }

  void _onInertiaTick(Duration elapsed) {
    if (_lastInertiaTick == Duration.zero) {
      _lastInertiaTick = elapsed;
      return;
    }
    final dt = ((elapsed - _lastInertiaTick).inMicroseconds / 1e6)
        .clamp(0.001, 0.05);
    _lastInertiaTick = elapsed;

    final decay = math.exp(-_inertiaFriction * dt);
    _scrollVelocity = _scrollVelocity * decay;

    if (_scrollVelocity.distance < _inertiaStopSpeed) {
      _stopInertia();
      return;
    }

    final step = _scrollVelocity * dt;
    widget.onMouseScroll(step.dx * 0.65, step.dy * 0.65);
  }

  /// Continuous precision ballistic curve (no abrupt slope knees).
  /// Slow movement -> ~0.58x pixel-accurate; medium -> ~1.25x; fast flick -> up to 2.75x.
  double _ballisticGain(double speedPxPerSec) {
    final normalized = speedPxPerSec / (speedPxPerSec + 360.0);
    return 0.58 + (2.17 * normalized);
  }

  Offset _centroidOf(Iterable<Offset> pts) {
    var sumX = 0.0;
    var sumY = 0.0;
    var count = 0;
    for (final pt in pts) {
      sumX += pt.dx;
      sumY += pt.dy;
      count++;
    }
    if (count == 0) return Offset.zero;
    return Offset(sumX / count, sumY / count);
  }

  void _queueMove(Offset delta) {
    if (delta == Offset.zero) return;
    _pendingMove += delta;
    _scheduleOrFlush();
  }

  void _queueScroll(Offset delta) {
    if (delta == Offset.zero) return;
    _pendingScroll += delta;
    _scheduleOrFlush();
  }

  void _scheduleOrFlush() {
    final now = DateTime.now();
    if (_lastFlushAt == null) {
      _flushPending();
      return;
    }
    final elapsed = now.difference(_lastFlushAt!);
    if (elapsed >= _coalesceInterval) {
      _flushPending();
      return;
    }
    final remaining = _coalesceInterval - elapsed;
    _flushTimer ??= Timer(remaining, _flushPending);
  }

  void _flushPending() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _lastFlushAt = DateTime.now();

    if (_pendingMove != Offset.zero) {
      final move = _pendingMove;
      _pendingMove = Offset.zero;
      widget.onMouseMove(move.dx, move.dy);
    }
    if (_pendingScroll != Offset.zero) {
      final scroll = _pendingScroll;
      _pendingScroll = Offset.zero;
      widget.onMouseScroll(scroll.dx, scroll.dy);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final stoppedInertia = _stopInertia();
    final now = DateTime.now();
    final wasEmpty = _pointers.isEmpty;

    if (wasEmpty) {
      _gestureStart = now;
      _maxPointersInGesture = 1;
      _maxTravel = 0.0;
      _wasMultiFingerGesture = false;
      _threeFingerSwipeTriggered = false;
      _threeFingerStartCentroid = null;
      _stoppedInertiaOnDown = stoppedInertia;
      _lastMoveTimestamp = event.timeStamp;
      _smoothedMoveDelta = Offset.zero;
      _lastScrollTimestamp = null;
      _scrollFrameDelta = Offset.zero;
      _scrollVelocity = Offset.zero;

      // Double-tap & hold engages drag lock (LMB held down).
      if (!stoppedInertia &&
          _lastSingleTapAt != null &&
          now.difference(_lastSingleTapAt!).inMilliseconds <= 280) {
        _isDragLocked = true;
        _lastSingleTapAt = null;
        GamepadHaptics.lightImpact();
        _flushPending();
        widget.onMouseButton(MouseButton.left, true);
      }
    } else {
      _maxPointersInGesture =
          math.max(_maxPointersInGesture, _pointers.length + 1);
      if (_pointers.length + 1 >= 2) {
        _wasMultiFingerGesture = true;
      }
    }

    _pointers[event.pointer] = event.localPosition;
    _downPositions[event.pointer] = event.localPosition;

    if (_pointers.length == 2) {
      _lastTwoFingerCentroid = _centroidOf(_pointers.values.take(2));
      _lastScrollTimestamp = event.timeStamp;
      _scrollFrameDelta = Offset.zero;
      _scrollVelocity = Offset.zero;
    } else if (_pointers.length >= 3) {
      _threeFingerStartCentroid = _centroidOf(_pointers.values.take(3));
      _threeFingerSwipeTriggered = false;
      _lastTwoFingerCentroid = null;
      _scrollFrameDelta = Offset.zero;
      _scrollVelocity = Offset.zero;
    }

    _syncFingerDots();
    if (wasEmpty || _isDragLocked) {
      setState(() {});
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final prev = _pointers[event.pointer];
    if (prev == null) return;

    final rawDelta = event.localPosition - prev;
    _pointers[event.pointer] = event.localPosition;

    final startPos = _downPositions[event.pointer];
    if (startPos != null) {
      _maxTravel =
          math.max(_maxTravel, (event.localPosition - startPos).distance);
    }

    if (_pointers.length == 1) {
      // Prevent stray cursor jump when lifting 2 or 3 fingers asynchronously.
      if (!_wasMultiFingerGesture && rawDelta != Offset.zero) {
        final dtSec = _lastMoveTimestamp != null
            ? ((event.timeStamp - _lastMoveTimestamp!).inMicroseconds / 1e6)
                .clamp(0.004, 0.05)
            : 0.016;
        _lastMoveTimestamp = event.timeStamp;

        final speed = rawDelta.distance / dtSec;
        // Velocity-adaptive One-Euro style alpha: silky at low speed, zero-lag at high speed.
        final alpha = (0.48 + (speed / (speed + 260.0)) * 0.46).clamp(0.48, 0.94);
        _smoothedMoveDelta = Offset(
          _smoothedMoveDelta.dx * (1.0 - alpha) + rawDelta.dx * alpha,
          _smoothedMoveDelta.dy * (1.0 - alpha) + rawDelta.dy * alpha,
        );

        if (_smoothedMoveDelta.distance >= 0.12) {
          final gain = _ballisticGain(speed) * widget.dpi;
          _queueMove(
            Offset(
              _smoothedMoveDelta.dx * gain,
              _smoothedMoveDelta.dy * gain,
            ),
          );
        }
      }
    } else if (_pointers.length == 2 && _maxPointersInGesture < 3) {
      _wasMultiFingerGesture = true;
      final centroid = _centroidOf(_pointers.values.take(2));
      final centroidDelta = _lastTwoFingerCentroid != null
          ? centroid - _lastTwoFingerCentroid!
          : Offset.zero;
      _lastTwoFingerCentroid = centroid;

      if (centroidDelta != Offset.zero) {
        // Soft axis lock: suppress accidental horizontal drift during vertical scroll.
        var sx = centroidDelta.dx;
        var sy = centroidDelta.dy;
        if (sy.abs() > sx.abs() * 2.2) {
          sx = 0.0;
        } else if (sx.abs() > sy.abs() * 2.2) {
          sy = 0.0;
        }

        // Accumulate same-timestamp pointer moves so two fingers in one frame
        // never divide by a synthetic 0.004s dt and inflate inertia speed.
        _scrollFrameDelta += Offset(sx, sy);
        if (_lastScrollTimestamp == null) {
          _lastScrollTimestamp = event.timeStamp;
        } else if (event.timeStamp > _lastScrollTimestamp!) {
          final dtSec =
              ((event.timeStamp - _lastScrollTimestamp!).inMicroseconds / 1e6)
                  .clamp(0.004, 0.25);
          _lastScrollTimestamp = event.timeStamp;
          final instVel = _scrollFrameDelta / dtSec;
          _scrollFrameDelta = Offset.zero;
          _scrollVelocity = Offset(
            _scrollVelocity.dx * 0.40 + instVel.dx * 0.60,
            _scrollVelocity.dy * 0.40 + instVel.dy * 0.60,
          );
        }

        _queueScroll(Offset(sx * 0.65, sy * 0.65));
      }
    } else if (_pointers.length >= 3) {
      _wasMultiFingerGesture = true;
      final centroid = _centroidOf(_pointers.values.take(3));
      _threeFingerStartCentroid ??= centroid;

      if (widget.onShortcut != null && !_threeFingerSwipeTriggered) {
        final offset = centroid - _threeFingerStartCentroid!;
        if (offset.distance >= _threeFingerSwipeThreshold) {
          _threeFingerSwipeTriggered = true;
          GamepadHaptics.lightImpact();

          if (offset.dy.abs() >= offset.dx.abs()) {
            if (offset.dy < 0) {
              // 3-Finger Swipe Up: Task View / Mission Control
              widget.onShortcut?.call(const ['META', 'TAB']);
              _showGestureFeedback('TASK VIEW');
            } else {
              // 3-Finger Swipe Down: Show Desktop
              widget.onShortcut?.call(const ['META', 'D']);
              _showGestureFeedback('SHOW DESKTOP');
            }
          } else {
            if (offset.dx > 0) {
              // 3-Finger Swipe Right: Switch App Next
              widget.onShortcut?.call(const ['ALT', 'TAB']);
              _showGestureFeedback('SWITCH APP ▶');
            } else {
              // 3-Finger Swipe Left: Switch App Prev
              widget.onShortcut?.call(const ['ALT', 'SHIFT', 'TAB']);
              _showGestureFeedback('◀ SWITCH APP');
            }
          }
        }
      }
    }

    _syncFingerDots();
  }

  void _handlePointerEnd(int pointerId, {required bool canceled}) {
    _pointers.remove(pointerId);
    _downPositions.remove(pointerId);
    if (_pointers.length < 2) {
      _lastTwoFingerCentroid = null;
    }
    if (_pointers.length < 3) {
      _threeFingerStartCentroid = null;
    }

    _syncFingerDots();

    if (_pointers.isEmpty) {
      _flushPending();
      final wasDragLocked = _isDragLocked;

      if (_isDragLocked) {
        _isDragLocked = false;
        widget.onMouseButton(MouseButton.left, false);
      } else if (!canceled && _gestureStart != null) {
        final elapsedMs =
            DateTime.now().difference(_gestureStart!).inMilliseconds;
        final isTap = elapsedMs <= 260 &&
            _maxTravel < 12.0 &&
            !_threeFingerSwipeTriggered;

        if (isTap && !_stoppedInertiaOnDown) {
          GamepadHaptics.lightImpact();
          if (_maxPointersInGesture >= 3) {
            // 3-Finger Tap: Middle Click
            widget.onMouseButton(MouseButton.middle, true);
            widget.onMouseButton(MouseButton.middle, false);
            _showGestureFeedback('MIDDLE CLICK');
            _lastSingleTapAt = null;
          } else if (_maxPointersInGesture == 2) {
            // 2-Finger Tap: Right Click
            widget.onMouseButton(MouseButton.right, true);
            widget.onMouseButton(MouseButton.right, false);
            _lastSingleTapAt = null;
          } else {
            // 1-Finger Tap: Left Click
            widget.onMouseButton(MouseButton.left, true);
            widget.onMouseButton(MouseButton.left, false);
            _lastSingleTapAt = DateTime.now();
          }
        } else if (_maxPointersInGesture == 2 && _wasMultiFingerGesture) {
          _startInertiaIfFastEnough();
        }
      }

      _gestureStart = null;
      _maxPointersInGesture = 0;
      _maxTravel = 0.0;
      _wasMultiFingerGesture = false;
      _threeFingerSwipeTriggered = false;
      _stoppedInertiaOnDown = false;
      _lastMoveTimestamp = null;
      _lastScrollTimestamp = null;
      _smoothedMoveDelta = Offset.zero;

      if (wasDragLocked || mounted) {
        setState(() {});
      }
    }
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

                // Live multi-touch finger indicators (repainted without setState)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TouchIndicatorsPainter(
                        positions: _fingerPositions,
                        accentColor: p.highlightBorder,
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
                        : (_gestureFeedback ?? widget.caption),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (_isDragLocked || _gestureFeedback != null)
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

class _TouchIndicatorsPainter extends CustomPainter {
  final ValueNotifier<List<Offset>> positions;
  final Color accentColor;

  _TouchIndicatorsPainter({
    required this.positions,
    required this.accentColor,
  }) : super(repaint: positions);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = positions.value;
    if (pts.isEmpty) return;

    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final pos in pts) {
      canvas.drawCircle(pos, 16, fillPaint);
      canvas.drawCircle(pos, 16, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TouchIndicatorsPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor ||
      oldDelegate.positions != positions;
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