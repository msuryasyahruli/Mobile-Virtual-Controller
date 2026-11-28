import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/gamepad_input.dart';

/// Physical mouse buttons sent over the PC input protocol.
enum MouseButton {
  /// The primary (left) mouse button.
  left,

  /// The middle (wheel) mouse button.
  middle,

  /// The secondary (right) mouse button.
  right,
}

/// Transport layers used to reach the VControllers server.
enum ConnectionTransport {
  /// Local network WebSocket connection.
  wifi,

  /// Android Bluetooth RFCOMM SPP connection.
  bluetooth,
}

/// Metadata for a paired Bluetooth device.
class BluetoothDeviceInfo {
  /// The human-readable name of the device.
  final String name;

  /// The Bluetooth MAC address of the device.
  final String address;

  /// Creates a [BluetoothDeviceInfo] with the given [name] and [address].
  const BluetoothDeviceInfo({
    required this.name,
    required this.address,
  });
}

/// Connection states for [ConnectionService].
enum ConnectionStatus {
  /// Actively connected to the server.
  connected,

  /// Not connected to any server.
  disconnected,

  /// Attempting to establish or restore a connection.
  reconnecting,
}

/// Manages WiFi WebSocket and Bluetooth SPP connections to the PC server.
///
/// Use [ConnectionService.instance] or [ConnectionService.new] to access the
/// shared singleton across screens.
class ConnectionService {
  /// The default WebSocket port used by the VControllers server (`8765`).
  static const int serverPort = 8765;

  /// The delay between automatic WiFi reconnect attempts.
  static const Duration reconnectInterval = Duration(seconds: 3);

  /// The maximum time to wait for a WebSocket handshake before timing out.
  static const Duration connectTimeout = Duration(seconds: 5);

  static const String _lastIpPrefKey = 'vcontrollers_last_ip';
  static const String _lastPortPrefKey = 'vcontrollers_last_port';
  static const String _lastBtAddrPrefKey = 'vcontrollers_last_bt_addr';

  static const MethodChannel _btMethodChannel =
      MethodChannel('com.example.vcontrollers/bluetooth');
  static const EventChannel _btEventChannel =
      EventChannel('com.example.vcontrollers/bluetooth_events');

  /// The shared singleton [ConnectionService] instance.
  static final ConnectionService instance = ConnectionService._internal();

  /// Returns the shared [instance].
  factory ConnectionService() => instance;

  ConnectionService._internal();

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  SharedPreferences? _prefs;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  StreamSubscription<dynamic>? _btEventSubscription;
  Timer? _reconnectTimer;

  ConnectionTransport _transport = ConnectionTransport.wifi;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _currentIp;
  int _currentPort = serverPort;
  String? _currentBtAddress;
  String? _currentBtName;
  String? _lastError;
  bool _shouldReconnect = false;
  int _connectionGeneration = 0;

  /// A broadcast stream of [ConnectionStatus] updates.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// A broadcast stream of server rejection or transport error messages.
  Stream<String?> get errorStream => _errorController.stream;

  /// The active [ConnectionTransport].
  ConnectionTransport get currentTransport => _transport;

  /// The current [ConnectionStatus].
  ConnectionStatus get currentStatus => _status;

  /// The IPv4 address of the active or most recently targeted WiFi server.
  String? get currentIp => _currentIp;

  /// The TCP port of the active or most recently targeted WiFi server.
  int get currentPort => _currentPort;

  /// The Bluetooth MAC address of the active or last targeted device.
  String? get currentBluetoothAddress => _currentBtAddress;

  /// The display name of the active Bluetooth device, if known.
  String? get currentBluetoothName => _currentBtName;

  /// The most recent server or transport error message, or `null` if none.
  String? get lastError => _lastError;

