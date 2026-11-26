import 'package:flutter/material.dart';

import '../theme/gamepad_theme.dart';
import '../widgets/pc_suite_parts.dart';

/// Modes 2 & 3: Mechanical 65% US QWERTY Keyboard for Windows and macOS (`852x393`).
class PcKeyboardScreen extends StatefulWidget {
  final PcSuiteScreenConfig config;
  final bool isMac;
  final void Function(String key, bool pressed, Set<String> modifiers)
      onKeyEvent;
  final void Function(List<String> keys) onShortcut;

  const PcKeyboardScreen({
    super.key,
    required this.config,
    required this.isMac,
    required this.onKeyEvent,
    required this.onShortcut,
  });

  @override
  State<PcKeyboardScreen> createState() => _PcKeyboardScreenState();
}

class _PcKeyboardScreenState extends State<PcKeyboardScreen> {
  bool _fnActive = false;
  bool _capsLatched = false;
  final Set<String> _heldModifiers = {};
  final Set<String> _latchedModifiers = {};
  final Map<String, DateTime> _modifierDownAt = {};
  bool _nonModifierPressedWhileModHeld = false;

  Set<String> get _activeModifiers => {
        ..._heldModifiers,
        ..._latchedModifiers,
      };

  void _handleModifierPress(String modId, bool pressed) {
    if (pressed) {
      _modifierDownAt[modId] = DateTime.now();
      _nonModifierPressedWhileModHeld = false;
      final alreadyLatched = _latchedModifiers.contains(modId);
      setState(() => _heldModifiers.add(modId));
      if (!alreadyLatched) {
        widget.onKeyEvent(modId, true, _activeModifiers);
      }
      return;
    }

    final downAt = _modifierDownAt.remove(modId);
    final quickTap = downAt != null &&
        DateTime.now().difference(downAt).inMilliseconds <= 250 &&
        !_nonModifierPressedWhileModHeld;

    if (quickTap) {
      final wasLatched = _latchedModifiers.contains(modId);
      setState(() {
        _heldModifiers.remove(modId);
        if (wasLatched) {
          _latchedModifiers.remove(modId);
        } else {
          _latchedModifiers.add(modId);
        }
      });
      // Stay logically pressed while latched; only emit release when unlatching.
      if (wasLatched) {
        widget.onKeyEvent(modId, false, _activeModifiers);
      }
    } else {
      setState(() => _heldModifiers.remove(modId));
      widget.onKeyEvent(modId, false, _activeModifiers);
    }
  }

  void _handleStandardKey(String keyCode, bool pressed) {
    if (pressed) {
      if (_heldModifiers.isNotEmpty) {
        _nonModifierPressedWhileModHeld = true;
      }
      widget.onKeyEvent(keyCode, true, _activeModifiers);
      return;
    }

    final modsAtRelease = _activeModifiers;
    widget.onKeyEvent(keyCode, false, modsAtRelease);

    if (_latchedModifiers.isNotEmpty) {
      final toRelease = _latchedModifiers.toList();
      setState(() => _latchedModifiers.clear());
      for (final modId in toRelease) {
        widget.onKeyEvent(modId, false, _activeModifiers);
      }
    }
  }

  void _handleRepeatKeyTap(String keyCode) {
    final mods = _activeModifiers;
    widget.onKeyEvent(keyCode, true, mods);
    widget.onKeyEvent(keyCode, false, mods);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.config.palette;
    final isMac = widget.isMac;
    final showUpper = _capsLatched ||
        _heldModifiers.contains('SHIFT') ||
        _latchedModifiers.contains('SHIFT');

    String letter(String ch) => showUpper ? ch.toUpperCase() : ch.toLowerCase();

    return PcArtboardShell(
      palette: p,
      hudOpacity: widget.config.hudOpacity,
      symmetricNotchPadding: true,
      builder: (s) {
        Widget keyBtn({
          required String label,
          required String code,
          required double width,
          double height = 46,
          double radius = 8,
          double fontSize = 11.5,
          String? subLabel,
          PcKeyVariant variant = PcKeyVariant.standard,
          bool enableRepeat = false,
        }) {
          return PcSuiteKeyButton(
            palette: p,
            label: label,
            subLabel: subLabel,
            width: s(width),
            height: s(height),
            borderRadius: s(radius),
            fontSize: s(fontSize),
            variant: variant,
            enableRepeat: enableRepeat,
            onPressChanged: (down) => _handleStandardKey(code, down),
            onRepeatTick: enableRepeat ? () => _handleRepeatKeyTap(code) : null,
          );
        }

        Widget modBtn({
          required String label,
          required String modCode,
          required double width,
          double height = 46,
          PcKeyVariant variant = PcKeyVariant.modifier,
        }) {
          final latched = _latchedModifiers.contains(modCode);
          return PcSuiteKeyButton(
            palette: p,
            label: label,
            width: s(width),
            height: s(height),
            borderRadius: s(8),
            fontSize: s(10.5),
            variant: variant,
            isLatched: latched,
            onPressChanged: (down) => _handleModifierPress(modCode, down),
          );
        }

        Widget buildRow(double y, List<Widget> children) {
          return Positioned(
            left: s(36),
            top: s(y),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(width: s(6)),
                  children[i],
                ],
              ],
            ),
          );
        }

