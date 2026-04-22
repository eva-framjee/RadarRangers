// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/components/text_field.dart';
// import 'package:flutter_application_1/pages/new_user_page.dart';
// import 'package:flutter_application_1/pages/home_page.dart';
// import 'package:flutter_application_1/pages/forgot_password_page.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();

//   bool isLoading = false;

//   // NEW: controls whether the password is hidden
//   bool _obscurePassword = true;

//   Future<void> signUserIn() async {
//     setState(() => isLoading = true);

//     try {
//       final users = FirebaseFirestore.instance.collection('users');

//       final inputUsername = usernameController.text.trim();
//       final inputPassword = passwordController.text.trim();

//       print(
//           "Attempting Firestore login: username='$inputUsername', password='$inputPassword'");

//       // Query Firestore for matching username + password
//       final query = await users
//           .where('username', isEqualTo: inputUsername)
//           .where('password', isEqualTo: inputPassword)
//           .get();

//       print("Firestore returned ${query.docs.length} document(s)");

//       if (query.docs.isNotEmpty) {
//         // Found a matching document
//         final userDoc = query.docs.first;
//         final uid = userDoc.id;
//         print("✅ Login successful — UID: $uid");

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => HomePage(
//               uid: uid,
//               username: inputUsername,
//             ),
//           ),
//         );
//       } else {
//         // No matching document found
//         print("Login failed: invalid credentials");
//         showDialog(
//           context: context,
//           builder: (context) => const AlertDialog(
//             title: Text('Login failed'),
//             content: Text('Invalid username or password.'),
//           ),
//         );
//       }
//     } catch (e) {
//       print("Firestore error: $e");
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
//       backgroundColor: const Color.fromARGB(255, 172, 198, 170),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.lock, size: 100),
//                 const SizedBox(height: 50),

//                 const Text(
//                   'Check your Stats',
//                   style: TextStyle(
//                     color: Colors.black87,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 25),

//                 // Username field
//                 TypeTextField(
//                   controller: usernameController,
//                   hintText: 'Username',
//                   obscureText: false,
//                   width: 250,
//                   height: 45,
//                 ),

//                 const SizedBox(height: 15),

//                 // Password field with eye toggle
//                 Stack(
//                   alignment: Alignment.centerRight,
//                   children: [
//                     TypeTextField(
//                       controller: passwordController,
//                       hintText: 'Password',
//                       obscureText: _obscurePassword,
//                       width: 250,
//                       height: 45,
//                     ),
//                     Positioned(
//                       right: 6,
//                       child: IconButton(
//                         icon: Icon(
//                           _obscurePassword
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: Colors.black54,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscurePassword = !_obscurePassword;
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 25),

//                 // Sign-in button
//                 ElevatedButton(
//                   onPressed: isLoading ? null : signUserIn,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal[700],
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 12,
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Sign In',
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),

//                 const SizedBox(height: 15),

//                 // New user link
//                 TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const NewUserPage(),
//                       ),
//                     );
//                   },
//                   child: const Text(
//                     'New User? Create an Account',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       decoration: TextDecoration.underline,
//                     ),
//                   ),
//                 ),

//                 // Forgot Password Button
//                 TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const ForgotPasswordPage(),
//                       ),
//                     );
//                   },
//                   child: const Text(
//                     'Forgot Password?',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       decoration: TextDecoration.underline,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }





// april 17

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/components/text_field.dart';
import 'package:flutter_application_1/pages/new_user_page.dart';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:flutter_application_1/pages/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signUserIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Error', 'Please enter your email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Sign in with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Login failed.');
      }

      // Get extra user info from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String username = '';

      if (userDoc.exists) {
        final data = userDoc.data();
        username = data?['username'] ?? '';
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            uid: user.uid,
            username: username,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';

      if (e.code == 'user-not-found') {
        message = 'No account found for that email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'That email address is not valid.';
      }

      _showMessage('Login failed', message);
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

                TypeTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                  width: 250,
                  height: 45,
                ),

                const SizedBox(height: 15),

                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TypeTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      width: 250,
                      height: 45,
                    ),
                    Positioned(
                      right: 6,
                      child: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                ElevatedButton(
                  onPressed: isLoading ? null : signUserIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
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

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
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