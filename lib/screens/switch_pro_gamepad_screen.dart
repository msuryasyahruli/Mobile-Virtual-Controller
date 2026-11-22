import 'package:flutter/material.dart';

import '../models/gamepad_input.dart';
import '../theme/gamepad_theme.dart';
import '../widgets/dedicated_stick_click_button.dart';
import '../widgets/gamepad_dpad.dart';
import '../widgets/gamepad_face_buttons.dart';
import '../widgets/gamepad_shoulder_button.dart';
import '../widgets/gamepad_thumbstick.dart';
import 'gamepad_layout_parts.dart';

/// Nintendo Switch Pro asymmetric controller screen (`ZL/L/M1`, `M2/R/ZR`,
/// Joy-Con Neon Blue left stick & Neon Red right stick, enlarged D-Pad,
/// `−`/`Home`/`+`/`Capture`, dedicated `LS`/`RS`, and Nintendo `X A B Y` diamond).
class SwitchProGamepadScreen extends StatelessWidget {
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

  const SwitchProGamepadScreen({
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

        final stickSocket = b(96);
        final stickCap = b(64);
        final stickIndent = b(36);
        final dpadSize = b(132);
        final plateSize = b(144);
        final faceBtnSize = b(44);
        final clickW = b(48);
        final clickH = b(36);
        final navW = b(36);
        final navH = b(26);
        final captureW = b(28);
        final captureH = b(20);
        final homeSize = b(40);

        return [
          // Top bar: ZL, L, M1 | Status + Settings (148x24) | M2, R, ZR.
          GamepadTopStatusBar(
            theme: theme,
            s: s,
            status: status,
            statusPillWidth: 148,
            onOpenMenu: onOpenMenu,
            leftShoulders: [
              GamepadShoulderButton(
                theme: theme,
                label: 'ZL',
                width: triggerWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(lt: down ? 1.0 : 0.0)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'L',
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
                label: 'R',
                width: bumperWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(rb: down)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'ZR',
                width: triggerWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(rt: down ? 1.0 : 0.0)),
              ),
            ],
          ),

          // Left Cluster: Top-left Analog Stick (Neon Blue inner rim).
          centeredGamepadControl(
            s: s,
            cx: 114,
            cy: 130,
            width: stickSocket,
            height: stickSocket,
            child: GamepadThumbstick(
              theme: theme,
              socketSize: stickSocket,
              capSize: stickCap,
              indentSize: stickIndent,
              deadzone: deadzone,
              indentBorderColor: theme.effectiveLeftStickIndentBorder,
              activeAccentColor: theme.effectiveLeftStickIndentBorder,
              onChanged: (offset) => onInputChanged(
                getInput().copyWith(lx: offset.dx, ly: offset.dy),
              ),
            ),
          ),

          // Left Cluster: Dedicated LS button (48x36).
          centeredGamepadControl(
            s: s,
            cx: 90,
            cy: 284,
            width: clickW,
            height: clickH,
            enforceMinHitTarget: true,
            child: DedicatedStickClickButton(
              theme: theme,
              label: 'LS',
              width: clickW,
              height: clickH,
              borderRadius: b(GamepadRadii.lg),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(l3: down)),
            ),
          ),

          // Left Cluster: Enlarged D-Pad (132x132).
          centeredGamepadControl(
            s: s,
            cx: 244,
            cy: 268,
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

          // Center: Minus (−, 36x26).
          centeredGamepadControl(
            s: s,
            cx: 366,
            cy: 160,
            width: navW,
            height: navH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'Minus',
              width: navW,
              height: navH,
              borderRadius: b(GamepadRadii.md),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(select: down)),
              child: Text(
                '−',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: b(16),
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),

          // Center: Switch Home button (⌂, 40x40) opening Controller Settings.
          centeredGamepadControl(
            s: s,
            cx: 426,
            cy: 160,
            width: homeSize,
            height: homeSize,
            enforceMinHitTarget: true,
            child: GamepadHomeButton(
              theme: theme,
              size: homeSize,
              style: GamepadStyle.nintendoSwitch,
              onTap: onOpenMenu,
            ),
          ),

          // Center: Plus (+, 36x26).
          centeredGamepadControl(
            s: s,
            cx: 486,
            cy: 160,
            width: navW,
            height: navH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'Plus',
              width: navW,
              height: navH,
              borderRadius: b(GamepadRadii.md),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(start: down)),
              child: Text(
                '+',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: b(16),
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),

          // Center: Capture button (●, 28x20).
          centeredGamepadControl(
            s: s,
            cx: 426,
            cy: 214,
            width: captureW,
            height: captureH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'Capture',
              width: captureW,
              height: captureH,
              borderRadius: b(GamepadRadii.sm),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(select: down)),
              child: Container(
                width: b(8),
                height: b(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ),

          // Center: Connected IP:port caption.
          GamepadEndpointCaption(
            theme: theme,
            s: s,
            top: 248,
            ip: serverIp,
            port: serverPort,
          ),

          // Right Cluster: Nintendo diamond (X top, A right, B bottom, Y left).
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
                  onInputChanged(getInput().copyWith(x: down)),
              onRightChanged: (down) =>
                  onInputChanged(getInput().copyWith(a: down)),
              onBottomChanged: (down) =>
                  onInputChanged(getInput().copyWith(b: down)),
              onLeftChanged: (down) =>
                  onInputChanged(getInput().copyWith(y: down)),
            ),
          ),

          // Right Cluster: Right Analog Stick (Neon Red inner rim).
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
              indentBorderColor: theme.effectiveRightStickIndentBorder,
              activeAccentColor: theme.effectiveRightStickIndentBorder,
              onChanged: (offset) => onInputChanged(
                getInput().copyWith(rx: offset.dx, ry: offset.dy),
              ),
            ),
          ),

          // Right Cluster: Dedicated RS button (48x36).
          centeredGamepadControl(
            s: s,
            cx: 770,
            cy: 284,
            width: clickW,
            height: clickH,
            enforceMinHitTarget: true,
            child: DedicatedStickClickButton(
              theme: theme,
              label: 'RS',
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
