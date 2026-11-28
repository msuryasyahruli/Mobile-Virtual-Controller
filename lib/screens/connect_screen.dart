import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/connection_service.dart';
import '../theme/gamepad_theme.dart';

/// Portrait screen for pairing with a VControllers server over WiFi or Bluetooth.
///
/// Allows entering a server IP and port or choosing a paired Bluetooth device,
/// selecting a [GamepadStyle], and toggling light or dark mode before navigating
/// to `/gamepad`.
class ConnectScreen extends StatefulWidget {
  /// Creates a [ConnectScreen].
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final ConnectionService _connectionService = ConnectionService.instance;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: ConnectionService.serverPort.toString(),
  );
  final FocusNode _ipFocusNode = FocusNode();
  final FocusNode _portFocusNode = FocusNode();

  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<String?>? _errorSubscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  GamepadStyle _style = GamepadStyle.playstation;
  GamepadButtonSize _buttonSize = GamepadButtonSize.normal;
  bool _isDark = true;

  ConnectionTransport _transport = ConnectionTransport.wifi;
  List<BluetoothDeviceInfo> _btDevices = const [];
  String? _selectedBtAddress;
  bool _btLoading = false;
  bool _btPermissionGranted = true;
  bool _btEnabled = true;

  String? _ipError;
  String? _portError;
  String? _serverError;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _enterConnectMode();
    _status = _connectionService.currentStatus;
    _serverError = _connectionService.lastError;
    _loadInitialData();
    _listenConnectionStatus();
  }

  /// Mengatur orientasi default portrait dan menampilkan system bar normal.
  Future<void> _enterConnectMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Memuat IP/port/Bluetooth terakhir serta preferensi tampilan bersama.
  Future<void> _loadInitialData() async {
    final lastIp = await _connectionService.loadLastIp();
    final lastPort = await _connectionService.loadLastPort();
    final lastBtAddr = await _connectionService.loadLastBtAddress();
    final appearance = await GamepadAppearancePrefs.load();
    if (!mounted) return;
    setState(() {
      if (lastIp.isNotEmpty) {
        _ipController.text = lastIp;
      }
      _portController.text = lastPort.toString();
      if (lastBtAddr.isNotEmpty) {
        _selectedBtAddress = lastBtAddr;
      }
      _style = appearance.style;
      _isDark = appearance.isDark;
      _buttonSize = appearance.buttonSize;
    });
  }

  /// Memuat daftar perangkat Bluetooth yang sudah di-pair di Android.
  Future<void> _refreshBluetoothDevices({bool askPermission = false}) async {
    setState(() => _btLoading = true);
    var hasPerm = await _connectionService.hasBluetoothPermission();
    if (!hasPerm && askPermission) {
      hasPerm = await _connectionService.requestBluetoothPermission();
    }
    final enabled = await _connectionService.isBluetoothEnabled();
    final devices = (hasPerm && enabled)
        ? await _connectionService.getPairedBluetoothDevices()
        : const <BluetoothDeviceInfo>[];

    if (!mounted) return;
    setState(() {
      _btLoading = false;
      _btPermissionGranted = hasPerm;
      _btEnabled = enabled;
      _btDevices = devices;
      if (devices.isNotEmpty &&
          (_selectedBtAddress == null ||
              !devices.any((d) => d.address == _selectedBtAddress))) {
        _selectedBtAddress = devices.first.address;
      }
    });
  }

  /// Memantau perubahan status koneksi & error server, lalu navigasi otomatis saat terhubung.
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

    _errorSubscription = _connectionService.errorStream.listen((error) {
      if (!mounted) return;
      setState(() {
        _serverError = error;
      });
    });

    if (_status == ConnectionStatus.connected && !_hasNavigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        Navigator.of(context).pushReplacementNamed('/gamepad');
      });
    }
  }

  /// Mengganti preset controller yang dipakai bersama dengan GamepadScreen.
  void _selectStyle(GamepadStyle nextStyle) {
    if (_style == nextStyle) return;
    HapticFeedback.lightImpact();
    setState(() {
      _style = nextStyle;
    });
    GamepadAppearancePrefs.save(
      style: _style,
      isDark: _isDark,
      buttonSize: _buttonSize,
    );
  }

  /// Mengganti Light Mode / Dark Mode yang tersinkronisasi dengan GamepadScreen.
  void _toggleBrightness() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDark = !_isDark;
    });
    GamepadAppearancePrefs.save(
      style: _style,
      isDark: _isDark,
      buttonSize: _buttonSize,
    );
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

  /// Memulai koneksi ke server WebSocket atau Bluetooth SPP sesuai tab aktif.
  Future<void> _handleConnect() async {
    if (_transport == ConnectionTransport.bluetooth) {
      final addr = _selectedBtAddress?.trim() ?? '';
      if (addr.isEmpty) {
        setState(() {
          _serverError = 'Select a paired PC or Mac first';
        });
        return;
      }
      FocusScope.of(context).unfocus();
      setState(() {
        _ipError = null;
        _portError = null;
        _serverError = null;
      });
      final matched = _btDevices
          .where((d) => d.address == addr)
          .map((d) => d.name)
          .firstOrNull;
      await _connectionService.connectBluetooth(addr, deviceName: matched);
      return;
    }

    final ip = _ipController.text.trim();
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);

    final String? ipErr = _isValidIpv4(ip)
        ? null
        : 'Enter a valid IPv4 address (e.g. 192.168.1.10)';
    final String? portErr =
        (port != null && port >= 1 && port <= 65535) ? null : 'Port 1-65535';

    if (ipErr != null || portErr != null) {
      setState(() {
        _ipError = ipErr;
        _portError = portErr;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _ipError = null;
      _portError = null;
      _serverError = null;
    });

    await _connectionService.connect(ip, port: port!);
  }

  /// Membatalkan proses koneksi/reconnect yang sedang berlangsung.
  Future<void> _handleCancel() async {
    await _connectionService.disconnect();
  }

  /// Returns connection status title, detail, and indicator color.
  ({Color color, String title, String detail}) _statusInfo(GamepadTheme theme) {
    final isBt = _transport == ConnectionTransport.bluetooth;
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ??
        ConnectionService.serverPort;
    final target = isBt
        ? (_btDevices
                .where((d) => d.address == _selectedBtAddress)
                .map((d) => d.name)
                .firstOrNull ??
            'Bluetooth device')
        : '$ip:$port';

    switch (_status) {
      case ConnectionStatus.connected:
        return (
          color: theme.statusAccent,
          title: 'Connected',
          detail: 'Opening controller for $target',
        );
      case ConnectionStatus.reconnecting:
        return (
          color: const Color(0xFFD97706),
          title: 'Connecting to $target',
          detail: isBt
              ? 'Waiting for VControllers server over Bluetooth'
              : 'Waiting for VControllers server on your local WiFi',
        );
      case ConnectionStatus.disconnected:
        if (_serverError != null && _serverError!.isNotEmpty) {
          return (
            color: theme.disconnectColor,
            title: 'Connection failed',
            detail: '$_serverError.',
          );
        }
        return (
          color: theme.textSecondary,
          title: 'Ready to connect',
          detail: isBt
              ? 'Start VControllers on your PC or Mac, then pick it below.'
              : 'Start VControllers on your PC or Mac, then enter its IP.',
        );
    }
  }

  /// Membangun input IPv4 dengan label jelas dan state fokus konsisten.
  Widget _buildIpField(GamepadTheme theme) {
    return TextField(
      controller: _ipController,
      focusNode: _ipFocusNode,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: TextStyle(
        color: theme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        theme: theme,
        label: 'Server IP',
        hint: '192.168.1.100',
        errorText: _ipError,
      ),
      onSubmitted: (_) => _portFocusNode.requestFocus(),
    );
  }

  /// Membangun input port numerik (default 8765).
  Widget _buildPortField(GamepadTheme theme) {
    return TextField(
      controller: _portController,
      focusNode: _portFocusNode,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      style: TextStyle(
        color: theme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        theme: theme,
        label: 'Port',
        hint: '8765',
        errorText: _portError,
      ),
      onSubmitted: (_) => _handleConnect(),
    );
  }

  /// Dekorasi TextField seragam memakai token [GamepadTheme] dan [GamepadRadii.lg].
  InputDecoration _inputDecoration({
    required GamepadTheme theme,
    required String label,
    required String hint,
    String? errorText,
  }) {
    final borderRadius = BorderRadius.circular(GamepadRadii.lg);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      labelStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
      hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
      errorStyle: TextStyle(color: theme.disconnectColor, fontSize: 12),
      filled: true,
      fillColor: theme.buttonFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: theme.buttonBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: theme.buttonBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: theme.statusAccent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: theme.disconnectColor, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: theme.disconnectColor, width: 1.8),
      ),
    );
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    _ipController.dispose();
    _portController.dispose();
    _ipFocusNode.dispose();
    _portFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GamepadTheme.resolve(_style, _isDark);
    final statusInfo = _statusInfo(theme);
    final isConnecting = _status == ConnectionStatus.reconnecting;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.chassisBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactWidth = constraints.maxWidth < 360;
              final isShortHeight = constraints.maxHeight < 620;
              final isTight = isCompactWidth || isShortHeight;
              final horizontalPadding = isCompactWidth ? 12.0 : 24.0;
              final verticalPadding = isTight ? 8.0 : 20.0;
              final cardPadding = isTight ? 12.0 : 22.0;
              final sectionGap = isTight ? 8.0 : 16.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bar atas: identitas aplikasi + tombol tema >= 44x44dp.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VControllers',
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: isTight ? 21 : 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PC & Mac controller over WiFi or Bluetooth',
                                    style: TextStyle(
                                      color: theme.textSecondary,
                                      fontSize: isTight ? 12 : 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Semantics(
                              button: true,
                              label: _isDark
                                  ? 'Switch to light mode'
                                  : 'Switch to dark mode',
                              child: Tooltip(
                                message: _isDark ? 'Light Mode' : 'Dark Mode',
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: _toggleBrightness,
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: theme.buttonFill,
                                      foregroundColor: theme.textPrimary,
                                      side: BorderSide(
                                        color: theme.buttonBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          GamepadRadii.lg,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      _isDark
                                          ? Icons.light_mode_rounded
                                          : Icons.dark_mode_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sectionGap),

                        // Main connection panel.
                        Container(
                          padding: EdgeInsets.all(cardPadding),
                          decoration: BoxDecoration(
                            color: theme.plateFill,
                            borderRadius: BorderRadius.circular(GamepadRadii.xl),
                            border: Border.all(
                              color: theme.plateBorder,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Current connection status.
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: isTight ? 8 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.buttonFill,
                                  borderRadius:
                                      BorderRadius.circular(GamepadRadii.lg),
                                  border: Border.all(
                                    color: _serverError != null
                                        ? theme.disconnectColor
                                        : theme.buttonBorder,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: statusInfo.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            statusInfo.title,
                                            style: TextStyle(
                                              color: theme.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            statusInfo.detail,
                                            style: TextStyle(
                                              color: theme.textSecondary,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: sectionGap),

                              // Transport switcher: WiFi (WebSocket) / Bluetooth (SPP).
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTransportChip(
                                      theme: theme,
                                      label: 'WiFi',
                                      icon: Icons.wifi_rounded,
                                      selected:
                                          _transport == ConnectionTransport.wifi,
                                      onTap: () {
                                        if (_transport ==
                                            ConnectionTransport.wifi) return;
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _transport = ConnectionTransport.wifi;
                                          _serverError = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTransportChip(
                                      theme: theme,
                                      label: 'Bluetooth',
                                      icon: Icons.bluetooth_rounded,
                                      selected: _transport ==
                                          ConnectionTransport.bluetooth,
                                      onTap: () {
                                        if (_transport ==
                                            ConnectionTransport.bluetooth) {
                                          return;
                                        }
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _transport =
                                              ConnectionTransport.bluetooth;
                                          _serverError = null;
                                        });
                                        _refreshBluetoothDevices(
                                          askPermission: true,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: sectionGap),

                              if (_transport == ConnectionTransport.bluetooth)
                                _buildBluetoothSection(theme)
                              else if (isCompactWidth) ...[
                                _buildIpField(theme),
                                const SizedBox(height: 10),
                                _buildPortField(theme),
                              ] else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: _buildIpField(theme),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: _buildPortField(theme),
                                    ),
                                  ],
                                ),
                              SizedBox(height: sectionGap),

                              // Pilihan preset controller sebelum bermain (tiap tombol >= 44dp).
                              Text(
                                'Controller layout',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: GamepadStyle.values
                                    .where((s) => s.isConsole)
                                    .map((preset) {
                                  final selected = preset == _style;
                                  final isLast = preset ==
                                      GamepadStyle.values
                                          .where((s) => s.isConsole)
                                          .last;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: isLast ? 0 : 8,
                                      ),
                                      child: SizedBox(
                                        height: 44,
                                        child: OutlinedButton(
                                          onPressed: () => _selectStyle(preset),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            backgroundColor: selected
                                                ? theme.statusAccent
                                                    .withValues(alpha: 0.14)
                                                : theme.buttonFill,
                                            foregroundColor: selected
                                                ? theme.statusAccent
                                                : theme.textPrimary,
                                            side: BorderSide(
                                              color: selected
                                                  ? theme.statusAccent
                                                  : theme.buttonBorder,
                                              width: selected ? 1.5 : 1.0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                GamepadRadii.lg,
                                              ),
                                            ),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              preset.displayName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: GamepadStyle.values
                                      .where((s) => s.isPcSuite)
                                      .map((preset) {
                                    final selected = preset == _style;
                                    final isLast = preset ==
                                        GamepadStyle.values
                                            .where((s) => s.isPcSuite)
                                            .last;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: isLast ? 0 : 6,
                                      ),
                                      child: SizedBox(
                                        height: 38,
                                        child: OutlinedButton(
                                          onPressed: () => _selectStyle(preset),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            backgroundColor: selected
                                                ? theme.statusAccent
                                                    .withValues(alpha: 0.14)
                                                : theme.buttonFill,
                                            foregroundColor: selected
                                                ? theme.statusAccent
                                                : theme.textPrimary,
                                            side: BorderSide(
                                              color: selected
                                                  ? theme.statusAccent
                                                  : theme.buttonBorder,
                                              width: selected ? 1.5 : 1.0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                GamepadRadii.lg,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            preset.displayName,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              SizedBox(height: isTight ? 10 : 18),

                              // Primary connect action.
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: FilledButton.icon(
                                        onPressed: _handleConnect,
                                        icon: isConnecting
                                            ? SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: theme.onStatusAccent,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.link_rounded,
                                                size: 18,
                                              ),
                                        label: Text(
                                          isConnecting
                                              ? 'Connecting...'
                                              : 'Connect to PC',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: theme.statusAccent,
                                          foregroundColor: theme.onStatusAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              GamepadRadii.lg,
                                            ),
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
                                          foregroundColor:
                                              theme.disconnectColor,
                                          side: BorderSide(
                                            color: theme.disconnectColor,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              GamepadRadii.lg,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransportChip({
    required GamepadTheme theme,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? theme.statusAccent.withValues(alpha: 0.14)
              : theme.buttonFill,
          foregroundColor: selected ? theme.statusAccent : theme.textPrimary,
          side: BorderSide(
            color: selected ? theme.statusAccent : theme.buttonBorder,
            width: selected ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GamepadRadii.lg),
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothSection(GamepadTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paired device',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _btLoading
                  ? null
                  : () => _refreshBluetoothDevices(askPermission: true),
              icon: _btLoading
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.statusAccent,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                _btPermissionGranted ? 'Refresh' : 'Grant Permission',
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ],
        ),
        if (!_btPermissionGranted)
          Text(
            'Allow Bluetooth access to list paired devices.',
            style: TextStyle(color: theme.disconnectColor, fontSize: 12),
          )
        else if (!_btEnabled)
          Text(
            'Turn on Bluetooth on your phone, then tap Refresh.',
            style: TextStyle(color: theme.disconnectColor, fontSize: 12),
          )
        else if (_btDevices.isEmpty)
          Text(
            'No paired devices found. Pair your PC or Mac in Android Bluetooth settings first.',
            style: TextStyle(color: theme.textSecondary, fontSize: 12),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _btDevices.any((d) => d.address == _selectedBtAddress)
                ? _selectedBtAddress
                : _btDevices.first.address,
            dropdownColor: theme.plateFill,
            style: TextStyle(color: theme.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.buttonFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GamepadRadii.lg),
                borderSide: BorderSide(color: theme.buttonBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GamepadRadii.lg),
                borderSide: BorderSide(color: theme.buttonBorder),
              ),
            ),
            items: _btDevices
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d.address,
                    child: Text(
                      '${d.name} (${d.address})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedBtAddress = val;
                _serverError = null;
              });
            },
          ),
      ],
    );
  }
}
