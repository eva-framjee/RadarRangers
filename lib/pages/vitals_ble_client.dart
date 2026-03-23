// // lib/vitals_ble_client.dart

// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';

// final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
// final Guid vitalsJsonUuid = Guid("12345678-1234-1234-1234-1234567890b0");
// final Guid heartWaveUuid = Guid("12345678-1234-1234-1234-1234567890ae");
// final Guid breathWaveUuid = Guid("12345678-1234-1234-1234-1234567890af");
// final Guid commandUuid = Guid("12345678-1234-1234-1234-1234567890b1");

// class VitalsBleClient {
//   static final VitalsBleClient _instance = VitalsBleClient._internal();
//   factory VitalsBleClient() => _instance;
//   VitalsBleClient._internal();

//   BluetoothDevice? _device;

//   BluetoothCharacteristic? _vitalsJsonChar;
//   BluetoothCharacteristic? _heartWaveChar;
//   BluetoothCharacteristic? _breathWaveChar;
//   BluetoothCharacteristic? _commandChar;

//   StreamSubscription<List<int>>? _vitalsSub;
//   StreamSubscription<List<int>>? _heartWaveSub;
//   StreamSubscription<List<int>>? _breathWaveSub;

//   bool _connected = false;

//   double currentHR = 0;
//   double currentBR = 0;
//   bool presence = false;
//   String currentAIState = "WARMUP";

//   final List<FlSpot> heartWave = [];
//   final List<FlSpot> breathWave = [];

//   double _tHeart = 0;
//   double _tBreath = 0;

//   String _jsonBuffer = "";

//   Future<void> requestPerms() async {
//     await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.locationWhenInUse,
//     ].request();
//   }

//   Future<void> connect(String targetName) async {
//     print("CONNECT() CALLED");

//     if (_connected && _device != null) {
//       print("Already connected");
//       return;
//     }

//     await requestPerms();

//     final adapterState = await FlutterBluePlus.adapterState.first;
//     if (adapterState != BluetoothAdapterState.on) {
//       throw Exception("Bluetooth is OFF");
//     }

//     await disconnect();

//     await FlutterBluePlus.stopScan();
//     await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

//     BluetoothDevice? found;

//     final scanSub = FlutterBluePlus.scanResults.listen((results) {
//       for (final r in results) {
//         final name = r.device.platformName.trim();
//         print("SCAN RESULT: '$name'");

//         // if (name.toLowerCase().contains(targetName.toLowerCase())) {
//         //   found = r.device;
//         // }
//         if (name.trim() == "RadarRangers") {
//           found = r.device;
//         }
//       }
//     });

//     await Future.delayed(const Duration(seconds: 15));
//     await FlutterBluePlus.stopScan();
//     await scanSub.cancel();

//     if (found == null) {
//       throw Exception("Device not found: $targetName");
//     }

//     _device = found;
//     print("FOUND DEVICE: ${_device!.platformName}");

//     await _device!.connect(
//       timeout: const Duration(seconds: 30),
//       autoConnect: false,
//     );
//     print("CONNECT CALL FINISHED");

//     await Future.delayed(const Duration(milliseconds: 500));

//     try {
//       final mtu = await _device!.requestMtu(185);
//       print("MTU NEGOTIATED: $mtu");
//     } catch (e) {
//       print("MTU REQUEST FAILED: $e");
//     }

//     final services = await _device!.discoverServices();
//     print("SERVICES FOUND: ${services.length}");

//     final svc = services.firstWhere((s) => s.uuid == serviceUuid);

//     BluetoothCharacteristic findChar(Guid uuid) {
//       return svc.characteristics.firstWhere((c) => c.uuid == uuid);
//     }

//     _vitalsJsonChar = findChar(vitalsJsonUuid);
//     _heartWaveChar = findChar(heartWaveUuid);
//     _breathWaveChar = findChar(breathWaveUuid);
//     _commandChar = findChar(commandUuid);

//     print("Found vitals char: ${_vitalsJsonChar?.uuid}");
//     print("Found heart char: ${_heartWaveChar?.uuid}");
//     print("Found breath char: ${_breathWaveChar?.uuid}");
//     print("Found command char: ${_commandChar?.uuid}");

//     await _subscribeAll();

//     _connected = true;
//     print("BLE connected successfully");
//   }

//   Future<void> _subscribeAll() async {
//     print("_subscribeAll() CALLED");