        final numRowKeys = const [
          ('1', 'F1'),
          ('2', 'F2'),
          ('3', 'F3'),
          ('4', 'F4'),
          ('5', 'F5'),
          ('6', 'F6'),
          ('7', 'F7'),
          ('8', 'F8'),
          ('9', 'F9'),
          ('0', 'F10'),
          ('−', 'F11'),
          ('=', 'F12'),
        ];

        final shortcuts = isMac
            ? const [
                ('COPY (⌘C)', ['META', 'C'], PcKeyVariant.shortcut),
                ('PASTE (⌘V)', ['META', 'V'], PcKeyVariant.shortcut),
                ('UNDO (⌘Z)', ['META', 'Z'], PcKeyVariant.shortcut),
                ('SPOTLIGHT (⌘␣)', ['META', 'SPACE'], PcKeyVariant.highlight),
                ('MISSION CTRL', ['CTRL', 'UP'], PcKeyVariant.alert),
              ]
            : const [
                ('COPY (Ctrl+C)', ['CTRL', 'C'], PcKeyVariant.shortcut),
                ('PASTE (Ctrl+V)', ['CTRL', 'V'], PcKeyVariant.shortcut),
                ('UNDO (Ctrl+Z)', ['CTRL', 'Z'], PcKeyVariant.shortcut),
                ('ALT + TAB', ['ALT', 'TAB'], PcKeyVariant.highlight),
                ('TASK MGR', ['CTRL', 'SHIFT', 'ESC'], PcKeyVariant.alert),
              ];

