import 'package:flutter/material.dart';

import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';
import '../widgets/pc_suite_parts.dart';

/// Mode 4: Hybrid Gaming (WASD + Mouse Aim Trackpad) screen (`852x393`).
class HybridWasdTrackpadScreen extends StatelessWidget {
  final PcSuiteScreenConfig config;
  final void Function(String key, bool pressed) onKeyChanged;
  final void Function(double dx, double dy) onMouseMove;
  final void Function(MouseButton button, bool pressed) onMouseButton;
  final void Function(double dx, double dy) onMouseScroll;

  const HybridWasdTrackpadScreen({
    super.key,
    required this.config,
    required this.onKeyChanged,
    required this.onMouseMove,
    required this.onMouseButton,
    required this.onMouseScroll,
  });

  @override
  Widget build(BuildContext context) {
    final p = config.palette;

    return PcArtboardShell(
      palette: p,
      hudOpacity: config.hudOpacity,
      symmetricNotchPadding: true,
      builder: (s) => [
        // Top Bar (y: 16, h: 34)
        Positioned(
          left: s(36),
          top: s(16),
          child: PcSuiteKeyButton(
            palette: p,
            label: 'ESC',
            width: s(56),
            height: s(34),
            borderRadius: s(8),
            fontSize: s(10.5),
            variant: PcKeyVariant.alert,
            onPressChanged: (down) => onKeyChanged('ESC', down),
          ),
        ),
        Positioned(
          left: s(98),
          top: s(16),
          child: PcSuiteKeyButton(
            palette: p,
            label: 'TAB',
            width: s(56),
            height: s(34),
            borderRadius: s(8),
            fontSize: s(10.5),
            variant: PcKeyVariant.modifier,
            onPressChanged: (down) => onKeyChanged('TAB', down),
          ),
        ),
        Positioned(
          left: s(286),
          top: s(16),
          child: PcSuiteStatusPill(
            palette: p,
            label: config.status.label,
            dotColor: config.status.color,
            width: s(280),
            height: s(34),
            fontSize: s(9.8),
            onTap: config.onOpenMenu,
          ),
        ),
        Positioned(
          left: s(674),
          top: s(16),
          child: PcSuiteKeyButton(
            palette: p,
            label: 'FULL KB',
            width: s(78),
            height: s(34),
            borderRadius: s(8),
            fontSize: s(10.5),
            variant: PcKeyVariant.modeSwitch,
            onTap: () => config.onSwitchStyle(GamepadStyle.pcKeyboardWin),
          ),
        ),
        Positioned(
          left: s(758),
          top: s(16),
          child: PcSuiteKeyButton(
            palette: p,
            label: '☰',
            width: s(58),
            height: s(34),
            borderRadius: s(8),
            fontSize: s(13),
            variant: PcKeyVariant.modeSwitch,
            onTap: config.onOpenMenu,
          ),
        ),

        // Left Gaming Key Cluster (x: 36..338)
        Positioned(
          left: s(36),
          top: s(68),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PcSuiteKeyButton(
                palette: p,
                label: 'Q',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(14),
                variant: PcKeyVariant.standard,
                onPressChanged: (down) => onKeyChanged('Q', down),
              ),
              SizedBox(width: s(10)),
              PcSuiteKeyButton(
                palette: p,
                label: 'W',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(15),
                variant: PcKeyVariant.highlight,
                onPressChanged: (down) => onKeyChanged('W', down),
              ),
              SizedBox(width: s(10)),
              PcSuiteKeyButton(
                palette: p,
                label: 'E',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(14),
                variant: PcKeyVariant.standard,
                onPressChanged: (down) => onKeyChanged('E', down),
              ),
              SizedBox(width: s(10)),
              PcSuiteKeyButton(
                palette: p,
                label: 'R',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(14),
                variant: PcKeyVariant.highlight,
                onPressChanged: (down) => onKeyChanged('R', down),
              ),
            ],
          ),
        ),

        Positioned(
          left: s(36),
          top: s(136),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PcSuiteKeyButton(
                palette: p,
                label: 'A',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(15),
                variant: PcKeyVariant.highlight,
                onPressChanged: (down) => onKeyChanged('A', down),
              ),
              SizedBox(width: s(10)),
              PcSuiteKeyButton(
                palette: p,
                label: 'S',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(15),
                variant: PcKeyVariant.highlight,
                onPressChanged: (down) => onKeyChanged('S', down),
              ),
              SizedBox(width: s(10)),
              PcSuiteKeyButton(
                palette: p,
                label: 'D',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(15),
                variant: PcKeyVariant.highlight,
                onPressChanged: (down) => onKeyChanged('D', down),
              ),
              SizedBox(width: s(10)),
              PcSuiteKeyButton(
                palette: p,
                label: 'F',
                width: s(68),
                height: s(58),
                borderRadius: s(10),
                fontSize: s(14),
                variant: PcKeyVariant.standard,
                onPressChanged: (down) => onKeyChanged('F', down),
              ),
            ],
          ),
        ),

        Positioned(
          left: s(36),
          top: s(208),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PcSuiteKeyButton(
                palette: p,
                label: 'SHIFT (SPRINT)',
                width: s(146),
                height: s(52),
                borderRadius: s(10),
                fontSize: s(11),
                variant: PcKeyVariant.modifier,
                onPressChanged: (down) => onKeyChanged('SHIFT', down),
              ),
              SizedBox(width: s(10)),
              PcSuiteKeyButton(
                palette: p,
                label: 'CTRL (CROUCH)',
                width: s(146),
                height: s(52),
                borderRadius: s(10),
                fontSize: s(11),
                variant: PcKeyVariant.modifier,
                onPressChanged: (down) => onKeyChanged('CTRL', down),
              ),
            ],
          ),
        ),

        Positioned(
          left: s(36),
          top: s(274),
          child: PcSuiteKeyButton(
            palette: p,
            label: 'SPACE (JUMP)',
            width: s(302),
            height: s(54),
            borderRadius: s(12),
            fontSize: s(13),
            variant: PcKeyVariant.cta,
            onPressChanged: (down) => onKeyChanged('SPACE', down),
          ),
        ),

        // Right Mouse / Aim Trackpad (x: 362, y: 68, w: 454, h: 238)
        Positioned(
          left: s(362),
          top: s(68),
          child: PcMultiTouchTrackpad(
            palette: p,
            width: s(454),
            height: s(238),
            borderRadius: s(18),
            crosshairSize: s(24),
            captionFontSize: s(10),
            caption: 'MOUSE / AIM TRACKPAD • TAP TO CLICK',
            dpi: 1.2,
            onMouseMove: onMouseMove,
            onMouseButton: onMouseButton,
            onMouseScroll: onMouseScroll,
          ),
        ),

        // Bottom Mouse Buttons (y: 320, h: 56, radius: 12)
        Positioned(
          left: s(362),
          top: s(320),
          child: PcSuiteKeyButton(
            palette: p,
            label: 'LMB (FIRE / CLICK)',
            width: s(220),
            height: s(56),
            borderRadius: s(12),
            fontSize: s(11.5),
            variant: PcKeyVariant.alert,
            onPressChanged: (down) => onMouseButton(MouseButton.left, down),
          ),
        ),
        Positioned(
          left: s(596),
          top: s(320),
          child: PcSuiteKeyButton(
            palette: p,
            label: 'RMB (ADS / MENU)',
            width: s(220),
            height: s(56),
            borderRadius: s(12),
            fontSize: s(11.5),
            variant: PcKeyVariant.modifier,
            onPressChanged: (down) => onMouseButton(MouseButton.right, down),
          ),
        ),
      ],
    );
  }
}
