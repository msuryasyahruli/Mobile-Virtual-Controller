# VControllers (Flutter Android Client)

Aplikasi controller gamepad wireless untuk Android berbasis Flutter yang terhubung ke PC Windows melalui WebSocket di jaringan WiFi lokal (`ws://<ip>:<port>`, default port `8765`) dan diteruskan ke virtual Xbox 360 controller menggunakan [Virtual Controller Server](https://github.com/msuryasyahruli/Virtual-Controller-Server.git) (Python + ViGEmBus).

## Fitur Utama

- **3 Preset Layout Controller**:
  - **PlayStation (DualSense)**: Stick simetris, D-Pad recessed, tombol shapes (`△`, `○`, `✕`, `□`), Touchpad interaktif dengan lightbar, `SHARE`, `OPT`, `L1`/`L2`, `R1`/`R2`, macro `M1`/`M2`, serta tombol khusus `L3`/`R3`.
  - **Xbox Series**: Stick asimetris, Hybrid D-Pad dish, tombol `Y`/`B`/`A`/`X`, `View`, `Menu`, `Share`, `LB`/`LT`, `RB`/`RT`, macro `M1`/`M2`, serta tombol khusus `LS`/`RS`.
  - **Nintendo Switch Pro**: Stick asimetris dengan aksen Joy-Con (Neon Blue/Red), D-Pad, layout fisik Nintendo (`X` atas, `A` kanan, `B` bawah, `Y` kiri), `−`, `+`, Capture (`●`), `ZL`/`L`, `R`/`ZR`, macro `M1`/`M2`, serta tombol khusus `LS`/`RS`.
- **Trackpad, Mouse & Keyboard Suite (4 Mode)**:
  - **Trackpad & Mouse**: Mendukung **Portrait (`393 × 852`)** & **Landscape (`852 × 393`)**, trackpad multi-touch full-width (1-jari gerak kursor dengan DPI `0.8x`–`2.0x`, 1-jari tap `LMB`, 2-jari tap `RMB`, 2-jari drag untuk scroll vertikal/horizontal, double-tap & tahan untuk drag lock), tombol fisik `LMB`/`MID`/`RMB`, `VOL −`/`VOL +`, `MIC`, serta quick nav Portrait (`◀ BACK`, `WIN / ⌘`, `FWD ▶`).
  - **PC Keyboard (Win)** & **macOS Keyboard**: Keyboard mekanik 65% US QWERTY dengan overlay `FN`/`fn 🌐` (`F1`–`F12`), sticky/holdable modifiers (`SHIFT`, `CTRL`, `ALT`/`OPT`, `WIN`/`⌘ CMD`, `CAPS`), key-repeat `350ms`, shortcut OS (`COPY`, `PASTE`, `UNDO`, `ALT + TAB` / `SPOTLIGHT`, `TASK MGR` / `MISSION CTRL`), serta switch cepat `Win / macOS` dan `TRACKPAD`.
  - **Hybrid WASD + Pad**: Cluster gaming kiri (`Q`/`W`/`E`/`R`, `A`/`S`/`D`/`F`, `SHIFT (SPRINT)`, `CTRL (CROUCH)`, `SPACE (JUMP)`) yang bekerja bersamaan dengan mouse/aim trackpad + `LMB`/`RMB` di kanan.
- **Quick Menu Drawer (`☰`)**: Slide-over drawer kanan untuk mengganti preset controller maupun PC Suite, tema **Dark / Light Mode**, **Haptics**, **Gyro**, slider **Deadzone** (`0%` - `25%`), **HUD Opacity** (`20%` - `100%`), masuk **HUD Edit Mode** (`Smaller` / `Normal` / `Larger` + `Reset`), dan kembali ke **PC Pairing**.
- **True Multi-Touch**: Menggunakan `Listener` per pointer ID sehingga trigger, bumper, kedua analog stick, D-Pad, tombol aksi, maupun WASD + trackpad dapat dipakai bersamaan tanpa konflik.
- **Responsif & Aman Notch**: Skala proporsional berbasis `LayoutBuilder` (artboard referensi `852 × 393` landscape & `393 × 852` portrait Trackpad) dengan `SafeArea` dan padding simetris terhadap notch/status bar.
- **Orientasi Otomatis**: Portrait di `ConnectScreen`, Landscape + `WakelockPlus` di `GamepadScreen` (dengan dukungan rotasi Portrait/Landscape khusus mode `Trackpad & Mouse`).
- **Auto-Reconnect & Hemat Bandwidth**: Otomatis mencoba terhubung ulang setiap 3 detik saat koneksi terputus, dan hanya mengirim payload JSON ketika state input berubah.

## Struktur Proyek

```text
flutter-app/
├── android/
│   └── app/src/main/AndroidManifest.xml        # Permission INTERNET, VIBRATE, WAKE_LOCK & cleartext LAN
├── lib/
│   ├── main.dart                               # Entry point, tema, routing '/' & '/gamepad'
│   ├── models/
│   │   └── gamepad_input.dart                  # Model state tombol & axis + toJson()
│   ├── services/
│   │   └── connection_service.dart             # WebSocket client, mouse/keyboard events, auto-reconnect
│   ├── theme/
│   │   ├── gamepad_theme.dart                  # Token warna PS/Xbox/Switch Pro/PC Suite (Light/Dark) & prefs
│   │   └── pc_suite_theme.dart                 # Token warna Midnight Navy/Amber/Silver untuk PC Suite
│   ├── screens/
│   │   ├── connect_screen.dart                 # Input IP & Port PC Windows (portrait) + preset & tema
│   │   ├── gamepad_screen.dart                 # Host screen, Quick Menu Drawer & HUD Edit toolbar
│   │   ├── gamepad_layout_parts.dart           # Shared ArtboardCanvasShell, top status bar, utility buttons
│   │   ├── playstation_gamepad_screen.dart     # Layout PlayStation DualSense
│   │   ├── xbox_gamepad_screen.dart            # Layout Xbox Series
│   │   ├── switch_pro_gamepad_screen.dart      # Layout Nintendo Switch Pro
│   │   ├── pc_trackpad_screen.dart             # Mode Trackpad & Mouse (Portrait & Landscape)
│   │   ├── pc_keyboard_screen.dart             # Mode Keyboard 65% US QWERTY (Windows & macOS)
│   │   └── hybrid_wasd_trackpad_screen.dart    # Mode Hybrid Gaming WASD + Aim Trackpad
│   └── widgets/
│       ├── dedicated_stick_click_button.dart   # Tombol pill L3/R3 & LS/RS
│       ├── gamepad_dpad.dart                   # D-Pad 8-arah / diagonal slide
│       ├── gamepad_face_buttons.dart           # Cluster tombol aksi diamond
│       ├── gamepad_shoulder_button.dart        # Tombol L1/L2/R1/R2, LB/LT/RB/RT, ZL/L/R/ZR
│       ├── gamepad_thumbstick.dart             # Analog stick multi-touch dengan radial deadzone
│       ├── gamepad_touchpad.dart               # Touchpad DualSense dengan indikator sentuhan
│       ├── pc_suite_parts.dart                 # Key button repeat, multi-touch trackpad & status pill
│       └── quick_menu_drawer.dart              # Slide-over Quick Menu Drawer (Dark & Light mode)
├── test/
│   └── widget_test.dart                        # Widget test ConnectScreen, layouts, QuickMenuDrawer & PC Suite
├── LICENSE
└── pubspec.yaml
```

## Protokol Komunikasi WebSocket

- **URL**: `ws://<IP_PC_WINDOWS>:8765`
- **Format JSON**:

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

> Catatan: Pada layout PlayStation, `✕` dipetakan ke `A`, `○` ke `B`, `□` ke `X`, `△` ke `Y`, `SHARE`/Touchpad ke `SELECT`, dan `OPT` ke `START`. Pada layout Switch Pro, tata letak fisik Nintendo dipetakan sesuai standar (`B` bawah -> `A`, `A` kanan -> `B`, `Y` kiri -> `X`, `X` atas -> `Y`, `−` -> `SELECT`, `+` -> `START`).

- **Format JSON PC Suite (Trackpad, Mouse & Keyboard)**:
  - `{"type": "mouse_move", "dx": 4.2, "dy": -1.5}`
  - `{"type": "mouse_button", "button": "left", "pressed": true}` (`left` | `middle` | `right`)
  - `{"type": "mouse_scroll", "dx": 0.0, "dy": -6.0}`
  - `{"type": "key", "key": "W", "pressed": true, "modifiers": ["SHIFT"]}`
  - `{"type": "shortcut", "keys": ["CTRL", "C"]}`

## Prasyarat

- Flutter SDK (Dart `>=3.2.0 <4.0.0`)
- Android SDK & perangkat Android (atau emulator)
- Server WebSocket penerima di PC Windows pada port `8765` dari repository [Virtual-Controller-Server](https://github.com/msuryasyahruli/Virtual-Controller-Server.git) (atau server kustom apa pun yang mengikuti format protokol JSON di atas)
- HP Android dan PC Windows terhubung di jaringan WiFi yang sama

## Cara Menjalankan

1. **Siapkan & jalankan server WebSocket di PC Windows**
   - Clone dan jalankan server dari repository resmi:
     ```bash
     git clone https://github.com/msuryasyahruli/Virtual-Controller-Server.git
     ```
   - Ikuti petunjuk instalasi di [Virtual-Controller-Server](https://github.com/msuryasyahruli/Virtual-Controller-Server.git) untuk menjalankan server pada port `8765` (atau port kustom).
   - Pastikan Windows Firewall mengizinkan koneksi masuk TCP pada port yang digunakan dan catat alamat IP lokal PC Windows.

2. **Install dependensi & jalankan aplikasi Flutter**:
   ```bash
   flutter pub get
   flutter run
   ```

3. **Hubungkan di HP**:
   - Masukkan IP lokal dan port PC Windows pada layar `ConnectScreen`, lalu tekan **Connect to PC**.
   - Setelah terhubung, aplikasi otomatis masuk ke `GamepadScreen` (landscape).
   - Buka **Quick Menu Drawer** lewat tombol `☰` di top bar untuk mengganti preset **PS5 / Xbox / Switch**, tema **Light / Dark**, **Haptics**, **Gyro**, **Deadzone**, **HUD Opacity**, **Edit HUD Layout**, atau kembali ke **PC Pairing**.

## Pengujian & Build APK

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

## Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).
