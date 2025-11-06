import 'package:flutter/material.dart';

class ThreeWeeksAgoPage extends StatelessWidget {
  const ThreeWeeksAgoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3 Weeks Ago'),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: const Center(
        child: Text(
          'Data from 1 day ago will be displayed here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}