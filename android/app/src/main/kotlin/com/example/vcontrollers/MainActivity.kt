package com.example.vcontrollers

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.example.vcontrollers/bluetooth"
        private const val EVENT_CHANNEL = "com.example.vcontrollers/bluetooth_events"
        private const val REQ_BT_PERMISSIONS = 4102
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor = Executors.newCachedThreadPool()
    private val writeExecutor = Executors.newSingleThreadExecutor()

    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    @Volatile
    private var activeSocket: BluetoothSocket? = null

    @Volatile
    private var activeOutput: OutputStream? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(getBluetoothAdapter() != null)
                    "isEnabled" -> result.success(getBluetoothAdapter()?.isEnabled == true)
                    "hasPermission" -> result.success(hasBluetoothPermission())
                    "requestPermission" -> requestBluetoothPermission(result)
                    "getPairedDevices" -> handleGetPairedDevices(result)
                    "connect" -> {
                        val address = call.argument<String>("address")?.trim().orEmpty()
                        val channel = call.argument<Int>("channel") ?: 4
                        handleConnect(address, channel, result)
                    }
                    "send" -> {
                        val payload = call.argument<String>("payload") ?: ""
                        handleSend(payload, result)
                    }
                    "disconnect" -> {
                        closeSocket()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getBluetoothAdapter(): BluetoothAdapter? {
        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return manager?.adapter
    }

    private fun hasBluetoothPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestBluetoothPermission(result: MethodChannel.Result) {
        if (hasBluetoothPermission()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("BUSY", "Permission request already in progress", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            ),
            REQ_BT_PERMISSIONS
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_BT_PERMISSIONS) {
            val granted = hasBluetoothPermission()
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    @SuppressLint("MissingPermission")
    private fun handleGetPairedDevices(result: MethodChannel.Result) {
        val adapter = getBluetoothAdapter()
        if (adapter == null) {
            result.error("NO_ADAPTER", "Bluetooth is not supported on this device", null)
            return
        }
        if (!hasBluetoothPermission()) {
            result.error("NO_PERMISSION", "Bluetooth permission not granted", null)
            return
        }
        val list = adapter.bondedDevices
            ?.map { device ->
                mapOf(
                    "name" to (device.name ?: "Unknown Device"),
                    "address" to device.address
                )
            }
            ?.sortedBy { it["name"]?.lowercase() }
            ?: emptyList()
        result.success(list)
    }

    @SuppressLint("MissingPermission")
    private fun handleConnect(address: String, fallbackChannel: Int, result: MethodChannel.Result) {
        if (address.isEmpty()) {
            result.error("INVALID_ADDRESS", "Bluetooth MAC address is empty", null)
            return
        }
        val adapter = getBluetoothAdapter()
        if (adapter == null || !adapter.isEnabled) {
            result.error("BT_OFF", "Bluetooth is turned off", null)
            return
        }
        if (!hasBluetoothPermission()) {
            result.error("NO_PERMISSION", "Bluetooth permission not granted", null)
            return
        }

        ioExecutor.execute {
            closeSocket()
            try {
                if (adapter.isDiscovering) {
                    adapter.cancelDiscovery()
                }
                val device: BluetoothDevice = adapter.getRemoteDevice(address)
                val socket = connectWithFallback(device, fallbackChannel)
                activeSocket = socket
                activeOutput = socket.outputStream
                startReaderThread(socket)
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                closeSocket()
                mainHandler.post {
                    result.error(
                        "CONNECT_FAILED",
                        e.message ?: "Failed to connect via Bluetooth",
                        null
                    )
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun connectWithFallback(device: BluetoothDevice, channel: Int): BluetoothSocket {
        try {
            val sdpSocket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            sdpSocket.connect()
            return sdpSocket
        } catch (primaryErr: IOException) {
            try {
                val insecureSocket = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
                insecureSocket.connect()
                return insecureSocket
            } catch (_: IOException) {
                try {
                    val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                    val fallbackSocket = method.invoke(device, channel) as BluetoothSocket
                    fallbackSocket.connect()
                    return fallbackSocket
                } catch (_: Exception) {
                    throw primaryErr
                }
            }
        }
    }

    private fun startReaderThread(socket: BluetoothSocket) {
        ioExecutor.execute {
            try {
                val reader = BufferedReader(InputStreamReader(socket.inputStream, Charsets.UTF_8))
                while (activeSocket === socket) {
                    val line = reader.readLine() ?: break
                    val trimmed = line.trim()
                    if (trimmed.isNotEmpty()) {
                        emitEvent(mapOf("type" to "message", "data" to trimmed))
                    }
                }
            } catch (_: Exception) {
            } finally {
                if (activeSocket === socket) {
                    closeSocket()
                    emitEvent(mapOf("type" to "disconnected"))
                }
            }
        }
    }

    private fun handleSend(payload: String, result: MethodChannel.Result) {
        val output = activeOutput
        if (output == null || activeSocket?.isConnected != true) {
            result.success(false)
            return
        }
        writeExecutor.execute {
            try {
                val bytes = (payload + "\n").toByteArray(Charsets.UTF_8)
                output.write(bytes)
                output.flush()
                mainHandler.post { result.success(true) }
            } catch (_: Exception) {
                closeSocket()
                emitEvent(mapOf("type" to "disconnected"))
                mainHandler.post { result.success(false) }
            }
        }
    }

    private fun emitEvent(payload: Map<String, Any>) {
        mainHandler.post {
            eventSink?.success(payload)
        }
    }

    private fun closeSocket() {
        val socket = activeSocket
        activeSocket = null
        activeOutput = null
        if (socket != null) {
            try {
                socket.close()
            } catch (_: Exception) {
            }
        }
    }

    override fun onDestroy() {
        closeSocket()
        ioExecutor.shutdownNow()
        writeExecutor.shutdownNow()
        super.onDestroy()
    }
}
