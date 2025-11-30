import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalHistoryPage extends StatefulWidget {
  final String username; // passed from login

  const PersonalHistoryPage({super.key, required this.username});

  @override
  State<PersonalHistoryPage> createState() => _PersonalHistoryPageState();
}

class _PersonalHistoryPageState extends State<PersonalHistoryPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController medicalController = TextEditingController();

  String? selectedGender;
  String? normalHeartRate;   // <-- NEW dropdown
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data();
      setState(() {
        firstNameController.text = data['first_name'] ?? '';
        lastNameController.text = data['last_name'] ?? '';
        ageController.text = data['age'] ?? '';
        weightController.text = data['weight'] ?? '';
        heightController.text = data['height'] ?? '';
        medicalController.text = data['medical_history'] ?? '';
        selectedGender = data['gender'];
        normalHeartRate = data['normal_heart_rate'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveInfo() async {
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    if (normalHeartRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your normal heart rate.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .get()
        .then((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'age': ageController.text,
          'weight': weightController.text,
          'height': heightController.text,
          'medical_history': medicalController.text,
          'gender': selectedGender,
          'normal_heart_rate': normalHeartRate, // <-- NEW FIELD
        });
      }
    });

    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text("Saved Successfully"),
        content: Text("Your personal info has been updated."),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    medicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal History'),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your personal details:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User Age (years)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User Weight (lbs)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User Height (inches)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() => selectedGender = value);
                },
              ),
              const SizedBox(height: 20),

              //normal heart rate dropdown
              
              DropdownButtonFormField<String>(
                value: normalHeartRate,
                decoration: const InputDecoration(
                  labelText: 'Normal Heart Rate',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '60-100', child: Text('60-100')),
                  DropdownMenuItem(value: '80-120', child: Text('80-120')),
                  DropdownMenuItem(value: '40-60', child: Text('40-60')),
                ],
                onChanged: (value) {
                  setState(() {
                    normalHeartRate = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Medical History
              TextField(
                controller: medicalController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Medical History',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: saveInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 172, 198, 170),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Save Info"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
