// import 'package:flutter/material.dart';

// import 'login_page.dart';
// import 'PatternStats_page.dart';
// import 'statHistoryPage.dart';
// import 'personalHistoryPage.dart';
// import 'user_manual_page.dart';
// import 'vitals_ble_client.dart';

// class HomePage extends StatefulWidget {
//   final String username;
//   final String uid;

//   const HomePage({
//     super.key,
//     required this.username,
//     required this.uid,
//   });

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final VitalsBleClient ble = VitalsBleClient();

//   String status = "Starting...";
//   double hr = 0;
//   double br = 0;
//   String aiState = "WARMUP";

//   bool _connecting = false;
//   bool _listening = false;

//   @override
//   void initState() {
//     super.initState();
//     print("HOMEPAGE initState");
//     Future.delayed(const Duration(seconds: 1), _startBle);
//   }

//   Future<void> _startBle() async {
//     print("_startBle() called");

//     if (_connecting) {
//       print("_startBle blocked: already connecting");
//       return;
//     }

//     _connecting = true;

//     try {
//       setState(() {
//         status = "Connecting to RadarRangers...";
//       });

//       print("About to connect...");
//       await ble.connect("RadarRangers");
//       print("BLE connect finished");

//       setState(() {
//         status = "Connected";
//       });

//       print("Sending start command...");
//       await ble.sendCommand("start");
//       print("Start command sent");

//       if (!_listening) {
//         _startListening();
//       }
//     } catch (e) {
//       print("BLE ERROR: $e");
//       setState(() {
//         status = "Connection failed";
//       });
//     } finally {
//       _connecting = false;
//     }
//   }

//   void _startListening() {
//     _listening = true;
//     print("_startListening() called");

//     Future.doWhile(() async {
//       await Future.delayed(const Duration(milliseconds: 500));

//       if (!mounted) return false;

//       setState(() {
//         hr = ble.currentHR;
//         br = ble.currentBR;
//         aiState = ble.currentAIState;
//       });

//       print("HOME UPDATED -> HR=$hr BR=$br AI=$aiState");

//       return true;
//     });
//   }

//   @override
//   void dispose() {
//     ble.disconnect();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final username = widget.username;
//     final uid = widget.uid;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Home Page"),
//         backgroundColor: const Color.fromARGB(255, 172, 198, 170),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Welcome, $username!",
//                 style: const TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 12),

//               Text(
//                 status,
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: status.toLowerCase().contains("failed")
//                       ? Colors.red
//                       : Colors.black,
//                 ),
//               ),

//               const SizedBox(height: 20),

//               ElevatedButton.icon(
//                 onPressed: _connecting ? null : _startBle,
//                 icon: const Icon(Icons.refresh),
//                 label: Text(_connecting ? "Connecting..." : "Retry Connection"),
//               ),

//               const SizedBox(height: 30),

//               Text(
//                 "Heart Rate: ${hr.toStringAsFixed(1)} BPM",
//                 style: const TextStyle(fontSize: 22),
//               ),

//               const SizedBox(height: 10),

//               Text(
//                 "Breath Rate: ${br.toStringAsFixed(1)} BPM",
//                 style: const TextStyle(fontSize: 22),
//               ),

//               const SizedBox(height: 10),

//               Text(
//                 "AI State: $aiState",
//                 style: const TextStyle(fontSize: 20),
//               ),

//               const SizedBox(height: 30),

//               _navButton("Daily Stats", () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => StatsPage(uid: uid)),
//                 );
//               }),

//               _navButton("Stat History", () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => StatHistoryPage(uid: uid),
//                   ),
//                 );
//               }),

//               _navButton("Personal History", () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         PersonalHistoryPage(username: username),
//                   ),
//                 );
//               }),

//               const SizedBox(height: 30),

//               ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const LoginPage(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.logout),
//                 label: const Text("Log Out"),
//               ),

//               const SizedBox(height: 20),

//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const UserManualPage(),
//                     ),
//                   );
//                 },
//                 child: const Text("User Manual"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _navButton(String title, VoidCallback onTap) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: ElevatedButton(
//         onPressed: onTap,
//         child: Text(title),
//       ),
//     );
//   }
// }






// CODE THE NIGHT EVERYTHING WORKED



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'PatternStats_page.dart';
import 'statHistoryPage.dart';
import 'personalHistoryPage.dart';
import 'user_manual_page.dart';

import 'vitals_ble_client.dart'; 


class HomePage extends StatefulWidget {
  final String username;
  final String uid;

  const HomePage({
    super.key,
    required this.username,
    required this.uid,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final VitalsBleClient ble = VitalsBleClient();

  String status = "Starting...";
  double hr = 0;
  double br = 0;

  bool _connecting = false; // 🔥 prevents spam tapping

  @override
  void initState() {
    super.initState();
    _startBle();
  }

  Future<void> _startBle() async {
    if (_connecting) return;

    _connecting = true;

    try {
      setState(() => status = "Connecting to RadarRangers...");

      await ble.connect("RadarRangers");

      setState(() => status = "Connected ✅");

      // 🔥 START RADAR ON PI
      await ble.sendCommand("start");

      print("BLE CONNECTED + START SENT");

      _startListening();
    } catch (e) {
      setState(() => status = "Connection failed ❌");
      print("BLE ERROR: $e");
    }

    _connecting = false;
  }

  void _startListening() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return false;

      setState(() {
        hr = ble.currentHR;
        br = ble.currentBR;
      });

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.username;
    final uid = widget.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Welcome
            Text(
              'Welcome, $username!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// STATUS
            Text(
              status,
              style: TextStyle(
                fontSize: 16,
                color: status.contains("failed")
                    ? Colors.red
                    : Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 RETRY BUTTON (ONLY SHOW WHEN FAILED)
            if (status.contains("failed"))
              ElevatedButton.icon(
                onPressed: _connecting ? null : _startBle,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry Connection"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),

            const SizedBox(height: 20),

            /// LIVE HR
            Text(
              "Heart Rate: ${hr.toStringAsFixed(0)} BPM",
              style: const TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 10),

            /// LIVE BR
            Text(
              "Breath Rate: ${br.toStringAsFixed(0)} BPM",
              style: const TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 30),

            /// NAV BUTTONS
            _navButton("Daily Stats", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatsPage(uid: uid)),
              );
            }),

            _navButton("Stat History", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatHistoryPage(uid: uid)),
              );
            }),

            _navButton("Personal History", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PersonalHistoryPage(username: username),
                ),
              );
            }),

            const SizedBox(height: 30),

            /// LOG OUT
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),

            const SizedBox(height: 20),

            /// USER MANUAL
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManualPage(),
                  ),
                );
              },
              child: const Text("User Manual"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(title),
      ),
    );
  }
}