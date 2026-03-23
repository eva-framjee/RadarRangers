// lib/services/vitals_firestore_logger.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsFirestoreLogger {
  VitalsFirestoreLogger({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Track last write time per user+kind so we don't spam Firestore
  final Map<String, DateTime> _lastWrite = {};

  bool _canWrite(String key, int minIntervalSeconds) {
    final now = DateTime.now();
    final last = _lastWrite[key];
    if (last != null && now.difference(last).inSeconds < minIntervalSeconds) {
      return false;
    }
    _lastWrite[key] = now;
    return true;
  }

  /// Logs heart rate to: users/{uid}/heart_data
  /// fields: timestamp (Timestamp), heart_rate (double)
  Future<void> logHeartRate({
    required String uid,
    required double bpm,
    int minIntervalSeconds = 5,
  }) async {
    if (bpm <= 0) return;

    final key = "$uid:hr";
    if (!_canWrite(key, minIntervalSeconds)) return;

    final now = DateTime.now();
    await _db.collection('users').doc(uid).collection('heart_data').add({
      'timestamp': Timestamp.fromDate(now),
      'heart_rate': bpm,
    });
  }

  /// Logs breath rate to: users/{uid}/breath_data
  /// fields: timestamp (Timestamp), breath_rate (double)
  Future<void> logBreathRate({
    required String uid,
    required double br,
    int minIntervalSeconds = 5,
  }) async {
    if (br <= 0) return;

    final key = "$uid:br";
    if (!_canWrite(key, minIntervalSeconds)) return;

    final now = DateTime.now();
    await _db.collection('users').doc(uid).collection('breath_data').add({
      'timestamp': Timestamp.fromDate(now),
      'breath_rate': br,
    });
  }
}