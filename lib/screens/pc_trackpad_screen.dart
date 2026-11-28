import 'package:flutter/material.dart';

import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';
import '../theme/pc_suite_theme.dart';
import '../widgets/pc_suite_parts.dart';

/// Mode 1: PC Trackpad & Mouse remote screen. Supports Landscape (`852x393`)
/// and Portrait (`393x852`) reference artboards via [OrientationBuilder].
class PcTrackpadScreen extends StatefulWidget {
  final PcSuiteScreenConfig config;
  final void Function(double dx, double dy) onMouseMove;
  final void Function(MouseButton button, bool pressed) onMouseButton;
  final void Function(double dx, double dy) onMouseScroll;
  final void Function(String key) onTapKey;
  final void Function(List<String> keys) onShortcut;

  const PcTrackpadScreen({
    super.key,
    required this.config,
    required this.onMouseMove,
    required this.onMouseButton,
    required this.onMouseScroll,
    required this.onTapKey,
    required this.onShortcut,
  });

  @override
  State<PcTrackpadScreen> createState() => _PcTrackpadScreenState();
}

enum _TrackpadSlot {
  keyboard,
  volDown,
  volUp,
  dpi,
  mic,
  menu,
  lmb,
  mid,
  rmb,
  back,
  winCmd,
  fwd,
}

class _PcTrackpadScreenState extends State<PcTrackpadScreen> {
  static const List<double> _dpiSteps = [0.8, 1.0, 1.2, 1.5, 2.0];
  int _dpiIndex = 2; // 1.2x default
  bool _micMuted = false;

  double get _dpi => _dpiSteps[_dpiIndex];

  void _cycleDpi() =>
      setState(() => _dpiIndex = (_dpiIndex + 1) % _dpiSteps.length);

  void _toggleMic() {
    setState(() => _micMuted = !_micMuted);
    widget.onTapKey('MIC_MUTE');
  }

  Widget _slot(
    _TrackpadSlot slot,
    PcSuiteTheme p,
    double Function(double) s, {
    required double x,
    required double y,
    required double w,
    required double h,
    double radius = 8,
    String? labelOverride,
    double fontSize = 10.5,
  }) {
    final cfg = widget.config;

    Widget buildBtn({
      required String label,
      required PcKeyVariant variant,
      bool enableRepeat = false,
      bool latched = false,
      VoidCallback? onTap,
      ValueChanged<bool>? onPressChanged,
    }) {
      return Positioned(
        left: s(x),
        top: s(y),
        child: PcSuiteKeyButton(
          palette: p,
          label: labelOverride ?? label,
          width: s(w),
          height: s(h),
          borderRadius: s(radius),
          fontSize: s(fontSize),
          variant: variant,
          enableRepeat: enableRepeat,
          isLatched: latched,
          onTap: onTap,
          onPressChanged: onPressChanged,
        ),
      );
    }

    return switch (slot) {
      _TrackpadSlot.keyboard => buildBtn(
          label: 'KEYBOARD',
          variant: PcKeyVariant.modeSwitch,
          onTap: () => cfg.onSwitchStyle(GamepadStyle.pcKeyboardWin),
        ),
      _TrackpadSlot.volDown => buildBtn(
          label: 'VOL −',
          variant: PcKeyVariant.modifier,
          enableRepeat: true,
          onTap: () => widget.onTapKey('VOLUME_DOWN'),
        ),
      _TrackpadSlot.volUp => buildBtn(
          label: 'VOL +',
          variant: PcKeyVariant.modifier,
          enableRepeat: true,
          onTap: () => widget.onTapKey('VOLUME_UP'),
        ),
      _TrackpadSlot.dpi => buildBtn(
          label: 'DPI ${_dpi.toStringAsFixed(1)}x',
          variant: PcKeyVariant.modifier,
          onTap: _cycleDpi,
        ),
      _TrackpadSlot.mic => buildBtn(
          label: 'MIC',
          variant: _micMuted ? PcKeyVariant.alert : PcKeyVariant.modifier,
          latched: _micMuted,
          onTap: _toggleMic,
        ),
      _TrackpadSlot.menu => buildBtn(
          label: '☰',
          variant: PcKeyVariant.modifier,
          onTap: cfg.onOpenMenu,
        ),
      _TrackpadSlot.lmb => buildBtn(
          label: 'LEFT CLICK (LMB)',
          variant: PcKeyVariant.standard,
          onPressChanged: (d) => widget.onMouseButton(MouseButton.left, d),
        ),
      _TrackpadSlot.mid => buildBtn(
          label: 'MID',
          variant: PcKeyVariant.modeSwitch,
          onPressChanged: (d) => widget.onMouseButton(MouseButton.middle, d),
        ),
      _TrackpadSlot.rmb => buildBtn(
          label: 'RIGHT CLICK (RMB)',
          variant: PcKeyVariant.standard,
          onPressChanged: (d) => widget.onMouseButton(MouseButton.right, d),
        ),
      _TrackpadSlot.back => buildBtn(
          label: '◀ BACK',
          variant: PcKeyVariant.modifier,
          onTap: () => widget.onShortcut(const ['ALT', 'ARROW_LEFT']),
        ),
      _TrackpadSlot.winCmd => buildBtn(
          label: 'WIN / ⌘',
          variant: PcKeyVariant.modeSwitch,
          onTap: () => widget.onTapKey('META'),
        ),
      _TrackpadSlot.fwd => buildBtn(
          label: 'FWD ▶',
          variant: PcKeyVariant.modifier,
          onTap: () => widget.onShortcut(const ['ALT', 'ARROW_RIGHT']),
        ),
    };
  }

