import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/connection_service.dart';

/// Halaman awal untuk memasukkan alamat IP server PC Windows dan membuka koneksi WebSocket.
class ConnectScreen extends StatefulWidget {
  /// Membuat [ConnectScreen].
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final ConnectionService _connectionService = ConnectionService.instance;
  final TextEditingController _ipController = TextEditingController();

  StreamSubscription<ConnectionStatus>? _statusSubscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorText;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _enterConnectMode();
    _status = _connectionService.currentStatus;
    _loadSavedIp();
    _listenConnectionStatus();
  }

  /// Mengatur orientasi default portrait dan menampilkan system bar normal untuk ConnectScreen.
  Future<void> _enterConnectMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Memuat IP terakhir dari SharedPreferences saat screen diinisialisasi.
  Future<void> _loadSavedIp() async {
    final lastIp = await _connectionService.loadLastIp();
    if (!mounted) return;
    if (lastIp.isNotEmpty) {
      _ipController.text = lastIp;
    }
  }

  /// Memantau perubahan status koneksi dan otomatis pindah ke GamepadScreen saat Connected.
  void _listenConnectionStatus() {
    _statusSubscription = _connectionService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _status = status;
      });

      if (status == ConnectionStatus.connected && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.of(context).pushReplacementNamed('/gamepad');
      }
    });

    if (_status == ConnectionStatus.connected && !_hasNavigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        Navigator.of(context).pushReplacementNamed('/gamepad');
      });
    }
  }

  /// Memvalidasi format IPv4 sederhana sebelum memulai koneksi.
  bool _isValidIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      if (part.isEmpty) return false;
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return false;
    }
    return true;
  }

  /// Memulai koneksi ke server WebSocket dengan IP dari TextField.
  Future<void> _handleConnect() async {
    final ip = _ipController.text.trim();
    if (!_isValidIpv4(ip)) {
      setState(() {
        _errorText = 'Masukkan alamat IPv4 valid (contoh: 192.168.1.10)';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _errorText = null;
    });

    await _connectionService.connect(ip);
  }

  /// Membatalkan proses koneksi/reconnect yang sedang berlangsung.
  Future<void> _handleCancel() async {
    await _connectionService.disconnect();
  }

  /// Mengembalikan metadata ikon, warna, dan teks untuk status koneksi saat ini.
  ({IconData icon, Color color, String label}) _statusMeta() {
    switch (_status) {
      case ConnectionStatus.connected:
        return (
          icon: Icons.wifi_rounded,
          color: const Color(0xFF2ECC71),
          label: 'Connected',
        );
      case ConnectionStatus.reconnecting:
        return (
          icon: Icons.sync_rounded,
          color: const Color(0xFFF39C12),
          label: 'Reconnecting ke ws://${_ipController.text.trim()}:${ConnectionService.serverPort}...',
        );
      case ConnectionStatus.disconnected:
        return (
          icon: Icons.wifi_off_rounded,
          color: const Color(0xFFE74C3C),
          label: 'Disconnected',
        );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusMeta = _statusMeta();
    final isConnecting = _status == ConnectionStatus.reconnecting;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withOpacity(0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header aplikasi.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D9FF).withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: Color(0xFF00D9FF),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WiFi Gamepad',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'WebSocket Client • Port ${ConnectionService.serverPort}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Indikator status koneksi (ikon + teks).
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusMeta.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusMeta.color.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            statusMeta.icon,
                            color: statusMeta.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              statusMeta.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusMeta.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Input IP Address PC Windows.
                    TextField(
                      controller: _ipController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.8,
                      ),
                      decoration: InputDecoration(
                        labelText: 'IP Address PC Windows',
                        hintText: '192.168.1.100',
                        errorText: _errorText,
                        prefixIcon: const Icon(
                          Icons.computer_rounded,
                          color: Color(0xFF00D9FF),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF00D9FF),
                            width: 1.8,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _handleConnect(),
                    ),
                    const SizedBox(height: 18),

                    // Tombol Connect (dan tombol Batal saat sedang reconnecting).
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _handleConnect,
                              icon: isConnecting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    )
                                  : const Icon(Icons.link_rounded),
                              label: Text(
                                isConnecting ? 'Menghubungkan...' : 'Connect',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9FF),
                                foregroundColor: const Color(0xFF0E1324),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isConnecting) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _handleCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE74C3C),
                                side: const BorderSide(
                                  color: Color(0xFFE74C3C),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
