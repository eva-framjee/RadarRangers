import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// ===========================
/// UUIDS (must match Pi GATT server)
/// ===========================
final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");

final Guid heartBpmUuid  = Guid("12345678-1234-1234-1234-1234567890ac");
final Guid breathBpmUuid = Guid("12345678-1234-1234-1234-1234567890ad");

final Guid heartWaveUuid = Guid("12345678-1234-1234-1234-1234567890ae");
final Guid breathWaveUuid= Guid("12345678-1234-1234-1234-1234567890af");
final Guid commandUuid = Guid("12345678-1234-1234-1234-1234567890b1");



class RaspiBleStreamClient {
  BluetoothDevice? _device;

  BluetoothCharacteristic? _heartBpmChar;
  BluetoothCharacteristic? _breathBpmChar;
  BluetoothCharacteristic? _heartWaveChar;
  BluetoothCharacteristic? _breathWaveChar;

  StreamSubscription<List<int>>? _heartBpmSub;
  StreamSubscription<List<int>>? _breathBpmSub;
  StreamSubscription<List<int>>? _heartWaveSub;
  StreamSubscription<List<int>>? _breathWaveSub;

  final _heartBpmCtrl = StreamController<int>.broadcast();
  final _breathBpmCtrl = StreamController<int>.broadcast();
  final _heartSamplesCtrl = StreamController<List<int>>.broadcast();
  final _breathSamplesCtrl = StreamController<List<int>>.broadcast();

  Stream<int> get heartBpmStream => _heartBpmCtrl.stream;
  Stream<int> get breathBpmStream => _breathBpmCtrl.stream;
  Stream<List<int>> get heartSamplesStream => _heartSamplesCtrl.stream;
  Stream<List<int>> get breathSamplesStream => _breathSamplesCtrl.stream;

  bool get isConnected => _device != null;

  final _anyPacketCtrl = StreamController<void>.broadcast();
  Stream<void> get onAnyPacket => _anyPacketCtrl.stream;


  /// Permissions for Android 12+ + scanning
  Future<void> requestBlePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // many phones still require this for scan results
    ].request();
  }

  Future<void> connectAndSubscribe({
    String targetName = "RadarRangers",
    Duration scanTimeout = const Duration(seconds: 12),
  }) async {
    await requestBlePermissions();

    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      throw Exception("Bluetooth is OFF. Turn it on and try again.");
    }

    await disconnect();

    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: scanTimeout);

    StreamSubscription<List<ScanResult>>? scanSub;
    final completer = Completer<void>();

    scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final name = r.device.platformName.trim();

        if (name.isNotEmpty && name.toLowerCase() == targetName.toLowerCase()) {
          _device = r.device;

          await FlutterBluePlus.stopScan();
          await scanSub?.cancel();

          await _device!.connect(
            timeout: const Duration(seconds: 15),
            autoConnect: false,
          );

          await _discoverChars();
          await _subscribeAll();

          completer.complete();
          return;
        }
      }
    });

    try {
      await completer.future.timeout(scanTimeout + const Duration(seconds: 2));
    } on TimeoutException {
      await FlutterBluePlus.stopScan();
      await scanSub?.cancel();
      throw Exception(
        "Could not find BLE device named '$targetName'. "
        "Make sure the Pi is advertising BLE, and Android Location Services is ON.",
      );
    }
  }

  Future<void> _discoverChars() async {
    if (_device == null) throw Exception("No device connected.");

    final services = await _device!.discoverServices();

    final svc = services.firstWhere(
      (s) => s.uuid == serviceUuid,
      orElse: () => throw Exception("Service UUID not found: $serviceUuid"),
    );

    for (final c in svc.characteristics) {
      if (c.uuid == heartBpmUuid) _heartBpmChar = c;
      if (c.uuid == breathBpmUuid) _breathBpmChar = c;
      if (c.uuid == heartWaveUuid) _heartWaveChar = c;
      if (c.uuid == breathWaveUuid) _breathWaveChar = c;
    }

    // You can decide to allow missing BPM chars if you only stream waveforms
    if (_heartWaveChar == null || _breathWaveChar == null) {
      throw Exception("Missing waveform characteristics. Check UUIDs on Pi.");
    }
  }

  Future<void> _subscribeAll() async {
    // HEART BPM (optional)
    if (_heartBpmChar != null) {
      await _heartBpmChar!.setNotifyValue(true);
      await _heartBpmSub?.cancel();
      _heartBpmSub = _heartBpmChar!.onValueReceived.listen((bytes) {
        _heartBpmCtrl.add(_u16(bytes));
      });
    }

    // BREATH BPM (optional)
    if (_breathBpmChar != null) {
      await _breathBpmChar!.setNotifyValue(true);
      await _breathBpmSub?.cancel();
      _breathBpmSub = _breathBpmChar!.onValueReceived.listen((bytes) {
        _breathBpmCtrl.add(_u16(bytes));
      });
    }

    // HEART WAVEFORM (required)
    await _heartWaveChar!.setNotifyValue(true);
    await _heartWaveSub?.cancel();
    _heartWaveSub = _heartWaveChar!.onValueReceived.listen((bytes) {
      _heartSamplesCtrl.add(_i16List(bytes));
    });

    // BREATH WAVEFORM (required)
    await _breathWaveChar!.setNotifyValue(true);
    await _breathWaveSub?.cancel();
    _breathWaveSub = _breathWaveChar!.onValueReceived.listen((bytes) {
      _breathSamplesCtrl.add(_i16List(bytes));
    });
  }

  int _u16(List<int> bytes) {
    if (bytes.length < 2) return 0;
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return bd.getUint16(0, Endian.little);
  }

  List<int> _i16List(List<int> bytes) {
    final u8 = Uint8List.fromList(bytes);
    final bd = ByteData.sublistView(u8);

    final out = <int>[];
    for (int i = 0; i + 1 < u8.length; i += 2) {
      out.add(bd.getInt16(i, Endian.little));
    }
    return out;
  }

  Future<void> disconnect() async {
    try {
      await _heartBpmSub?.cancel();
      await _breathBpmSub?.cancel();
      await _heartWaveSub?.cancel();
      await _breathWaveSub?.cancel();
    } catch (_) {}

    _heartBpmSub = null;
    _breathBpmSub = null;
    _heartWaveSub = null;
    _breathWaveSub = null;

    try {
      await _heartBpmChar?.setNotifyValue(false);
      await _breathBpmChar?.setNotifyValue(false);
      await _heartWaveChar?.setNotifyValue(false);
      await _breathWaveChar?.setNotifyValue(false);
    } catch (_) {}

    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _heartBpmChar = null;
    _breathBpmChar = null;
    _heartWaveChar = null;
    _breathWaveChar = null;
  }

  void dispose() {
    disconnect();
    _heartBpmCtrl.close();
    _breathBpmCtrl.close();
    _heartSamplesCtrl.close();
    _breathSamplesCtrl.close();
  }
}
