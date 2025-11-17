// import 'package:flutter/material.dart';
// import 'weekly_data_page.dart';
// import 'monthly_data_page.dart';

// class StatHistoryPage extends StatelessWidget {
//   const StatHistoryPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Stat History'),
//         backgroundColor: const Color.fromARGB(255, 172, 198, 170),
//       ),
//       body: Center( // <-- This centers the content vertically & horizontally
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center, // vertical center
//             crossAxisAlignment: CrossAxisAlignment.center, // horizontal center
//             children: [
//               const Text(
//                 'Your Stat History',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 40),

//               // Weekly Data Section
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const WeeklyDataPage()),
//                   );
//                 },
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   margin: const EdgeInsets.symmetric(vertical: 10),
//                   decoration: BoxDecoration(
//                     color: const Color.fromARGB(255, 172, 198, 170),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: const Color.fromARGB(255, 16, 93, 90),
//                       width: 2,
//                     ),
//                   ),
//                   child: const Text(
//                     "Data from This Week",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),

//               // Monthly Data Section
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const MonthlyDataPage()),
//                   );
//                 },
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   margin: const EdgeInsets.symmetric(vertical: 10),
//                   decoration: BoxDecoration(
//                     color: const Color.fromARGB(255, 172, 198, 170),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: const Color.fromARGB(255, 16, 93, 90),
//                       width: 2,
//                     ),
//                   ),
//                   child: const Text(
//                     "Data from This Month",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'weekly_data_pageHR.dart';
import 'monthly_data_pageHR.dart';
import 'weekly_data_pageBR.dart';
import 'monthly_data_pageBR.dart';
class StatHistoryPage extends StatelessWidget {
  final String uid;

  const StatHistoryPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stat History'),
        backgroundColor: Color.fromARGB(255, 172, 198, 170),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const Text(
                'Your Stat History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // HEART RATE WEEKLY
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyDataPageHR(uid: uid),
                    ),
                  );
                },
                child: _buildButton("Heart Rate Data from This Week"),
              ),

              // HEART RATE MONTHLY
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MonthlyDataPageHR(uid: uid),
                    ),
                  );
                },
                child: _buildButton("Heart Rate Data from This Month"),
              ),
// BREATH RATE MONTHLY
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MonthlyDataPageBR(uid: uid),
                    ),
                  );
                },
                child: _buildButton("Respiratory Rate Data from This Month"),
              ),
              // BREATH RATE WEEKLY
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyDataPageBR(uid: uid),
                    ),
                  );
                },
                child: _buildButton("Respiratory Rate Data from This Week"),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 172, 198, 170),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color.fromARGB(255, 16, 93, 90),
          width: 2,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}