  Widget _trackpad(
    PcSuiteTheme p,
    double Function(double) s, {
    required double x,
    required double y,
    required double w,
    required double h,
    required String caption,
  }) {
    return Positioned(
      left: s(x),
      top: s(y),
      child: PcMultiTouchTrackpad(
        palette: p,
        width: s(w),
        height: s(h),
        borderRadius: s(18),
        crosshairSize: s(24),
        captionFontSize: s(10),
        caption: caption,
        dpi: _dpi,
        onMouseMove: widget.onMouseMove,
        onMouseButton: widget.onMouseButton,
        onMouseScroll: widget.onMouseScroll,
        onShortcut: widget.onShortcut,
      ),
    );
  }

  Widget _statusPill(
    PcSuiteTheme p,
    double Function(double) s, {
    required double x,
    required double y,
    required double w,
    required double fontSize,
  }) {
    return Positioned(
      left: s(x),
      top: s(y),
      child: PcSuiteStatusPill(
        palette: p,
        label: widget.config.status.label,
        dotColor: widget.config.status.color,
        width: s(w),
        height: s(34),
        fontSize: s(fontSize),
        onTap: widget.config.onOpenMenu,
      ),
    );
  }

  List<Widget> _landscape(PcSuiteTheme p, double Function(double) s) => [
        _slot(_TrackpadSlot.keyboard, p, s, x: 36, y: 16, w: 78, h: 34),
        _slot(_TrackpadSlot.volDown, p, s, x: 120, y: 16, w: 56, h: 34),
        _slot(_TrackpadSlot.volUp, p, s, x: 182, y: 16, w: 56, h: 34),
        _statusPill(p, s, x: 296, y: 16, w: 260, fontSize: 10),
        _slot(_TrackpadSlot.dpi, p, s, x: 616, y: 16, w: 78, h: 34),
        _slot(_TrackpadSlot.mic, p, s, x: 700, y: 16, w: 52, h: 34),
        _slot(_TrackpadSlot.menu, p, s,
            x: 758, y: 16, w: 58, h: 34, fontSize: 13),
        _trackpad(
          p,
          s,
          x: 36,
          y: 64,
          w: 780,
          h: 242,
          caption: 'MULTI-TOUCH TRACKPAD • 2-FINGER SCROLL • 3-FINGER GESTURES',
        ),
        _slot(_TrackpadSlot.lmb, p, s,
            x: 36, y: 320, w: 324, h: 56, radius: 12, fontSize: 12),
        _slot(_TrackpadSlot.mid, p, s,
            x: 372, y: 320, w: 108, h: 56, radius: 12, fontSize: 12),
        _slot(_TrackpadSlot.rmb, p, s,
            x: 492, y: 320, w: 324, h: 56, radius: 12, fontSize: 12),
      ];

  List<Widget> _portrait(PcSuiteTheme p, double Function(double) s) => [
        _slot(_TrackpadSlot.keyboard, p, s, x: 20, y: 20, w: 84, h: 34),
        _slot(_TrackpadSlot.dpi, p, s, x: 192, y: 20, w: 74, h: 34),
        _slot(_TrackpadSlot.mic, p, s, x: 272, y: 20, w: 48, h: 34),
        _slot(_TrackpadSlot.menu, p, s,
            x: 326, y: 20, w: 47, h: 34, fontSize: 13),
        _statusPill(p, s, x: 20, y: 66, w: 225, fontSize: 9.5),
        _slot(_TrackpadSlot.volDown, p, s, x: 251, y: 66, w: 58, h: 34),
        _slot(_TrackpadSlot.volUp, p, s, x: 315, y: 66, w: 58, h: 34),
        _trackpad(
          p,
          s,
          x: 20,
          y: 116,
          w: 353,
          h: 528,
          caption: 'MULTI-TOUCH TRACKPAD • 2-FINGER SCROLL • 3-FINGER GESTURES',
        ),
        _slot(_TrackpadSlot.lmb, p, s,
            x: 20,
            y: 660,
            w: 138,
            h: 76,
            radius: 14,
            fontSize: 12,
            labelOverride: 'LMB (LEFT)'),
        _slot(_TrackpadSlot.mid, p, s,
            x: 166, y: 660, w: 61, h: 76, radius: 14, fontSize: 12),
        _slot(_TrackpadSlot.rmb, p, s,
            x: 235,
            y: 660,
            w: 138,
            h: 76,
            radius: 14,
            fontSize: 12,
            labelOverride: 'RMB (RIGHT)'),
        _slot(_TrackpadSlot.back, p, s,
            x: 20, y: 752, w: 112, h: 48, radius: 12),
        _slot(_TrackpadSlot.winCmd, p, s,
            x: 140, y: 752, w: 113, h: 48, radius: 12),
        _slot(_TrackpadSlot.fwd, p, s,
            x: 261, y: 752, w: 112, h: 48, radius: 12),
      ];

  @override
  Widget build(BuildContext context) {
    final p = widget.config.palette;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        return PcArtboardShell(
          key: ValueKey(
            isPortrait ? 'pc_trackpad_portrait' : 'pc_trackpad_landscape',
          ),
          palette: p,
          artboardWidth: isPortrait ? 393 : 852,
          artboardHeight: isPortrait ? 852 : 393,
          hudOpacity: widget.config.hudOpacity,
          symmetricNotchPadding: !isPortrait,
          builder: (s) => isPortrait ? _portrait(p, s) : _landscape(p, s),
        );
      },
    );
  }
}
