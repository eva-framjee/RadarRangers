import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/components/text_field.dart';

import 'package:flutter_application_1/components/sign_in_button.dart';
import 'package:flutter_application_1/components/squaretile.dart';
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
      // Get Firestore instance
      final users = FirebaseFirestore.instance.collection('users');

      // Query Firestore for a matching username + password
      final query = await users
          .where('username', isEqualTo: usernameController.text.trim())
          .where('password', isEqualTo: passwordController.text.trim())
          .get();

      if (query.docs.isNotEmpty) {
        //  Success — navigate to Home Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(username: usernameController.text.trim()),
          ),
        );

      } else {
        //  No match
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Login failed'),
            content: Text('Invalid username or password.'),
          ),
        );
      }
    } catch (e) {
      // Handle any Firestore errors
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
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.lock, size: 100),
                const SizedBox(height: 50),
                Text(
                  'Check your Stats',
                  style: TextStyle(color: const Color.fromARGB(255, 16, 11, 11), fontSize: 16),
                ),
                const SizedBox(height: 25),

                // username
                  TypeTextField(
                    controller: usernameController,
                    hintText: 'Username',
                    obscureText: false,
                    width: 250, // makes box narrower
                    height: 45, // makes box shorter
                  ),

                  const SizedBox(height: 15),

                  // password
                  TypeTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    width: 250,
                    height: 45,
                  ),

                const SizedBox(height: 25),

                // sign in button
                ElevatedButton(
                  onPressed: isLoading ? null : signUserIn,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign In'),
                ),
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
