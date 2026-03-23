import 'dart:async';
import 'package:flutter/foundation.dart';
import 'raspi_ble_stream_client.dart';

class BleManager {
  BleManager._internal();
  static final BleManager instance = BleManager._internal();

  final RaspiBleStreamClient client = RaspiBleStreamClient();

  final ValueNotifier<String> status = ValueNotifier<String>("Starting…");
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  // ✅ NEW: prove data is arriving
  final ValueNotifier<DateTime?> lastRx = ValueNotifier<DateTime?>(null);
  final ValueNotifier<int> packetsRx = ValueNotifier<int>(0);

  bool _connecting = false;

  StreamSubscription? _anyPacketSub;

  Future<void> autoConnect({
    String deviceName = "RadarRangers",
  }) async {
    if (_connecting || connected.value) return;

    _connecting = true;
    status.value = "Connecting to $deviceName…";

    try {
      await client.connectAndSubscribe(targetName: deviceName);

      connected.value = true;
      status.value = "Connected ✅ ($deviceName)";

      // reset counters on successful connect
      lastRx.value = null;
      packetsRx.value = 0;

      // ✅ Listen for incoming notify packets
      await _anyPacketSub?.cancel();
      _anyPacketSub = client.onAnyPacket.listen((_) {
        lastRx.value = DateTime.now();
        packetsRx.value = packetsRx.value + 1;
      });
    } catch (e) {
      connected.value = false;
      status.value = "Not connected ❌ ($e)";
      await _anyPacketSub?.cancel();
      _anyPacketSub = null;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    await _anyPacketSub?.cancel();
    _anyPacketSub = null;

    await client.disconnect();
    connected.value = false;
    status.value = "Disconnected";
    lastRx.value = null;
    packetsRx.value = 0;
  }
}