//     try {
//       print("About to enable notify on vitals JSON");
//       await _vitalsJsonChar!.setNotifyValue(true);
//       print("Enabled notify on vitals JSON");
//     } catch (e) {
//       print("FAILED notify on vitals JSON: $e");
//     }

//     _vitalsSub = _vitalsJsonChar!.onValueReceived.listen((bytes) {
//       print("LISTENER FIRED");
//       print("BLE BYTES: $bytes");

//       if (bytes.isEmpty) return;

//       final chunk = utf8.decode(
//         Uint8List.fromList(bytes),
//         allowMalformed: true,
//       );
//       print("BLE CHUNK: $chunk");

//       _jsonBuffer += chunk;

//       while (_jsonBuffer.contains("}")) {
//         final end = _jsonBuffer.indexOf("}") + 1;
//         final jsonStr = _jsonBuffer.substring(0, end).trim();
//         _jsonBuffer = _jsonBuffer.substring(end);

//         if (jsonStr.isEmpty) continue;

//         try {
//           print("BLE RAW JSON: $jsonStr");

//           final map = jsonDecode(jsonStr) as Map<String, dynamic>;

//           final hr = (map["hr"] as num?)?.toDouble();
//           final br = (map["br"] as num?)?.toDouble();
//           final p = (map["presence"] as num?)?.toInt();
//           final ai = map["ai_state"] as String?;

//           if (hr != null) currentHR = hr;
//           if (br != null) currentBR = br;
//           if (p != null) presence = (p == 1);
//           if (ai != null) currentAIState = ai;

//           print("UPDATED HR=$currentHR BR=$currentBR AI=$currentAIState");
//         } catch (e) {
//           print("JSON PARSE ERROR: $e");
//           print("BAD JSON: $jsonStr");
//         }
//       }
//     });

//     try {
//       print("About to enable notify on heart wave");
//       await _heartWaveChar!.setNotifyValue(true);
//       print("Enabled notify on heart wave");
//     } catch (e) {
//       print("FAILED notify on heart wave: $e");
//     }

//     _heartWaveSub = _heartWaveChar!.onValueReceived.listen((bytes) {
//       _appendWave(bytes, heartWave, isHeart: true);
//     });

//     try {
//       print("About to enable notify on breath wave");
//       await _breathWaveChar!.setNotifyValue(true);
//       print("Enabled notify on breath wave");
//     } catch (e) {
//       print("FAILED notify on breath wave: $e");
//     }

//     _breathWaveSub = _breathWaveChar!.onValueReceived.listen((bytes) {
//       _appendWave(bytes, breathWave, isHeart: false);
//     });
//   }

//   void _appendWave(
//     List<int> bytes,
//     List<FlSpot> target, {
//     required bool isHeart,
//   }) {
//     if (bytes.length < 2) return;

//     final bd = Uint8List.fromList(bytes).buffer.asByteData();

//     for (int i = 0; i + 1 < bytes.length; i += 2) {
//       final sample = bd.getInt16(i, Endian.little).toDouble();

//       if (isHeart) {
//         _tHeart += 0.1;
//         target.add(FlSpot(_tHeart, sample));

//         while (target.isNotEmpty && (_tHeart - target.first.x) > 60) {
//           target.removeAt(0);
//         }
//       } else {
//         _tBreath += 0.1;
//         target.add(FlSpot(_tBreath, sample));

//         while (target.isNotEmpty && (_tBreath - target.first.x) > 60) {
//           target.removeAt(0);
//         }
//       }
//     }
//   }

//   Future<void> sendCommand(String cmd) async {
//     if (_commandChar == null) {
//       print("Command characteristic is null");
//       return;
//     }

//     final data = utf8.encode(cmd);
//     await _commandChar!.write(data, withoutResponse: false);
//     print("Sent command: $cmd");
//   }

//   Future<void> disconnect() async {
//     await _vitalsSub?.cancel();
//     await _heartWaveSub?.cancel();
//     await _breathWaveSub?.cancel();

//     _vitalsSub = null;
//     _heartWaveSub = null;
//     _breathWaveSub = null;

//     try {
//       await _vitalsJsonChar?.setNotifyValue(false);
//       await _heartWaveChar?.setNotifyValue(false);
//       await _breathWaveChar?.setNotifyValue(false);
//     } catch (_) {}

//     try {
//       await _device?.disconnect();
//     } catch (_) {}

