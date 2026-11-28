# VControllers (Flutter Android Client)

Wireless gamepad, precision trackpad, and keyboard client for Android built with Flutter. Connects to a Windows PC or Mac running [Virtual Controller Server](https://github.com/msuryasyahruli/Virtual-Controller-Server.git) over **local WiFi (WebSocket)** or **Bluetooth (RFCOMM SPP)**.

## Fitur Utama

- **Dual Transport (WiFi & Bluetooth SPP)**:
  - **WiFi WebSocket**: Koneksi LAN berlatensi rendah ke `ws://<ip>:<port>` (default port `8765`) dengan auto-reconnect setiap 3 detik.
  - **Bluetooth RFCOMM SPP**: Koneksi langsung ke PC/Mac yang sudah di-pair di pengaturan Bluetooth Android (Android 12+ runtime permission & native bridge di `MainActivity.kt`).
- **3 Preset Layout Controller**:
  - **PlayStation (DualSense)**: Stick simetris, D-Pad recessed, tombol shapes (`△`, `○`, `✕`, `□`), Touchpad interaktif dengan lightbar, `SHARE`, `OPT`, `L1`/`L2`, `R1`/`R2`, macro `M1`/`M2`, dan `L3`/`R3`.
  - **Xbox Series**: Stick asimetris, Hybrid D-Pad dish, `Y`/`B`/`A`/`X`, `View`, `Menu`, `Share`, `LB`/`LT`, `RB`/`RT`, macro `M1`/`M2`, dan `LS`/`RS`.
  - **Nintendo Switch Pro**: Stick asimetris dengan aksen Joy-Con (Neon Blue/Red), D-Pad, layout fisik Nintendo (`X` atas, `A` kanan, `B` bawah, `Y` kiri), `−`, `+`, Capture (`●`), `ZL`/`L`, `R`/`ZR`, macro `M1`/`M2`, dan `LS`/`RS`.
- **Trackpad, Mouse & Keyboard Suite (4 Mode)**:
  - **Trackpad & Mouse**: Mendukung **Portrait (`393 × 852`)** dan **Landscape (`852 × 393`)** dengan trackpad multi-touch full-width bergaya Precision Touchpad:
    - **1-Jari Drag**: Akselerasi balistik kontinu (`DPI 0.8x` - `2.0x`), filter smoothing adaptif, dan packet coalescing `8ms`.
    - **1-Jari Tap / Double-Tap & Hold**: Left Click (`LMB`) dan Drag Lock.
    - **2-Jari Tap & Drag**: Right Click (`RMB`), scroll vertikal/horizontal dengan axis lock, kinetic inertia, dan tap-to-brake tanpa klik tidak sengaja.
    - **3-Jari Gestures**: 3-jari tap = Middle Click (`MID`), swipe atas = Task View (`META+TAB`), swipe bawah = Show Desktop (`META+D`), swipe kanan/kiri = Switch App (`ALT+TAB` / `ALT+SHIFT+TAB`).
    - Tombol fisik `LMB`/`MID`/`RMB`, `VOL −`/`VOL +`, `MIC`, dan quick nav Portrait (`◀ BACK`, `WIN / ⌘`, `FWD ▶`).
  - **PC Keyboard (Win)** & **macOS Keyboard**: Keyboard mekanik 65% US QWERTY dengan overlay `FN`/`fn 🌐` (`F1` - `F12`), sticky/holdable modifiers (`SHIFT`, `CTRL`, `ALT`/`OPT`, `WIN`/`⌘ CMD`, `CAPS`), key-repeat `350ms`, shortcut OS, serta switch cepat `Win / macOS` dan `TRACKPAD`.
  - **Hybrid WASD + Pad**: Cluster gaming kiri (`Q`/`W`/`E`/`R`, `A`/`S`/`D`/`F`, `SHIFT (SPRINT)`, `CTRL (CROUCH)`, `SPACE (JUMP)`) simultan dengan aim trackpad + `LMB`/`RMB` di kanan.
- **Quick Menu Drawer (`☰`)**: Slide-over drawer kanan untuk memilih preset controller maupun PC Suite, tema **Dark / Light Mode**, **Haptics**, **Gyro**, slider **Deadzone** (`0%` - `25%`), **HUD Opacity** (`20%` - `100%`), **HUD Edit Mode** (`Smaller` / `Normal` / `Larger` + `Reset`), dan **PC Pairing**.
- **True Multi-Touch & Aman Notch**: Menggunakan raw `Listener` per pointer ID, skala artboard proporsional berbasis `LayoutBuilder`, `SafeArea`, dan `WakelockPlus`.

## Struktur Proyek

```text
flutter-app/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml                             # Permission INTERNET, BLUETOOTH, VIBRATE, WAKE_LOCK
│       └── kotlin/com/example/vcontrollers/MainActivity.kt # Native Android Bluetooth RFCOMM SPP bridge
├── lib/
│   ├── main.dart                                           # Entry point, tema, routing '/' & '/gamepad'
│   ├── models/
│   │   └── gamepad_input.dart                              # Model state tombol & axis + toJson()
│   ├── services/
│   │   └── connection_service.dart                         # Singleton WiFi WebSocket & Bluetooth SPP client
│   ├── theme/
│   │   ├── gamepad_theme.dart                              # Token warna PS/Xbox/Switch/PC Suite (Light/Dark) & prefs
│   │   └── pc_suite_theme.dart                             # Token Midnight Navy/Amber/Silver untuk PC Suite
│   ├── screens/
│   │   ├── connect_screen.dart                             # Pairing WiFi/Bluetooth (portrait) + preset & tema
│   │   ├── gamepad_screen.dart                             # Host screen, Quick Menu Drawer & HUD Edit toolbar
│   │   ├── gamepad_layout_parts.dart                       # Shared ArtboardCanvasShell, status bar & utility buttons
│   │   ├── playstation_gamepad_screen.dart                 # Layout PlayStation DualSense
│   │   ├── xbox_gamepad_screen.dart                        # Layout Xbox Series
│   │   ├── switch_pro_gamepad_screen.dart                  # Layout Nintendo Switch Pro
│   │   ├── pc_trackpad_screen.dart                         # Mode Trackpad & Mouse (Portrait & Landscape)
│   │   ├── pc_keyboard_screen.dart                         # Mode Keyboard 65% US QWERTY (Windows & macOS)
│   │   └── hybrid_wasd_trackpad_screen.dart                # Mode Hybrid Gaming WASD + Aim Trackpad
│   └── widgets/
│       ├── dedicated_stick_click_button.dart               # Tombol pill L3/R3 & LS/RS
│       ├── gamepad_dpad.dart                               # D-Pad 8-arah / diagonal slide
│       ├── gamepad_face_buttons.dart                       # Cluster tombol aksi diamond
│       ├── gamepad_shoulder_button.dart                    # Tombol L1/L2/R1/R2, LB/LT/RB/RT, ZL/L/R/ZR
│       ├── gamepad_thumbstick.dart                         # Analog stick multi-touch dengan radial deadzone
│       ├── gamepad_touchpad.dart                           # Touchpad DualSense dengan indikator sentuhan
│       ├── pc_suite_parts.dart                             # Precision trackpad, key repeat button & status pill
│       └── quick_menu_drawer.dart                          # Slide-over Quick Menu Drawer (Dark & Light mode)
├── test/
│   ├── widget_test.dart                                    # Widget & gesture test semua screen & layout
│   └── tdd_fixes_test.dart                                 # Regression tests untuk BT->WiFi, 3-jari, dan inertia
├── LICENSE
└── pubspec.yaml
```

## Protokol Komunikasi JSON

- **WiFi WebSocket**: `ws://<IP_SERVER>:8765`
- **Bluetooth SPP**: Newline-delimited JSON melalui RFCOMM SPP

### Gamepad Payload

```json
{
  "type": "gamepad",
  "buttons": {
    "A": false,
    "B": false,
    "X": false,
    "Y": false,
    "LB": false,
    "RB": false,
    "START": false,
    "SELECT": false,
    "L3": false,
    "R3": false,
    "DPAD_UP": false,
    "DPAD_DOWN": false,
    "DPAD_LEFT": false,
    "DPAD_RIGHT": false
  },
  "axes": {
    "LX": 0.0,
    "LY": 0.0,
    "RX": 0.0,
    "RY": 0.0,
    "LT": 0.0,
    "RT": 0.0
  }
}
```

> Pemetaan tombol: pada PlayStation, `✕` -> `A`, `○` -> `B`, `□` -> `X`, `△` -> `Y`, `SHARE`/Touchpad -> `SELECT`, `OPT` -> `START`. Pada Switch Pro, `B` -> `A`, `A` -> `B`, `Y` -> `X`, `X` -> `Y`, `−` -> `SELECT`, `+` -> `START`.

### PC Suite Payloads (Trackpad, Mouse & Keyboard)

```json
{"type": "mouse_move", "dx": 4.2, "dy": -1.5}
{"type": "mouse_button", "button": "left", "pressed": true}
{"type": "mouse_scroll", "dx": 0.0, "dy": -6.0}
{"type": "key", "key": "W", "pressed": true, "modifiers": ["SHIFT"]}
{"type": "shortcut", "keys": ["META", "TAB"]}
```

## Prasyarat

- Flutter SDK (Dart `>=3.2.0 <4.0.0`)
- Android SDK & perangkat Android (atau emulator)
- Server penerima dari repository [Virtual-Controller-Server](https://github.com/msuryasyahruli/Virtual-Controller-Server.git) di PC Windows atau Mac
- WiFi lokal yang sama (untuk mode WiFi) atau perangkat sudah di-pair via Bluetooth (untuk mode Bluetooth)

## Cara Menjalankan

1. **Siapkan & jalankan server di PC/Mac**:
   ```sh
   git clone https://github.com/msuryasyahruli/Virtual-Controller-Server.git
   ```
   Ikuti petunjuk instalasi di [Virtual-Controller-Server](https://github.com/msuryasyahruli/Virtual-Controller-Server.git), lalu jalankan server (default port `8765` untuk WiFi, atau aktifkan mode Bluetooth SPP).

2. **Install dependensi & jalankan aplikasi Flutter**:
   ```sh
   flutter pub get
   flutter run
   ```

3. **Hubungkan dari HP**:
   - **WiFi**: Pilih tab **WiFi**, masukkan IP dan port server, lalu tekan **Connect to PC**.
   - **Bluetooth**: Pair PC/Mac di pengaturan Bluetooth Android, pilih tab **Bluetooth**, pilih perangkat, lalu tekan **Connect to PC**.
   - Gunakan tombol `☰` untuk membuka **Quick Menu Drawer** dan berpindah antara preset **PS5 / Xbox / Switch**, **Trackpad**, **Win KB**, **macOS KB**, dan **Hybrid WASD**.

## Pengujian & Build APK

```sh
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

## Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).
