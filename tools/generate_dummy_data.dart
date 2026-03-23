// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// Future<void> generateDummyHeartData() async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) {
//     print("No user logged in");
//     return;
//   }

//   String uid = user.uid;
//   final firestore = FirebaseFirestore.instance;

//   final random = Random();

//   print(" Generating dummy data for $uid ...");

//   for (int i = 0; i < 500; i++) {
//     // Random heart rate between 60 and 120
//     int heartRate = 40 + random.nextInt(60);

//     // Random timestamp for  7 days
//     DateTime timestamp = DateTime.now()
//         .subtract(Duration(
//       hours: random.nextInt(24 * 7),
//       minutes: random.nextInt(60),
//     ));

//     await firestore
//         .collection("users")
//         .doc(uid)
//         .collection("heart_data")
//         .add({
//       "heart_rate": heartRate,
//       "timestamp": timestamp,
//     });
//   }

//   print(" DONE — 500 dummy heart_rate documents added!");
// }
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> generateDummyHeartData(String username) async {
  final firestore = FirebaseFirestore.instance;

  // find the user doc from username
  final query = await firestore
      .collection("users")
      .where("username", isEqualTo: username)
      .limit(1)
      .get();

  if (query.docs.isEmpty) {
    print("No user found with username $username");
    return;
  }

  final userDoc = query.docs.first.reference;
  final random = Random();

  print("Generating dummy heart data for $username ...");

  for (int i = 0; i < 500; i++) {
    int heartRate = 40 + random.nextInt(60);

    DateTime timestamp = DateTime.now().subtract(Duration(
      hours: random.nextInt(24 * 7),
      minutes: random.nextInt(60),
    ));

    await userDoc.collection("heart_data").add({
      "timestamp": timestamp,
      "heart_rate": heartRate,
    });
  }

  print("DONE: 500 dummy entries added.");
}
