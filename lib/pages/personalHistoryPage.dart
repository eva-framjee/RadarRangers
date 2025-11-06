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
  String? tachychondiaQuestion;
  String? breathingQuestion;
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
        tachychondiaQuestion = data['health'];
        breathingQuestion = data['health'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveInfo() async {
    // Validate gender selection
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }
    if (tachychondiaQuestion == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please state medical conditions.'))
      );
      return;
    }
    if (breathingQuestion == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please state medical conditions.'))
      );
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
          'heart_conditions': tachychondiaQuestion,
          'breath_conditions' : breathingQuestion, 
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

              // 🧍‍♂️ First name
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // 🧍‍♀️ Last name
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Age
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User Age (years)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Weight
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User Weight (lbs)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Height
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User Height (inches)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Gender dropdown
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
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 20),


              const Text(
                'Conditions that may raise heartrate:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('-hyperthyroidism'),
                    Text('-anemia'),
                    Text('-lung disease'),
                    Text('-high blood pressure'),
                    Text('-heart disease'),
                    Text('-heart failure'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              //tachycondria question
              DropdownButtonFormField<String>(
                value: tachychondiaQuestion,
                decoration: const InputDecoration(
                  labelText: 'Heart Conditions',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                  DropdownMenuItem(value: 'No', child: Text('No')),
                ],
                onChanged: (value) {
                  setState(() {
                    tachychondiaQuestion = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Conditions that may raise Breathing Rate:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('-asthma'),
                    Text('-psychological tachypnea'),
                    Text('-anxiety'),
                    Text('-high blood pressure'),
                    Text('-heart disease'),
                    Text('-heart failure')
                  ],
                ),
              ),

              const SizedBox(height: 20),

              //tachycondria question
              DropdownButtonFormField<String>(
                value: breathingQuestion,
                decoration: const InputDecoration(
                  labelText: 'Breathing Conditions',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                  DropdownMenuItem(value: 'No', child: Text('No')),
                ],
                onChanged: (value) {
                  setState(() {
                    breathingQuestion = value;
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