        return [
          // Top Bar (y: 14, h: 34)
          Positioned(
            left: s(36),
            top: s(14),
            child: keyBtn(
              label: 'ESC',
              code: 'ESC',
              width: 56,
              height: 34,
              fontSize: 10.5,
              variant: PcKeyVariant.alert,
            ),
          ),
          Positioned(
            left: s(98),
            top: s(14),
            child: PcSuiteKeyButton(
              palette: p,
              label: isMac ? 'fn 🌐' : 'FN',
              width: s(50),
              height: s(34),
              borderRadius: s(8),
              fontSize: s(10.5),
              variant: PcKeyVariant.modifier,
              isLatched: _fnActive,
              onTap: () => setState(() => _fnActive = !_fnActive),
            ),
          ),
          Positioned(
            left: s(206),
            top: s(14),
            child: PcSuiteStatusPill(
              palette: p,
              label: widget.config.status.label,
              dotColor: widget.config.status.color,
              width: s(280),
              height: s(34),
              fontSize: s(9.8),
              onTap: widget.config.onOpenMenu,
            ),
          ),
          Positioned(
            left: s(494),
            top: s(14),
            child: PcSuiteKeyButton(
              palette: p,
              label: 'Win / macOS',
              width: s(92),
              height: s(34),
              borderRadius: s(8),
              fontSize: s(9.8),
              variant: PcKeyVariant.highlight,
              onTap: () => widget.config.onSwitchStyle(
                isMac ? GamepadStyle.pcKeyboardWin : GamepadStyle.pcKeyboardMac,
              ),
            ),
          ),
          Positioned(
            left: s(668),
            top: s(14),
            child: PcSuiteKeyButton(
              palette: p,
              label: 'TRACKPAD',
              width: s(84),
              height: s(34),
              borderRadius: s(8),
              fontSize: s(10.5),
              variant: PcKeyVariant.modeSwitch,
              onTap: () => widget.config.onSwitchStyle(GamepadStyle.pcTrackpad),
            ),
          ),
          Positioned(
            left: s(758),
            top: s(14),
            child: PcSuiteKeyButton(
              palette: p,
              label: '☰',
              width: s(58),
              height: s(34),
              borderRadius: s(8),
              fontSize: s(13),
              variant: PcKeyVariant.modeSwitch,
              onTap: widget.config.onOpenMenu,
            ),
          ),

          // Row 1 (y: 60, h: 46)
          buildRow(60, [
            for (final pair in numRowKeys)
              keyBtn(
                label: _fnActive ? pair.$2 : pair.$1,
                subLabel: _fnActive ? pair.$1 : pair.$2,
                code: _fnActive ? pair.$2 : pair.$1,
                width: 52,
                variant:
                    _fnActive ? PcKeyVariant.highlight : PcKeyVariant.standard,
              ),
            keyBtn(
              label: isMac ? '⌫ DELETE' : '⌫ BKSP',
              code: 'BACKSPACE',
              width: 84,
              fontSize: 10.5,
              variant: PcKeyVariant.alert,
              enableRepeat: true,
            ),
          ]),

          // Row 2 (y: 114, h: 46)
          buildRow(114, [
            keyBtn(
              label: 'TAB',
              code: 'TAB',
              width: 72,
              fontSize: 10.5,
              variant: PcKeyVariant.modifier,
            ),
            for (final ch in const [
              'Q',
              'W',
              'E',
              'R',
              'T',
              'Y',
              'U',
              'I',
              'O',
              'P',
              '[',
            ])
              keyBtn(label: ch == '[' ? '[' : letter(ch), code: ch, width: 52),
            keyBtn(label: ']', code: ']', width: 64),
          ]),

          // Row 3 (y: 168, h: 46)
          buildRow(168, [
            PcSuiteKeyButton(
              palette: p,
              label: 'CAPS',
              width: s(82),
              height: s(46),
              borderRadius: s(8),
              fontSize: s(10.5),
              variant: PcKeyVariant.modifier,
              isLatched: _capsLatched,
              onTap: () {
                setState(() => _capsLatched = !_capsLatched);
                widget.onKeyEvent('CAPS_LOCK', true, _activeModifiers);
                widget.onKeyEvent('CAPS_LOCK', false, _activeModifiers);
              },
            ),
            for (final ch in const [
              'A',
              'S',
              'D',
              'F',
              'G',
              'H',
              'J',
              'K',
              'L',
              ';',
            ])
              keyBtn(label: ch == ';' ? ';' : letter(ch), code: ch, width: 52),
            keyBtn(
              label: isMac ? '⏎ RETURN' : '↵ ENTER',
              code: 'ENTER',
              width: 112,
              fontSize: 11,
              variant: PcKeyVariant.cta,
            ),
          ]),

          // Row 4 (y: 222, h: 46)
          buildRow(222, [
            modBtn(label: '⇧ SHIFT', modCode: 'SHIFT', width: 104),
            for (final ch in const [
              'Z',
              'X',
              'C',
              'V',
              'B',
              'N',
              'M',
              ',',
              '.',
              '/',
            ])
              keyBtn(
                label: (ch == ',' || ch == '.' || ch == '/') ? ch : letter(ch),
                code: ch,
                width: 52,
              ),
            keyBtn(
              label: '▲',
              code: 'ARROW_UP',
              width: 90,
              fontSize: 12,
              variant: PcKeyVariant.highlight,
              enableRepeat: true,
            ),
          ]),

          // Row 5 (y: 276, h: 50)
          buildRow(276, [
            modBtn(
              label: isMac ? '⌃ CTRL' : 'CTRL',
              modCode: 'CTRL',
              width: 68,
              height: 50,
            ),
            modBtn(
              label: isMac ? '⌥ OPT' : 'WIN',
              modCode: isMac ? 'ALT' : 'META',
              width: 56,
              height: 50,
            ),
            modBtn(
              label: isMac ? '⌘ CMD' : 'ALT',
              modCode: isMac ? 'META' : 'ALT',
              width: 56,
              height: 50,
              variant: isMac ? PcKeyVariant.highlight : PcKeyVariant.modifier,
            ),
            keyBtn(
              label: 'SPACE',
              code: 'SPACE',
              width: 328,
              height: 50,
              radius: 10,
              fontSize: 11,
              enableRepeat: true,
            ),
            modBtn(
              label: isMac ? '⌘ CMD' : 'ALT',
              modCode: isMac ? 'META' : 'ALT',
              width: 56,
              height: 50,
              variant: isMac ? PcKeyVariant.highlight : PcKeyVariant.modifier,
            ),
            keyBtn(
              label: '◀',
              code: 'ARROW_LEFT',
              width: 58,
              height: 50,
              fontSize: 12,
              variant: PcKeyVariant.highlight,
              enableRepeat: true,
            ),
            keyBtn(
              label: '▼',
              code: 'ARROW_DOWN',
              width: 58,
              height: 50,
              fontSize: 12,
              variant: PcKeyVariant.highlight,
              enableRepeat: true,
            ),
            keyBtn(
              label: '▶',
              code: 'ARROW_RIGHT',
              width: 58,
              height: 50,
              fontSize: 12,
              variant: PcKeyVariant.highlight,
              enableRepeat: true,
            ),
          ]),

          // Bottom Shortcut Strip (y: 338, h: 36, 5 pills 148x36 with 10px gap)
          Positioned(
            left: s(36),
            top: s(338),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < shortcuts.length; i++) ...[
                  if (i > 0) SizedBox(width: s(10)),
                  PcSuiteKeyButton(
                    palette: p,
                    label: shortcuts[i].$1,
                    width: s(148),
                    height: s(36),
                    borderRadius: s(8),
                    fontSize: s(10),
                    variant: shortcuts[i].$3,
                    onTap: () => widget.onShortcut(shortcuts[i].$2),
                  ),
                ],
              ],
            ),
          ),
        ];
      },
    );
  }
}