//     _device = null;
//     _connected = false;
//     _jsonBuffer = "";

//     currentHR = 0;
//     currentBR = 0;
//     presence = false;
//     currentAIState = "WARMUP";

//     heartWave.clear();
//     breathWave.clear();
//     _tHeart = 0;
//     _tBreath = 0;

//     print("BLE disconnected");
//   }
// }



//CODE FROM MODNAY NIGHT

// lib/vitals_ble_client.dart

// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';

// final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
// final Guid vitalsJsonUuid = Guid("12345678-1234-1234-1234-1234567890b0");
// final Guid heartWaveUuid = Guid("12345678-1234-1234-1234-1234567890ae");
// final Guid breathWaveUuid = Guid("12345678-1234-1234-1234-1234567890af");
// final Guid commandUuid = Guid("12345678-1234-1234-1234-1234567890b1");

// class VitalsBleClient {
//   static final VitalsBleClient _instance = VitalsBleClient._internal();
//   factory VitalsBleClient() => _instance;
//   VitalsBleClient._internal();

//   BluetoothDevice? _device;

//   BluetoothCharacteristic? _vitalsJsonChar;
//   BluetoothCharacteristic? _heartWaveChar;
//   BluetoothCharacteristic? _breathWaveChar;
//   BluetoothCharacteristic? _commandChar;

//   StreamSubscription<List<int>>? _vitalsSub;
//   StreamSubscription<List<int>>? _heartWaveSub;
//   StreamSubscription<List<int>>? _breathWaveSub;

//   bool _connected = false;

//   double currentHR = 0;
//   double currentBR = 0;
//   bool presence = false;
//   String currentAIState = "WARMUP";

//   final List<FlSpot> heartWave = [];
//   final List<FlSpot> breathWave = [];

//   double _tHeart = 0;
//   double _tBreath = 0;

//   String _jsonBuffer = "";

//   Future<void> requestPerms() async {
//     await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.locationWhenInUse,
//     ].request();
//   }

//   Future<void> connect(String targetName) async {
//     print("CONNECT() CALLED");

//     if (_connected && _device != null) {
//       print("Already connected");
//       return;
//     }

//     await requestPerms();

//     final adapterState = await FlutterBluePlus.adapterState.first;
//     if (adapterState != BluetoothAdapterState.on) {
//       throw Exception("Bluetooth is OFF");
//     }

//     await disconnect();

//     await FlutterBluePlus.stopScan();
//     await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

//     BluetoothDevice? found;

//     final scanSub = FlutterBluePlus.scanResults.listen((results) {
//       for (final r in results) {
//         final name = r.device.platformName.trim();
//         print("SCAN RESULT: '$name'");

//         if (name == targetName) {
//           found = r.device;
//         }
//       }
//     });

//     await Future.delayed(const Duration(seconds: 15));
//     await FlutterBluePlus.stopScan();
//     await scanSub.cancel();

//     if (found == null) {
//       throw Exception("Device not found: $targetName");
//     }

//     _device = found;
//     print("FOUND DEVICE: ${_device!.platformName}");

//     await _device!.connect(
//       timeout: const Duration(seconds: 30),
//       autoConnect: false,
//     );
//     print("CONNECT CALL FINISHED");

//     try {
//       final mtu = await _device!.requestMtu(185);
//       print("MTU NEGOTIATED: $mtu");
//     } catch (e) {
//       print("MTU REQUEST FAILED: $e");
//     }

//     final services = await _device!.discoverServices();
//     print("SERVICES FOUND: ${services.length}");

//     final svc = services.firstWhere((s) => s.uuid == serviceUuid);

//     BluetoothCharacteristic findChar(Guid uuid) =>
//         svc.characteristics.firstWhere((c) => c.uuid == uuid);

//     _vitalsJsonChar = findChar(vitalsJsonUuid);
//     _heartWaveChar = findChar(heartWaveUuid);
//     _breathWaveChar = findChar(breathWaveUuid);
//     _commandChar = findChar(commandUuid);

//     print("Found vitals char: ${_vitalsJsonChar?.uuid}");
//     print("Found heart char: ${_heartWaveChar?.uuid}");
//     print("Found breath char: ${_breathWaveChar?.uuid}");
//     print("Found command char: ${_commandChar?.uuid}");

//     await _subscribeAll();

//     _connected = true;
//     print("BLE connected successfully");
//   }

//   Future<void> _subscribeAll() async {
//     print("_subscribeAll() CALLED");

