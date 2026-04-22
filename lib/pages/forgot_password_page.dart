// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ForgotPasswordPage extends StatefulWidget {
//   const ForgotPasswordPage({super.key});

//   @override
//   State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
// }

// class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
//   final emailController = TextEditingController();

//   Future<void> resetPassword() async {
//     try {
//       await FirebaseAuth.instance
//           .sendPasswordResetEmail(email: emailController.text.trim());

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Reset link sent! Check your inbox.")),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (c) => AlertDialog(
//           title: const Text("Error"),
//           content: Text(e.toString()),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Reset Password"),
//         backgroundColor: const Color.fromARGB(255, 172, 198, 170),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text("Enter your email to reset your password"),
//             const SizedBox(height: 20),

//             TextField(
//               controller: emailController,
//               decoration: const InputDecoration(
//                 labelText: "Email",
//                 border: OutlineInputBorder(),
//               ),
//             ),

//             const SizedBox(height: 20),

//             ElevatedButton(
//               onPressed: resetPassword,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(255, 173, 248, 239),
//               ),
//               child: const Text("Send Reset Link"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reset link sent! Check your inbox."),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Could not send reset email.";

      if (e.code == 'invalid-email') {
        message = "That email address is not valid.";
      } else if (e.code == 'user-not-found') {
        message = "If an account exists for that email, a reset link was sent.";
      }

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Error"),
          content: Text(message),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Error"),
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: const Color.fromARGB(255, 172, 198, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter your email to reset your password"),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 248, 239),
              ),
              child: const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}
