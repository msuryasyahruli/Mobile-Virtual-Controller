import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/gamepad_input.dart';

/// Status koneksi WebSocket ke server PC Windows.
enum ConnectionStatus {
  connected,
  disconnected,
  reconnecting,
}

/// Service singleton untuk mengelola koneksi WebSocket dan pengiriman input gamepad.
class ConnectionService {
  /// Port default server WebSocket Python pada PC Windows.
  static const int serverPort = 8765;

  /// Interval auto-reconnect saat koneksi terputus.
  static const Duration reconnectInterval = Duration(seconds: 3);

  /// Timeout handshake WebSocket agar tidak menggantung pada IP yang tidak aktif.
  static const Duration connectTimeout = Duration(seconds: 5);

  static const String _lastIpPrefKey = 'wifi_gamepad_last_ip';

  /// Instance tunggal [ConnectionService] yang digunakan bersama antar screen.
  static final ConnectionService instance = ConnectionService._internal();

  factory ConnectionService() => instance;

  ConnectionService._internal();

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  SharedPreferences? _prefs;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _reconnectTimer;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _currentIp;
  bool _shouldReconnect = false;
  int _connectionGeneration = 0;

  /// Stream perubahan status koneksi WebSocket.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Status koneksi saat ini.
  ConnectionStatus get currentStatus => _status;

  /// Alamat IP server yang sedang digunakan atau terakhir dihubungkan.
  String? get currentIp => _currentIp;

  /// Inisialisasi SharedPreferences untuk menyimpan dan memuat IP terakhir.
  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  /// Memuat alamat IP terakhir yang tersimpan di SharedPreferences.
  Future<String> loadLastIp() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString(_lastIpPrefKey) ?? '';
  }

  /// Menyimpan alamat IP terakhir ke SharedPreferences.
  Future<void> saveLastIp(String ip) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_lastIpPrefKey, ip.trim());
  }

  /// Membuka koneksi WebSocket ke `ws://<ip>:8765` dan mengaktifkan auto-reconnect.
  Future<void> connect(String ip) async {
    final sanitizedIp = ip.trim();
    if (sanitizedIp.isEmpty) {
      _updateStatus(ConnectionStatus.disconnected);
      return;
    }

    _currentIp = sanitizedIp;
    _shouldReconnect = true;
    _connectionGeneration++;
    await saveLastIp(sanitizedIp);

    _cancelReconnectTimer();
    await _closeChannel();
    await _openConnection(sanitizedIp);
  }

  /// Menutup koneksi secara manual dan mematikan auto-reconnect.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _connectionGeneration++;
    _cancelReconnectTimer();
    await _closeChannel();
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Mengirim state [GamepadInput] sebagai JSON; mengabaikan error jika terputus.
  void sendInput(GamepadInput input) {
    if (_status != ConnectionStatus.connected || _channel == null) {
      return;
    }

    try {
      final payload = jsonEncode(input.toJson());
      _channel!.sink.add(payload);
    } catch (_) {
      // Abaikan error pengiriman saat koneksi sedang terputus atau tertutup.
    }
  }

  /// Melakukan proses koneksi WebSocket dengan penanganan error yang aman.
  Future<void> _openConnection(String ip) async {
    final generation = ++_connectionGeneration;
    _updateStatus(ConnectionStatus.reconnecting);

    WebSocketChannel? pendingChannel;
    try {
      final uri = Uri.parse('ws://$ip:$serverPort');
      pendingChannel = WebSocketChannel.connect(uri);
      await pendingChannel.ready.timeout(connectTimeout);

      // Pastikan permintaan koneksi ini belum digantikan atau dibatalkan.
      if (generation != _connectionGeneration || !_shouldReconnect) {
        await _safeCloseSpecificChannel(pendingChannel);
        return;
      }

      _channel = pendingChannel;
      _channelSubscription = _channel!.stream.listen(
        (_) {},
        onDone: () => _handleUnexpectedDisconnect(generation),
        onError: (Object _) => _handleUnexpectedDisconnect(generation),
        cancelOnError: true,
      );

      _updateStatus(ConnectionStatus.connected);
    } catch (_) {
      await _safeCloseSpecificChannel(pendingChannel);
      if (generation == _connectionGeneration) {
        _handleUnexpectedDisconnect(generation);
      }
    }
  }

  /// Menangani kondisi koneksi putus dan menjadwalkan auto-reconnect setiap 3 detik.
  void _handleUnexpectedDisconnect(int generation) {
    if (generation != _connectionGeneration) return;

    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;

    if (!_shouldReconnect || _currentIp == null || _currentIp!.isEmpty) {
      _updateStatus(ConnectionStatus.disconnected);
      return;
    }

    _updateStatus(ConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  /// Menjadwalkan percobaan reconnect berikutnya setelah [reconnectInterval].
  void _scheduleReconnect() {
    _cancelReconnectTimer();
    _reconnectTimer = Timer(reconnectInterval, () {
      if (!_shouldReconnect || _currentIp == null || _currentIp!.isEmpty) {
        return;
      }
      _openConnection(_currentIp!);
    });
  }

  /// Membatalkan timer reconnect yang sedang berjalan.
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Menutup channel dan subscription aktif secara aman.
  Future<void> _closeChannel() async {
    try {
      await _channelSubscription?.cancel();
    } catch (_) {
      // Abaikan error saat menutup subscription.
    }
    _channelSubscription = null;

    await _safeCloseSpecificChannel(_channel);
    _channel = null;
  }

  /// Menutup instance [WebSocketChannel] tertentu tanpa melempar exception.
  Future<void> _safeCloseSpecificChannel(WebSocketChannel? channel) async {
    if (channel == null) return;
    try {
      await channel.sink.close();
    } catch (_) {
      // Abaikan error saat menutup sink WebSocket.
    }
  }

  /// Memperbarui status internal dan mengirim event ke listener jika berubah.
  void _updateStatus(ConnectionStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  /// Membersihkan seluruh resource ketika service tidak lagi digunakan.
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
  }
}