//     _vitalsSub = _vitalsJsonChar!.lastValueStream.listen((bytes) {
//       print("LISTENER FIRED");
//       print("BLE BYTES: $bytes");
//       print("VITALS BYTES: $bytes");

//       if (bytes.isEmpty) return;

//       try {
//         final chunk = utf8.decode(
//           Uint8List.fromList(bytes),
//           allowMalformed: true,
//         );
//         print("BLE CHUNK: $chunk");

//         _jsonBuffer += chunk;

//         while (_jsonBuffer.contains("}")) {
//           final end = _jsonBuffer.indexOf("}") + 1;
//           final jsonStr = _jsonBuffer.substring(0, end).trim();
//           _jsonBuffer = _jsonBuffer.substring(end);

//           if (jsonStr.isEmpty) continue;

//           print("BLE RAW JSON: $jsonStr");

//           final map = jsonDecode(jsonStr) as Map<String, dynamic>;

//           final hr = (map["hr"] as num?)?.toDouble();
//           final br = (map["br"] as num?)?.toDouble();
//           final p = (map["presence"] as num?)?.toInt();
//           final ai = map["ai_state"] as String?;

//           if (hr != null) currentHR = hr;
//           if (br != null) currentBR = br;
//           if (p != null) presence = (p == 1);
//           if (ai != null) currentAIState = ai;

//           print("UPDATED HR=$currentHR BR=$currentBR AI=$currentAIState");
//         }
//       } catch (e) {
//         print("JSON PARSE ERROR: $e");
//       }
//     });

//     _heartWaveSub = _heartWaveChar!.lastValueStream.listen((bytes) {
//       print("HEART BYTES: $bytes");
//       _appendWave(bytes, heartWave, isHeart: true);
//     });

//     _breathWaveSub = _breathWaveChar!.lastValueStream.listen((bytes) {
//       print("BREATH BYTES: $bytes");

//       _appendWave(bytes, breathWave, isHeart: false);
//     });

//     try {
//       print("About to enable notify on vitals JSON");
//       await _vitalsJsonChar!.setNotifyValue(true);
//       print("Enabled notify on vitals JSON");
//     } catch (e) {
//       print("FAILED notify on vitals JSON: $e");
//     }

//     try {
//       print("About to enable notify on heart wave");
//       await _heartWaveChar!.setNotifyValue(true);
//       print("Enabled notify on heart wave");
//     } catch (e) {
//       print("FAILED notify on heart wave: $e");
//     }

//     try {
//       print("About to enable notify on breath wave");
//       await _breathWaveChar!.setNotifyValue(true);
//       print("Enabled notify on breath wave");
//     } catch (e) {
//       print("FAILED notify on breath wave: $e");
//     }
//   }

//   void _appendWave(
//     List<int> bytes,
//     List<FlSpot> target, {
//     required bool isHeart,
//   }) {
//     if (bytes.length < 2) return;

//     final bd = Uint8List.fromList(bytes).buffer.asByteData();

//     for (int i = 0; i + 1 < bytes.length; i += 2) {
//       final sample = bd.getInt16(i, Endian.little).toDouble();

//       if (isHeart) {
//         _tHeart += 0.1;
//         target.add(FlSpot(_tHeart, sample));

//         while (target.isNotEmpty && (_tHeart - target.first.x) > 60) {
//           target.removeAt(0);
//         }
//       } else {
//         _tBreath += 0.1;
//         target.add(FlSpot(_tBreath, sample));

//         while (target.isNotEmpty && (_tBreath - target.first.x) > 60) {
//           target.removeAt(0);
//         }
//       }
//     }
//   }

//   Future<void> sendCommand(String cmd) async {
//     if (_commandChar == null) {
//       print("Command characteristic is null");
//       return;
//     }

//     final data = utf8.encode(cmd);
//     await _commandChar!.write(data, withoutResponse: false);
//     print("Sent command: $cmd");
//   }

//   Future<void> disconnect() async {
//     await _vitalsSub?.cancel();
//     await _heartWaveSub?.cancel();
//     await _breathWaveSub?.cancel();

//     _vitalsSub = null;
//     _heartWaveSub = null;
//     _breathWaveSub = null;

//     try {
//       await _vitalsJsonChar?.setNotifyValue(false);
//       await _heartWaveChar?.setNotifyValue(false);
//       await _breathWaveChar?.setNotifyValue(false);
//     } catch (_) {}

