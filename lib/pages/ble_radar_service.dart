import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleRadarService {
  // Change this to match your Pi BLE advertised name
  final String targetName;

  BleRadarService({required this.targetName});

  // UUIDs
  static final Guid serviceUuid =
      Guid("12345678-1234-1234-1234-1234567890ab");
  static final Guid heartBpmUuid =
      Guid("12345678-1234-1234-1234-1234567890ac");
  static final Guid breathBpmUuid =
      Guid("12345678-1234-1234-1234-1234567890ad");
  static final Guid heartWaveUuid =
      Guid("12345678-1234-1234-1234-1234567890ae");
  static final Guid breathWaveUuid =
      Guid("12345678-1234-1234-1234-1234567890af");
  static final Guid commandUuid = 
      Guid("12345678-1234-1234-1234-1234567890b1");


  BluetoothDevice? _device;

  BluetoothCharacteristic? _heartBpmChar;
  BluetoothCharacteristic? _breathBpmChar;
  BluetoothCharacteristic? _heartWaveChar;
  BluetoothCharacteristic? _breathWaveChar;
  BluetoothCharacteristic? _commandChar;


  final _heartBpmCtrl = StreamController<int>.broadcast();
  final _breathBpmCtrl = StreamController<int>.broadcast();
  final _heartSamplesCtrl = StreamController<List<int>>.broadcast();
  final _breathSamplesCtrl = StreamController<List<int>>.broadcast();

  Stream<int> get heartBpmStream => _heartBpmCtrl.stream;
  Stream<int> get breathBpmStream => _breathBpmCtrl.stream;
  Stream<List<int>> get heartSamplesStream => _heartSamplesCtrl.stream;
  Stream<List<int>> get breathSamplesStream => _breathSamplesCtrl.stream;

  bool get isConnected => _device != null;

  Future<void> connect() async {
    // Ensure Bluetooth is on
    if (!await FlutterBluePlus.isOn) {
      throw Exception("Bluetooth is OFF. Turn it on.");
    }

    // Stop any previous scan
    await FlutterBluePlus.stopScan();

    // Scan
    BluetoothDevice? found;
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName;
        if (name == targetName) {
          found = r.device;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withServices: [serviceUuid], // helps narrow results
    );

    await FlutterBluePlus.stopScan();
    await sub.cancel();

    if (found == null) {
      throw Exception("Could not find BLE device named '$targetName'");
    }

    _device = found;

    // Connect
    await _device!.connect(timeout: const Duration(seconds: 12));

    // Discover services
    final services = await _device!.discoverServices();

    final svc = services.firstWhere(
      (s) => s.uuid == serviceUuid,
      orElse: () => throw Exception("Custom radar BLE service not found"),
    );

    for (final c in svc.characteristics) {
      if (c.uuid == heartBpmUuid) _heartBpmChar = c;
      if (c.uuid == breathBpmUuid) _breathBpmChar = c;
      if (c.uuid == heartWaveUuid) _heartWaveChar = c;
      if (c.uuid == breathWaveUuid) _breathWaveChar = c;
    }

    if (_heartBpmChar == null ||
        _breathBpmChar == null ||
        _heartWaveChar == null ||
        _breathWaveChar == null) {
      throw Exception("Missing one or more required BLE characteristics");
    }

    // Enable notifications and listen
    await _heartBpmChar!.setNotifyValue(true);
    _heartBpmChar!.onValueReceived.listen((bytes) {
      final bpm = _u16(bytes);
      _heartBpmCtrl.add(bpm);
    });

    await _breathBpmChar!.setNotifyValue(true);
    _breathBpmChar!.onValueReceived.listen((bytes) {
      final brpm = _u16(bytes);
      _breathBpmCtrl.add(brpm);
    });

    await _heartWaveChar!.setNotifyValue(true);
    _heartWaveChar!.onValueReceived.listen((bytes) {
      final samples = _i16List(bytes);
      _heartSamplesCtrl.add(samples);
    });

    await _breathWaveChar!.setNotifyValue(true);
    _breathWaveChar!.onValueReceived.listen((bytes) {
      final samples = _i16List(bytes);
      _breathSamplesCtrl.add(samples);
    });
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
  }

  void dispose() {
    disconnect();
    _heartBpmCtrl.close();
    _breathBpmCtrl.close();
    _heartSamplesCtrl.close();
    _breathSamplesCtrl.close();
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
}
