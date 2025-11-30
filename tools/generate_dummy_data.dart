import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> generateDummyHeartData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("No user logged in");
    return;
  }

  String uid = user.uid;
  final firestore = FirebaseFirestore.instance;

  final random = Random();

  print(" Generating dummy data for $uid ...");

  for (int i = 0; i < 500; i++) {
    // Random heart rate between 60 and 120
    int heartRate = 40 + random.nextInt(60);

    // Random timestamp for  7 days
    DateTime timestamp = DateTime.now()
        .subtract(Duration(
      hours: random.nextInt(24 * 7),
      minutes: random.nextInt(60),
    ));

    await firestore
        .collection("users")
        .doc(uid)
        .collection("heart_data")
        .add({
      "heart_rate": heartRate,
      "timestamp": timestamp,
    });
  }

  print(" DONE — 500 dummy heart_rate documents added!");
}
