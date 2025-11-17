import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/components/text_field.dart';
import 'package:flutter_application_1/pages/new_user_page.dart';
import 'package:flutter_application_1/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> signUserIn() async {
    setState(() => isLoading = true);

    try {
      final users = FirebaseFirestore.instance.collection('users');

      final inputUsername = usernameController.text.trim();
      final inputPassword = passwordController.text.trim();

      print("🟡 Attempting Firestore login: username='$inputUsername', password='$inputPassword'");

      // Query Firestore for matching username + password
      final query = await users
          .where('username', isEqualTo: inputUsername)
          .where('password', isEqualTo: inputPassword)
          .get();

      print("🟢 Firestore returned ${query.docs.length} document(s)");

      if (query.docs.isNotEmpty) {
        // Found a matching document
        final userDoc = query.docs.first;
        final uid = userDoc.id;
        print("✅ Login successful — UID: $uid");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              uid: uid,
              username: inputUsername,
            ),
          ),
        );
      } else {
        // No matching document found
        print("❌ Login failed: invalid credentials");
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Login failed'),
            content: Text('Invalid username or password.'),
          ),
        );
      }
    } catch (e) {
      print("🔥 Firestore error: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 100),
                const SizedBox(height: 50),

                const Text(
                  'Check your Stats',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                // Username field
                TypeTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                  width: 250,
                  height: 45,
                ),

                const SizedBox(height: 15),

                // Password field
                TypeTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  width: 250,
                  height: 45,
                ),

                const SizedBox(height: 25),

                // Sign-in button
                ElevatedButton(
                  onPressed: isLoading ? null : signUserIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 15),

                // New user link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewUserPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'New User? Create an Account',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
