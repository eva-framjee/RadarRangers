import 'package:flutter/material.dart';

class TwoWeeksAgoPage extends StatelessWidget {
  const TwoWeeksAgoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2 Weeks Ago'),
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