  /// Initializes [SharedPreferences] for persisting connection settings.
  ///
  /// Uses [prefs] when provided; otherwise obtains the default instance.
  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  /// Loads the last saved server IP address, or returns an empty string.
  Future<String> loadLastIp() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString(_lastIpPrefKey) ?? '';
  }

  /// Persists the trimmed [ip] address to local preferences.
  Future<void> saveLastIp(String ip) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_lastIpPrefKey, ip.trim());
  }

  /// Loads the last saved server port, defaulting to [serverPort].
  Future<int> loadLastPort() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getInt(_lastPortPrefKey) ?? serverPort;
  }

  /// Persists [port] to local preferences.
  Future<void> saveLastPort(int port) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_lastPortPrefKey, port);
  }

  /// Loads the last saved Bluetooth MAC address, or returns an empty string.
  Future<String> loadLastBtAddress() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString(_lastBtAddrPrefKey) ?? '';
  }

  /// Persists the trimmed Bluetooth [address] to local preferences.
  Future<void> saveLastBtAddress(String address) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_lastBtAddrPrefKey, address.trim());
  }

  /// Returns whether the device has a Bluetooth adapter.
  Future<bool> isBluetoothAvailable() async {
    try {
      return await _btMethodChannel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns whether Bluetooth is currently enabled on the device.
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _btMethodChannel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns whether runtime Bluetooth permission has been granted.
  Future<bool> hasBluetoothPermission() async {
    try {
      return await _btMethodChannel.invokeMethod<bool>('hasPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Requests runtime Bluetooth permission from the user.
  Future<bool> requestBluetoothPermission() async {
    try {
      return await _btMethodChannel.invokeMethod<bool>('requestPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Returns the paired [BluetoothDeviceInfo] entries reported by the OS.
  Future<List<BluetoothDeviceInfo>> getPairedBluetoothDevices() async {
    try {
      final rawList =
          await _btMethodChannel.invokeMethod<List<dynamic>>('getPairedDevices');
      if (rawList == null) return const [];
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => BluetoothDeviceInfo(
              name: (item['name'] ?? 'Unknown Device').toString(),
              address: (item['address'] ?? '').toString(),
            ),
          )
          .where((d) => d.address.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Connects to `ws://[ip]:[port]` and enables automatic reconnection.
  ///
  /// Falls back to [serverPort] if [port] is outside `1`..`65535`.
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
    _transport = ConnectionTransport.wifi;
    await _openConnection(sanitizedIp, _currentPort);
  }

  /// Membuka koneksi Bluetooth SPP ke perangkat PC yang sudah di-pair.
  /// Connects over Bluetooth RFCOMM SPP to the paired device at [address].
  ///
  /// Stores [deviceName] for display while connected.
  Future<void> connectBluetooth(String address, {String? deviceName}) async {
    final sanitizedAddr = address.trim();
    if (sanitizedAddr.isEmpty) {
      _updateStatus(ConnectionStatus.disconnected);
      return;
    }

    _transport = ConnectionTransport.bluetooth;
    _currentBtAddress = sanitizedAddr;
    _currentBtName = deviceName;
    _setError(null);
    _shouldReconnect = false;
    _connectionGeneration++;
    await saveLastBtAddress(sanitizedAddr);

    _cancelReconnectTimer();
    await _closeChannel();
    await _openBluetoothConnection(sanitizedAddr);
  }

  /// Closes the active connection and disables automatic reconnection.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _setError(null);
    _connectionGeneration++;
    _cancelReconnectTimer();
    await _closeChannel();
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Sends the canonical gamepad [input] payload when connected.
  void sendInput(GamepadInput input) {
    _sendJson(input.toJson());
  }

  /// Sends a relative cursor movement delta ([dx], [dy]) from the trackpad.
  void sendMouseMove(double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) return;
    _sendJson({
      'type': 'mouse_move',
      'dx': (dx * 100).round() / 100.0,
      'dy': (dy * 100).round() / 100.0,
    });
  }

  /// Sends a press or release event for [button] based on [pressed].
  void sendMouseButton(MouseButton button, bool pressed) {
    _sendJson({
      'type': 'mouse_button',
      'button': button.name,
      'pressed': pressed,
    });
  }

  /// Sends a scroll wheel delta ([dx], [dy]) from the trackpad.
  void sendMouseScroll(double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) return;
    _sendJson({
      'type': 'mouse_scroll',
      'dx': (dx * 100).round() / 100.0,
      'dy': (dy * 100).round() / 100.0,
    });
  }

  /// Sends a keyboard [key] press or release event with optional [modifiers].
  ///
  /// Sets the `pressed` flag to [pressed] and includes [modifiers] when
  /// non-empty.
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

  /// Sends a simultaneous keyboard shortcut for [keys] (e.g. `['CTRL', 'C']`).
  void sendShortcut(List<String> keys) {
    if (keys.isEmpty) return;
    _sendJson({
      'type': 'shortcut',
      'keys': keys,
    });
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (_status != ConnectionStatus.connected) {
      return;
    }

    try {
      final encoded = jsonEncode(payload);
      if (_transport == ConnectionTransport.bluetooth) {
        unawaited(
          _btMethodChannel.invokeMethod<bool>('send', {'payload': encoded}),
        );
        return;
      }
      if (_channel == null) return;
      _channel!.sink.add(encoded);
    } catch (_) {
      // Abaikan error pengiriman saat koneksi sedang terputus atau tertutup.
    }
  }

  /// Membuka koneksi Bluetooth RFCOMM SPP lewat MethodChannel native Android.
  Future<void> _openBluetoothConnection(String address) async {
    final generation = ++_connectionGeneration;
    _updateStatus(ConnectionStatus.reconnecting);

    try {
      await _btEventSubscription?.cancel();
      _btEventSubscription = _btEventChannel.receiveBroadcastStream().listen(
        (event) => _handleBluetoothEvent(event, generation),
        onError: (_) => _handleUnexpectedDisconnect(generation),
      );

      final ok = await _btMethodChannel.invokeMethod<bool>('connect', {
            'address': address,
            'channel': 5,
          }) ??
          false;

      if (generation != _connectionGeneration) return;
      if (!ok) {
        _setError('Failed to connect via Bluetooth');
        _updateStatus(ConnectionStatus.disconnected);
        return;
      }

      _updateStatus(ConnectionStatus.connected);
    } on PlatformException catch (e) {
      if (generation == _connectionGeneration) {
        _setError(e.message ?? 'Bluetooth connection failed');
        _updateStatus(ConnectionStatus.disconnected);
      }
    } catch (_) {
      if (generation == _connectionGeneration) {
        _setError('Bluetooth connection failed');
        _updateStatus(ConnectionStatus.disconnected);
      }
    }
  }

  void _handleBluetoothEvent(dynamic event, int generation) {
    if (generation != _connectionGeneration) return;
    if (event is! Map) return;
    final type = event['type']?.toString();
    if (type == 'message') {
      _handleServerMessage(event['data'], generation);
    } else if (type == 'disconnected') {
      _updateStatus(ConnectionStatus.disconnected);
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

    try {
      await _btEventSubscription?.cancel();
    } catch (_) {}
    _btEventSubscription = null;

    if (_transport == ConnectionTransport.bluetooth) {
      try {
        await _btMethodChannel.invokeMethod<bool>('disconnect');
      } catch (_) {}
    }

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
