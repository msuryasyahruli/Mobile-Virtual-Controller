import 'package:flutter/material.dart';

import '../models/gamepad_input.dart';
import '../theme/gamepad_theme.dart';
import '../widgets/dedicated_stick_click_button.dart';
import '../widgets/gamepad_dpad.dart';
import '../widgets/gamepad_face_buttons.dart';
import '../widgets/gamepad_shoulder_button.dart';
import '../widgets/gamepad_thumbstick.dart';
import '../widgets/gamepad_touchpad.dart';
import 'gamepad_layout_parts.dart';

/// PlayStation DualSense symmetric controller screen (`L2/L1`, `R1/R2`,
/// recessed D-Pad, dual symmetric sticks, Touchpad, `SHARE`/`OPT`, `PS` Home,
/// dedicated `L3`/`R3`, and `△ ○ ✕ □` diamond face buttons).
class PlayStationGamepadScreen extends StatelessWidget {
  final GamepadTheme theme;
  final GamepadButtonSize buttonSize;
  final double deadzone;
  final double hudOpacity;
  final GamepadStatusBadge status;
  final String? serverIp;
  final int serverPort;
  final GamepadInput Function() getInput;
  final ValueChanged<GamepadInput> onInputChanged;
  final VoidCallback onOpenMenu;

