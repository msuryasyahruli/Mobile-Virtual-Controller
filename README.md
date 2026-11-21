# WiFi Gamepad (Flutter Android Client)

Aplikasi controller gamepad wireless untuk Android berbasis Flutter yang terhubung ke PC Windows melalui WebSocket di jaringan WiFi lokal (`ws://<ip>:8765`) dan diteruskan ke virtual Xbox 360 controller menggunakan server Python + ViGEmBus.

## Fitur Utama

- **2 Preset Layout Controller**:
  - **PlayStation (DualSense)**: Stick simetris, D-Pad recessed, tombol shapes (`△`, `○`, `✕`, `□`), Touchpad interaktif dengan lightbar, `SHARE`, `OPT`, `L1`/`L2`, `R1`/`R2`, serta tombol khusus `L3`/`R3`.
  - **Xbox Series**: Stick asimetris, Hybrid D-Pad dish, tombol `Y`/`B`/`A`/`X`, `View`, `Menu`, `Share`, `LB`/`LT`, `RB`/`RT`, serta tombol khusus `LS`/`RS`.
- **Light Mode & Dark Mode**: Switch tema terang/gelap langsung dari top bar (tersimpan otomatis di `SharedPreferences`).
- **Ukuran Tombol (`S` / `M` / `L`)**: Pilihan ukuran tombol **Smaller**, **Normal**, dan **Larger** agar nyaman di berbagai ukuran tangan dan layar HP.
- **True Multi-Touch**: Menggunakan `Listener` per pointer ID sehingga trigger, bumper, kedua analog stick, D-Pad, dan tombol aksi dapat ditekan bersamaan tanpa konflik.
- **Responsif & Aman Notch**: Skala proporsional berbasis `LayoutBuilder` (artboard referensi `852 × 393`) dengan padding horizontal simetris terhadap notch/status bar.
- **Orientasi Otomatis**: Portrait di `ConnectScreen`, otomatis lock Landscape + `WakelockPlus` (layar tetap menyala) saat masuk `GamepadScreen`.
- **Auto-Reconnect & Hemat Bandwidth**: Otomatis mencoba terhubung ulang setiap 3 detik saat koneksi terputus, dan hanya mengirim payload JSON ketika state input berubah.

## Struktur Proyek

```text
flutter-app/
├── android/
│   └── app/src/main/AndroidManifest.xml   # Permission INTERNET, VIBRATE, WAKE_LOCK & cleartext LAN
├── lib/
│   ├── main.dart                          # Entry point, tema gelap, routing '/' & '/gamepad'
│   ├── models/
│   │   └── gamepad_input.dart             # Model state tombol & axis + toJson()
│   ├── services/
│   │   └── connection_service.dart        # WebSocket client, auto-reconnect, SharedPreferences IP
│   ├── theme/
│   │   └── gamepad_theme.dart             # Token warna PlayStation & Xbox (Light/Dark) + GamepadButtonSize
│   ├── screens/
│   │   ├── connect_screen.dart            # Input IP PC Windows (portrait) & status koneksi
│   │   └── gamepad_screen.dart            # Layout controller landscape multi-touch
│   └── widgets/
│       ├── dedicated_stick_click_button.dart  # Tombol pill L3/R3 & LS/RS
│       ├── gamepad_dpad.dart                  # D-Pad 8-arah / diagonal slide
│       ├── gamepad_face_buttons.dart          # Cluster tombol aksi diamond
│       ├── gamepad_shoulder_button.dart       # Tombol L1/L2/R1/R2 & LB/LT/RB/RT
│       ├── gamepad_thumbstick.dart            # Analog stick multi-touch dengan spring-back
│       └── gamepad_touchpad.dart              # Touchpad DualSense dengan indikator sentuhan
├── test/
│   └── widget_test.dart                   # Widget test ConnectScreen & GamepadScreen
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

> Catatan: Pada layout PlayStation, `✕` dipetakan ke `A`, `○` ke `B`, `□` ke `X`, `△` ke `Y`, `SHARE`/Touchpad ke `SELECT`, dan `OPT` ke `START`.

## Prasyarat

- Flutter SDK (Dart `>=3.2.0 <4.0.0`)
- Android SDK & perangkat Android (atau emulator)
- Server WebSocket penerima di PC Windows pada port `8765` (dari repository terpisah, atau server kustom apa pun yang mengikuti format protokol JSON di atas)
- HP Android dan PC Windows terhubung di jaringan WiFi yang sama

## Cara Menjalankan

1. **Siapkan & jalankan server WebSocket di PC Windows**
   - Jalankan aplikasi server WebSocket WiFi Gamepad (repository terpisah) pada port `8765`, atau gunakan server WebSocket kustom yang membaca payload JSON di atas.
   - Pastikan Windows Firewall mengizinkan koneksi masuk TCP port `8765` dan catat alamat IP lokal PC Windows.

2. **Install dependensi & jalankan aplikasi Flutter**:
   ```bash
   flutter pub get
   flutter run
   ```

3. **Hubungkan di HP**:
   - Masukkan IP lokal PC Windows pada layar `ConnectScreen`, lalu tekan **Connect**.
   - Setelah terhubung, aplikasi otomatis masuk ke `GamepadScreen` (landscape).
   - Gunakan top bar untuk mengganti preset **PS5 / XBOX**, ukuran tombol **S / M / L**, tema **Light / Dark**, atau **Disconnect**.

## Pengujian & Build APK

```bash
flutter analyze
flutter test
flutter build apk --debug
```
