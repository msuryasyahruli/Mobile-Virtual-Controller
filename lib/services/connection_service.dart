import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/gamepad_input.dart';

/// Physical mouse button identifiers sent over the WebSocket protocol.
enum MouseButton { left, middle, right }

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

  static const String _lastIpPrefKey = 'vcontrollers_last_ip';
  static const String _lastPortPrefKey = 'vcontrollers_last_port';

  /// Instance tunggal [ConnectionService] yang digunakan bersama antar screen.
  static final ConnectionService instance = ConnectionService._internal();

  factory ConnectionService() => instance;

  ConnectionService._internal();

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  SharedPreferences? _prefs;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _reconnectTimer;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _currentIp;
  int _currentPort = serverPort;
  String? _lastError;
  bool _shouldReconnect = false;
  int _connectionGeneration = 0;

  /// Stream perubahan status koneksi WebSocket.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Stream pesan error dari server (misalnya penolakan client kedua).
  Stream<String?> get errorStream => _errorController.stream;

  /// Status koneksi saat ini.
  ConnectionStatus get currentStatus => _status;

  /// Alamat IP server yang sedang digunakan atau terakhir dihubungkan.
  String? get currentIp => _currentIp;

  /// Port server yang sedang digunakan atau terakhir dihubungkan.
  int get currentPort => _currentPort;

  /// Pesan error terakhir dari server jika ada.
  String? get lastError => _lastError;

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

  /// Memuat port terakhir yang tersimpan di SharedPreferences.
  Future<int> loadLastPort() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getInt(_lastPortPrefKey) ?? serverPort;
  }

  /// Menyimpan port terakhir ke SharedPreferences.
  Future<void> saveLastPort(int port) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_lastPortPrefKey, port);
  }

  /// Membuka koneksi WebSocket ke `ws://<ip>:<port>` dan mengaktifkan auto-reconnect.
  Future<void> connect(String ip, {int port = serverPort}) async {
    final sanitizedIp = ip.trim();
    if (sanitizedIp.isEmpty) {
      _updateStatus(ConnectionStatus.disconnected);
      return;
    }

    _currentIp = sanitizedIp;
    _currentPort = (port >= 1 && port <= 65535) ? port : serverPort;
    _setError(null);
    _shouldReconnect = true;
    _connectionGeneration++;
    await saveLastIp(sanitizedIp);
    await saveLastPort(_currentPort);

    _cancelReconnectTimer();
    await _closeChannel();
    await _openConnection(sanitizedIp, _currentPort);
  }

  /// Menutup koneksi secara manual dan mematikan auto-reconnect.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _setError(null);
    _connectionGeneration++;
    _cancelReconnectTimer();
    await _closeChannel();
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Mengirim state [GamepadInput] sebagai JSON; mengabaikan error jika terputus.
  void sendInput(GamepadInput input) {
    _sendJson(input.toJson());
  }

  /// Mengirim delta pergerakan mouse relatif dari trackpad.
  void sendMouseMove(double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) return;
    _sendJson({
      'type': 'mouse_move',
      'dx': (dx * 100).round() / 100.0,
      'dy': (dy * 100).round() / 100.0,
    });
  }

  /// Mengirim event tekan/lepas tombol mouse ([MouseButton]).
  void sendMouseButton(MouseButton button, bool pressed) {
    _sendJson({
      'type': 'mouse_button',
      'button': button.name,
      'pressed': pressed,
    });
  }

  /// Mengirim event scroll wheel vertikal/horizontal dari trackpad.
  void sendMouseScroll(double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) return;
    _sendJson({
      'type': 'mouse_scroll',
      'dx': (dx * 100).round() / 100.0,
      'dy': (dy * 100).round() / 100.0,
    });
  }

  /// Mengirim event keyboard tekan/lepas beserta modifier aktif.
  void sendKeyEvent(
    String key,
    bool pressed, {
    Set<String> modifiers = const {},
  }) {
    _sendJson({
      'type': 'key',
      'key': key,
      'pressed': pressed,
      if (modifiers.isNotEmpty) 'modifiers': modifiers.toList(),
    });
  }

  /// Mengirim kombinasi shortcut keyboard sekaligus (mis. `Ctrl+C`, `Cmd+Space`).
  void sendShortcut(List<String> keys) {
    if (keys.isEmpty) return;
    _sendJson({
      'type': 'shortcut',
      'keys': keys,
    });
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (_status != ConnectionStatus.connected || _channel == null) {
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (_) {
      // Abaikan error pengiriman saat koneksi sedang terputus atau tertutup.
    }
  }

  /// Melakukan proses koneksi WebSocket dengan penanganan error yang aman.
  Future<void> _openConnection(String ip, int port) async {
    final generation = ++_connectionGeneration;
    _updateStatus(ConnectionStatus.reconnecting);

    WebSocketChannel? pendingChannel;
    try {
      final uri = Uri.parse('ws://$ip:$port');
      pendingChannel = WebSocketChannel.connect(uri);
      await pendingChannel.ready.timeout(connectTimeout);

      // Pastikan permintaan koneksi ini belum digantikan atau dibatalkan.
      if (generation != _connectionGeneration || !_shouldReconnect) {
        await _safeCloseSpecificChannel(pendingChannel);
        return;
      }

      _channel = pendingChannel;
      _channelSubscription = _channel!.stream.listen(
        (message) => _handleServerMessage(message, generation),
        onDone: () => _handleStreamDone(generation),
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

  /// Memproses pesan JSON dari server VControllers (mis. penolakan client kedua).
  void _handleServerMessage(dynamic message, int generation) {
    if (generation != _connectionGeneration) return;
    if (message is! String) return;

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic> && decoded['type'] == 'error') {
        final serverMsg =
            decoded['message']?.toString().trim() ?? 'Connection rejected by server';
        _rejectConnection(generation, serverMsg);
      }
    } catch (_) {
      // Abaikan pesan non-JSON dari server.
    }
  }

  /// Menangani penutupan stream dari server; hentikan auto-reconnect jika kode 1008.
  void _handleStreamDone(int generation) {
    if (generation != _connectionGeneration) return;
    if (_channel?.closeCode == 1008) {
      final reason = _channel?.closeReason?.trim();
      _rejectConnection(
        generation,
        (reason != null && reason.isNotEmpty)
            ? reason
            : (_lastError ?? 'Another client is already connected'),
      );
      return;
    }
    _handleUnexpectedDisconnect(generation);
  }

  /// Menghentikan auto-reconnect dan menyimpan pesan error penolakan server.
  void _rejectConnection(int generation, String message) {
    if (generation != _connectionGeneration) return;
    _shouldReconnect = false;
    _cancelReconnectTimer();
    _setError(message);
    unawaited(_closeChannel());
    _updateStatus(ConnectionStatus.disconnected);
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
      _openConnection(_currentIp!, _currentPort);
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

  /// Memperbarui pesan error terakhir dan menyiarkannya ke listener.
  void _setError(String? message) {
    if (_lastError == message) return;
    _lastError = message;
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }

  /// Membersihkan seluruh resource ketika service tidak lagi digunakan.
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _errorController.close();
  }
}