  const PlayStationGamepadScreen({
    super.key,
    required this.theme,
    required this.buttonSize,
    required this.status,
    required this.serverIp,
    required this.serverPort,
    required this.getInput,
    required this.onInputChanged,
    required this.onOpenMenu,
    this.deadzone = 0.05,
    this.hudOpacity = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final bs = buttonSize.scale;

    return GamepadCanvasShell(
      theme: theme,
      hudOpacity: hudOpacity,
      builder: (s) {
        double b(double v) => s(v * bs);

        final shoulderHeight = s((32 * bs).clamp(26.0, 36.0));
        final triggerWidth = s(72 * bs);
        final bumperWidth = s(64 * bs);
        final macroWidth = s(44 * bs);

        final dpadSize = b(144);
        final plateSize = b(144);
        final faceBtnSize = b(44);
        final stickSocket = b(96);
        final stickCap = b(64);
        final stickIndent = b(36);
        final clickW = b(48);
        final clickH = b(36);
        final utilW = b(44);
        final utilH = b(26);
        final homeSize = b(40);

        return [
          // Top bar: L2, L1, M1 | Status + Settings | M2, R1, R2.
          GamepadTopStatusBar(
            theme: theme,
            s: s,
            status: status,
            statusPillWidth: 132,
            onOpenMenu: onOpenMenu,
            leftShoulders: [
              GamepadShoulderButton(
                theme: theme,
                label: 'L2',
                width: triggerWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(lt: down ? 1.0 : 0.0)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'L1',
                width: bumperWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(lb: down)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'M1',
                width: macroWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                fillColorOverride: theme.macroLeftFill,
                borderColorOverride: theme.macroLeftBorder,
                borderWidth: 1.5,
                textColorOverride: theme.macroLeftText,
                accentColorOverride: theme.macroLeftBorder,
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(l3: down)),
              ),
            ],
            rightShoulders: [
              GamepadShoulderButton(
                theme: theme,
                label: 'M2',
                width: macroWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                fillColorOverride: theme.macroRightFill,
                borderColorOverride: theme.macroRightBorder,
                borderWidth: 1.5,
                textColorOverride: theme.macroRightText,
                accentColorOverride: theme.macroRightBorder,
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(r3: down)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'R1',
                width: bumperWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(rb: down)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'R2',
                width: triggerWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(rt: down ? 1.0 : 0.0)),
              ),
            ],
          ),

          // Left Cluster: Recessed D-Pad (144x144).
          centeredGamepadControl(
            s: s,
            cx: 114,
            cy: 138,
            width: dpadSize,
            height: dpadSize,
            child: GamepadDPad(
              theme: theme,
              size: dpadSize,
              onChanged: (up, down, left, right) => onInputChanged(
                getInput().copyWith(
                  dpadUp: up,
                  dpadDown: down,
                  dpadLeft: left,
                  dpadRight: right,
                ),
              ),
            ),
          ),

          // Left Cluster: Dedicated L3 button (48x36).
          centeredGamepadControl(
            s: s,
            cx: 82,
            cy: 284,
            width: clickW,
            height: clickH,
            enforceMinHitTarget: true,
            child: DedicatedStickClickButton(
              theme: theme,
              label: 'L3',
              width: clickW,
              height: clickH,
              borderRadius: b(GamepadRadii.lg),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(l3: down)),
            ),
          ),

          // Left Cluster: Left Analog Stick (96 socket / 64 cap / 36 indent).
          centeredGamepadControl(
            s: s,
            cx: 224,
            cy: 276,
            width: stickSocket,
            height: stickSocket,
            child: GamepadThumbstick(
              theme: theme,
              socketSize: stickSocket,
              capSize: stickCap,
              indentSize: stickIndent,
              deadzone: deadzone,
              onChanged: (offset) => onInputChanged(
                getInput().copyWith(lx: offset.dx, ly: offset.dy),
              ),
            ),
          ),

          // Center: SHARE button (44x26).
          centeredGamepadControl(
            s: s,
            cx: 250,
            cy: 89,
            width: utilW,
            height: utilH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'Share',
              width: utilW,
              height: utilH,
              borderRadius: b(GamepadRadii.sm),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(select: down)),
              child: Text(
                'SHARE',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: b(8.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          // Center: DualSense Touchpad (280x160) with blue lightbar.
          Positioned(
            left: s(286),
            top: s(68),
            child: GamepadTouchpad(
              theme: theme,
              width: s(280),
              height: s(160),
              borderRadius: s(GamepadRadii.xl),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(select: down)),
            ),
          ),

          // Center: OPTIONS button (44x26).
          centeredGamepadControl(
            s: s,
            cx: 602,
            cy: 89,
            width: utilW,
            height: utilH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'Options',
              width: utilW,
              height: utilH,
              borderRadius: b(GamepadRadii.sm),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(start: down)),
              child: Text(
                'OPT',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: b(8.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          // Center: PS Home button (40x40) opening Controller Settings.
          centeredGamepadControl(
            s: s,
            cx: 426,
            cy: 272,
            width: homeSize,
            height: homeSize,
            enforceMinHitTarget: true,
            child: GamepadHomeButton(
              theme: theme,
              size: homeSize,
              style: GamepadStyle.playstation,
              onTap: onOpenMenu,
            ),
          ),

          // Center: Passive DualSense amber Mute LED chassis indicator (16x6).
          Positioned(
            left: s(418),
            top: s(304),
            child: IgnorePointer(
              child: Container(
                width: s(16),
                height: s(6),
                decoration: BoxDecoration(
                  color: theme.muteLed,
                  borderRadius: BorderRadius.circular(s(3)),
                ),
              ),
            ),
          ),

          // Center: Connected IP:port caption.
          GamepadEndpointCaption(
            theme: theme,
            s: s,
            top: 326,
            ip: serverIp,
            port: serverPort,
          ),

          // Right Cluster: Face Button Plate (△ top, ○ right, ✕ bottom, □ left).
          centeredGamepadControl(
            s: s,
            cx: 738,
            cy: 138,
            width: plateSize,
            height: plateSize,
            child: GamepadFaceButtons(
              theme: theme,
              plateSize: plateSize,
              buttonSize: faceBtnSize,
              onTopChanged: (down) =>
                  onInputChanged(getInput().copyWith(y: down)),
              onRightChanged: (down) =>
                  onInputChanged(getInput().copyWith(b: down)),
              onBottomChanged: (down) =>
                  onInputChanged(getInput().copyWith(a: down)),
              onLeftChanged: (down) =>
                  onInputChanged(getInput().copyWith(x: down)),
            ),
          ),

          // Right Cluster: Right Analog Stick.
          centeredGamepadControl(
            s: s,
            cx: 628,
            cy: 276,
            width: stickSocket,
            height: stickSocket,
            child: GamepadThumbstick(
              theme: theme,
              socketSize: stickSocket,
              capSize: stickCap,
              indentSize: stickIndent,
              deadzone: deadzone,
              onChanged: (offset) => onInputChanged(
                getInput().copyWith(rx: offset.dx, ry: offset.dy),
              ),
            ),
          ),

          // Right Cluster: Dedicated R3 button (48x36).
          centeredGamepadControl(
            s: s,
            cx: 770,
            cy: 284,
            width: clickW,
            height: clickH,
            enforceMinHitTarget: true,
            child: DedicatedStickClickButton(
              theme: theme,
              label: 'R3',
              width: clickW,
              height: clickH,
              borderRadius: b(GamepadRadii.lg),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(r3: down)),
            ),
          ),
        ];
      },
    );
  }
}