//     try {
//       await _device?.disconnect();
//     } catch (_) {}

//     _device = null;
//     _connected = false;
//     _jsonBuffer = "";

//     currentHR = 0;
//     currentBR = 0;
//     presence = false;
//     currentAIState = "WARMUP";

//     heartWave.clear();
//     breathWave.clear();
//     _tHeart = 0;
//     _tBreath = 0;

//     print("BLE disconnected");
//   }
// }



//CODE THAT WILL READ AI STATE



// lib/vitals_ble_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';

final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
final Guid vitalsJsonUuid = Guid("12345678-1234-1234-1234-1234567890b0");
final Guid heartWaveUuid = Guid("12345678-1234-1234-1234-1234567890ae");
final Guid breathWaveUuid = Guid("12345678-1234-1234-1234-1234567890af");
final Guid commandUuid = Guid("12345678-1234-1234-1234-1234567890b1");

class VitalsBleClient {
  static final VitalsBleClient _instance = VitalsBleClient._internal();
  factory VitalsBleClient() => _instance;
  VitalsBleClient._internal();

  BluetoothDevice? _device;

  BluetoothCharacteristic? _vitalsJsonChar;
  BluetoothCharacteristic? _heartWaveChar;
  BluetoothCharacteristic? _breathWaveChar;
  BluetoothCharacteristic? _commandChar;

  StreamSubscription<List<int>>? _vitalsSub;
  StreamSubscription<List<int>>? _heartWaveSub;
  StreamSubscription<List<int>>? _breathWaveSub;

  bool _connected = false;

  double currentHR = 0;
  double currentBR = 0;
  bool presence = false;
  String currentAIState = "WARMUP";

  String _lastAlertedAIState = "";

  final List<FlSpot> heartWave = [];
  final List<FlSpot> breathWave = [];

  double _tHeart = 0;
  double _tBreath = 0;

  String _jsonBuffer = "";

  Future<void> requestPerms() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> connect(String targetName) async {
    print("CONNECT() CALLED");

    if (_connected && _device != null) {
      print("Already connected");
      return;
    }

    await requestPerms();

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw Exception("Bluetooth is OFF");
    }

    await disconnect();

    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    BluetoothDevice? found;

    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.trim();
        print("SCAN RESULT: '$name'");

