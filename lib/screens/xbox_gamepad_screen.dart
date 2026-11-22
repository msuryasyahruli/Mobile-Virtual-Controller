import 'package:flutter/material.dart';

import '../models/gamepad_input.dart';
import '../theme/gamepad_theme.dart';
import '../widgets/dedicated_stick_click_button.dart';
import '../widgets/gamepad_dpad.dart';
import '../widgets/gamepad_face_buttons.dart';
import '../widgets/gamepad_shoulder_button.dart';
import '../widgets/gamepad_thumbstick.dart';
import 'gamepad_layout_parts.dart';

/// Xbox Series asymmetric controller screen (`LT/LB`, `RB/RT`, top-left stick,
/// enlarged Hybrid D-Pad dish, `View`/`Xbox Guide`/`Menu`/`Share`, dedicated
/// `LS`/`RS`, and `Y B A X` diamond face buttons).
class XboxGamepadScreen extends StatelessWidget {
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

  const XboxGamepadScreen({
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
        final viewW = b(36);
        final viewH = b(26);
        final shareW = b(28);
        final shareH = b(20);
        final homeSize = b(40);

        return [
          // Top bar: LT, LB, M1 | Status + Settings | M2, RB, RT.
          GamepadTopStatusBar(
            theme: theme,
            s: s,
            status: status,
            statusPillWidth: 132,
            onOpenMenu: onOpenMenu,
            leftShoulders: [
              GamepadShoulderButton(
                theme: theme,
                label: 'LT',
                width: triggerWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(lt: down ? 1.0 : 0.0)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'LB',
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
                label: 'RB',
                width: bumperWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(rb: down)),
              ),
              SizedBox(width: s(8)),
              GamepadShoulderButton(
                theme: theme,
                label: 'RT',
                width: triggerWidth,
                height: shoulderHeight,
                borderRadius: s(GamepadRadii.md),
                onPressed: (down) =>
                    onInputChanged(getInput().copyWith(rt: down ? 1.0 : 0.0)),
              ),
            ],
          ),

          // Left Cluster: Top-left Analog Stick (green-rimmed concave center).
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

          // Left Cluster: Enlarged Hybrid D-Pad dish (132x132).
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

          // Center: View button (36x26).
          centeredGamepadControl(
            s: s,
            cx: 366,
            cy: 160,
            width: viewW,
            height: viewH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'View',
              width: viewW,
              height: viewH,
              borderRadius: b(GamepadRadii.md),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(select: down)),
              child: Icon(
                Icons.filter_none_rounded,
                size: b(13),
                color: theme.textPrimary,
              ),
            ),
          ),

          // Center: Xbox Guide / Nexus sphere (40x40) opening Controller Settings.
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
              style: GamepadStyle.xbox,
              onTap: onOpenMenu,
            ),
          ),

          // Center: Menu button (36x26).
          centeredGamepadControl(
            s: s,
            cx: 486,
            cy: 160,
            width: viewW,
            height: viewH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'Menu',
              width: viewW,
              height: viewH,
              borderRadius: b(GamepadRadii.md),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(start: down)),
              child: Icon(
                Icons.menu_rounded,
                size: b(15),
                color: theme.textPrimary,
              ),
            ),
          ),

          // Center: Share button (28x20).
          centeredGamepadControl(
            s: s,
            cx: 426,
            cy: 214,
            width: shareW,
            height: shareH,
            enforceMinHitTarget: true,
            child: GamepadUtilityButton(
              theme: theme,
              semanticLabel: 'Share',
              width: shareW,
              height: shareH,
              borderRadius: b(GamepadRadii.sm),
              onPressed: (down) =>
                  onInputChanged(getInput().copyWith(select: down)),
              child: Icon(
                Icons.ios_share_rounded,
                size: b(11),
                color: theme.textSecondary,
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

          // Right Cluster: Face Button Plate (Y top, B right, A bottom, X left).
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
