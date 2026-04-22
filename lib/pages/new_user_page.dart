// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';


// class NewUserPage extends StatefulWidget {
//   const NewUserPage({super.key});

//   @override
//   State<NewUserPage> createState() => _NewUserPageState();
// }

// class _NewUserPageState extends State<NewUserPage> {
//   final firstNameController = TextEditingController();
//   final lastNameController = TextEditingController();
//   final emailController = TextEditingController();
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();

//   bool isLoading = false;

//   Future<void> registerUser() async {
//     if (passwordController.text != confirmPasswordController.text) {
//       showDialog(
//         context: context,
//         builder: (context) => const AlertDialog(
//           title: Text('Error'),
//           content: Text('Passwords do not match.'),
//         ),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       // Save user info to Firestore
//       await FirebaseFirestore.instance.collection('users').add({
//         'first_name': firstNameController.text.trim(),
//         'last_name': lastNameController.text.trim(),
//         'email': emailController.text.trim(),
//         'username': usernameController.text.trim(),
//         'password': passwordController.text.trim(),
//       });

//       // Success dialog
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Success'),
//           content: const Text('Account created successfully!'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context); // return to login page
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Error'),
//           content: Text(e.toString()),
//         ),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('New User Registration'),
//         backgroundColor: const Color.fromARGB(255, 172, 198, 170),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               TextField(
//                 controller: firstNameController,
//                 decoration: const InputDecoration(labelText: 'First Name'),
//               ),
//               const SizedBox(height: 15),
//               TextField(
//                 controller: lastNameController,
//                 decoration: const InputDecoration(labelText: 'Last Name'),
//               ),
//               TextField(
//                 controller: emailController,
//                 decoration: const InputDecoration(labelText: 'Enter Email'),
//               ),
//               const SizedBox(height: 15),
//               TextField(
//                 controller: usernameController,
//                 decoration: const InputDecoration(labelText: 'Create Username'),
//               ),
//               const SizedBox(height: 15),
//               TextField(
//                 controller: passwordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'Create Password'),
//               ),
//               const SizedBox(height: 15),
//               TextField(
//                 controller: confirmPasswordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(labelText: 'Re-enter Password'),
//               ),
//               const SizedBox(height: 25),
//               ElevatedButton(
//                 onPressed: isLoading ? null : registerUser,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color.fromARGB(255, 122, 149, 216),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 40, vertical: 14),
//                 ),
//                 child: isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('Register'),
//               ),
//               const SizedBox(height: 20),
//               OutlinedButton(
//                 onPressed: () {
//                   // placeholder for link device
//                 },
//                 child: const Text('Link Device (Coming Soon)'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewUserPage extends StatefulWidget {
  const NewUserPage({super.key});

  @override
  State<NewUserPage> createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final username = usernameController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Error', 'Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Error', 'Passwords do not match.');
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1) Create the Firebase Auth user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('User was not created.');
      }

      // 2) Save extra profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'username': username,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Account created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // return to login page
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Something went wrong. Please try again.';

      if (e.code == 'email-already-in-use') {
        message = 'That email is already in use.';
      } else if (e.code == 'invalid-email') {
        message = 'That email address is not valid.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }

      _showMessage('Error', message);
    } catch (e) {
      _showMessage('Error', e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New User Registration'),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Enter Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Create Username'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Create Password'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Re-enter Password'),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 122, 149, 216),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register'),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Link Device (Coming Soon)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