        if (name == targetName) {
          found = r.device;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 15));
    await FlutterBluePlus.stopScan();
    await scanSub.cancel();

    if (found == null) {
      throw Exception("Device not found: $targetName");
    }

    _device = found;
    print("FOUND DEVICE: ${_device!.platformName}");

    await _device!.connect(
      timeout: const Duration(seconds: 30),
      autoConnect: false,
    );
    print("CONNECT CALL FINISHED");

    try {
      final mtu = await _device!.requestMtu(185);
      print("MTU NEGOTIATED: $mtu");
    } catch (e) {
      print("MTU REQUEST FAILED: $e");
    }

    final services = await _device!.discoverServices();
    print("SERVICES FOUND: ${services.length}");

    final svc = services.firstWhere((s) => s.uuid == serviceUuid);

    BluetoothCharacteristic findChar(Guid uuid) =>
        svc.characteristics.firstWhere((c) => c.uuid == uuid);

    _vitalsJsonChar = findChar(vitalsJsonUuid);
    _heartWaveChar = findChar(heartWaveUuid);
    _breathWaveChar = findChar(breathWaveUuid);
    _commandChar = findChar(commandUuid);

    print("Found vitals char: ${_vitalsJsonChar?.uuid}");
    print("Found heart char: ${_heartWaveChar?.uuid}");
    print("Found breath char: ${_breathWaveChar?.uuid}");
    print("Found command char: ${_commandChar?.uuid}");

    await _subscribeAll();

    _connected = true;
    print("BLE connected successfully");
  }

  Future<void> _subscribeAll() async {
    print("_subscribeAll() CALLED");

    _vitalsSub = _vitalsJsonChar!.lastValueStream.listen((bytes) async {
      print("LISTENER FIRED");
      print("BLE BYTES: $bytes");
      print("VITALS BYTES: $bytes");

      if (bytes.isEmpty) return;

      try {
        final chunk = utf8.decode(
          Uint8List.fromList(bytes),
          allowMalformed: true,
        );
        print("BLE CHUNK: $chunk");

        _jsonBuffer += chunk;

        while (_jsonBuffer.contains("}")) {
          final end = _jsonBuffer.indexOf("}") + 1;
          final jsonStr = _jsonBuffer.substring(0, end).trim();
          _jsonBuffer = _jsonBuffer.substring(end);

          if (jsonStr.isEmpty) continue;

          print("BLE RAW JSON: $jsonStr");

          final map = jsonDecode(jsonStr) as Map<String, dynamic>;

          final hr = (map["hr"] as num?)?.toDouble();
          final br = (map["br"] as num?)?.toDouble();
          final p = (map["presence"] as num?)?.toInt();
          final ai = map["ai_state"] as String?;

          if (hr != null) currentHR = hr;
          if (br != null) currentBR = br;
          if (p != null) presence = (p == 1);

          if (ai != null) {
            currentAIState = ai;

            if (currentAIState == "AI_EMERGENCY" &&
                _lastAlertedAIState != "AI_EMERGENCY") {
              _lastAlertedAIState = "AI_EMERGENCY";

              await NotificationService().showEmergencyNotification(
                title: "Emergency Alert",
                body: "AI detected unusual vitals.",
              );
            }

            if (currentAIState != "AI_EMERGENCY") {
              _lastAlertedAIState = currentAIState;
            }
          }

          print("UPDATED HR=$currentHR BR=$currentBR AI=$currentAIState");
        }
      } catch (e) {
        print("JSON PARSE ERROR: $e");
      }
    });

    _heartWaveSub = _heartWaveChar!.lastValueStream.listen((bytes) {
      print("HEART BYTES: $bytes");
      _appendWave(bytes, heartWave, isHeart: true);
    });

    _breathWaveSub = _breathWaveChar!.lastValueStream.listen((bytes) {
      print("BREATH BYTES: $bytes");
      _appendWave(bytes, breathWave, isHeart: false);
    });

    try {
      print("About to enable notify on vitals JSON");
      await _vitalsJsonChar!.setNotifyValue(true);
      print("Enabled notify on vitals JSON");
    } catch (e) {
      print("FAILED notify on vitals JSON: $e");
    }

    try {
      print("About to enable notify on heart wave");
      await _heartWaveChar!.setNotifyValue(true);
      print("Enabled notify on heart wave");
    } catch (e) {
      print("FAILED notify on heart wave: $e");
    }

    try {
      print("About to enable notify on breath wave");
      await _breathWaveChar!.setNotifyValue(true);
      print("Enabled notify on breath wave");
    } catch (e) {
      print("FAILED notify on breath wave: $e");
    }
  }

  void _appendWave(
    List<int> bytes,
    List<FlSpot> target, {
    required bool isHeart,
  }) {
    if (bytes.length < 2) return;

    final bd = Uint8List.fromList(bytes).buffer.asByteData();

    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final sample = bd.getInt16(i, Endian.little).toDouble();

      if (isHeart) {
        _tHeart += 0.1;
        target.add(FlSpot(_tHeart, sample));

        while (target.isNotEmpty && (_tHeart - target.first.x) > 60) {
          target.removeAt(0);
        }
      } else {
        _tBreath += 0.1;
        target.add(FlSpot(_tBreath, sample));

        while (target.isNotEmpty && (_tBreath - target.first.x) > 60) {
          target.removeAt(0);
        }
      }
    }
  }

  Future<void> sendCommand(String cmd) async {
    if (_commandChar == null) {
      print("Command characteristic is null");
      return;
    }

    final data = utf8.encode(cmd);
    await _commandChar!.write(data, withoutResponse: false);
    print("Sent command: $cmd");
  }

  Future<void> disconnect() async {
    await _vitalsSub?.cancel();
    await _heartWaveSub?.cancel();
    await _breathWaveSub?.cancel();

    _vitalsSub = null;
    _heartWaveSub = null;
    _breathWaveSub = null;

    try {
      await _vitalsJsonChar?.setNotifyValue(false);
      await _heartWaveChar?.setNotifyValue(false);
      await _breathWaveChar?.setNotifyValue(false);
    } catch (_) {}

    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _connected = false;
    _jsonBuffer = "";

    currentHR = 0;
    currentBR = 0;
    presence = false;
    currentAIState = "WARMUP";
    _lastAlertedAIState = "";

    heartWave.clear();
    breathWave.clear();
    _tHeart = 0;
    _tBreath = 0;

    print("BLE disconnected");
  }
}