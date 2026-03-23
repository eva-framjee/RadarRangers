import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final serviceUuid = Guid("12345678-1234-5678-1234-56789abcdef0");
final charUuid = Guid("12345678-1234-5678-1234-56789abcdef1");

class RaspiCsvClient {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _char;

  StreamSubscription<List<int>>? _notifySub;
  final _buf = StringBuffer();

  Future<void> requestBlePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  /// Connects to the BLE device named "RadarRangers".
  /// NOTE: We do NOT filter scan by service UUID because many peripherals
  /// don't advertise services in the scan packet.
  Future<void> connectAndDownload({
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
    await FlutterBluePlus.startScan(timeout: scanTimeout); // ✅ no service filter

    StreamSubscription<List<ScanResult>>? scanSub;
    final completer = Completer<void>();

    scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final name = r.device.platformName.trim();

        // Match your specific Pi by name (case-insensitive)
        if (name.isNotEmpty &&
            name.toLowerCase() == targetName.toLowerCase()) {
          _device = r.device;

          await FlutterBluePlus.stopScan();
          await scanSub?.cancel();

          await _device!.connect(
            timeout: const Duration(seconds: 30),
            autoConnect: false,
          );

          await _discoverAndSubscribe();
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

  Future<void> _discoverAndSubscribe() async {
    if (_device == null) throw Exception("No device connected.");

    final services = await _device!.discoverServices();

    final svc = services.firstWhere(
      (s) => s.uuid == serviceUuid,
      orElse: () => throw Exception("Service UUID not found: $serviceUuid"),
    );

    _char = svc.characteristics.firstWhere(
      (c) => c.uuid == charUuid,
      orElse: () => throw Exception("Characteristic UUID not found: $charUuid"),
    );

    _buf.clear();

    await _char!.setNotifyValue(true);

    await _notifySub?.cancel();
    _notifySub = _char!.onValueReceived.listen((value) async {
      final chunk = utf8.decode(value, allowMalformed: true);

      if (chunk == "__EOF__") {
        final csvText = _buf.toString();
        _buf.clear();

        final path = await _saveCsv(csvText);
        print("✅ CSV saved to: $path");
      } else {
        _buf.write(chunk);
      }
    });
  }

  Future<String> _saveCsv(String csvText) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        "raspi_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv";
    final file = File("${dir.path}/$filename");
    await file.writeAsString(csvText, flush: true);
    return file.path;
  }

  Future<void> disconnect() async {
    try {
      await _notifySub?.cancel();
      _notifySub = null;
    } catch (_) {}

    try {
      await _char?.setNotifyValue(false);
    } catch (_) {}

    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _char = null;
    _buf.clear();
  }
}
