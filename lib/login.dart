import 'package:proj_08_feliciatan/signup.dart';
import 'package:proj_08_feliciatan/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService(); //The line final _auth = AuthService(); is declaring a final variable named _auth and assigning it an instance of the AuthService class.
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late TapGestureRecognizer _tapRecognizer; //Since _tapRecognizer is not initialized immediately, you declare it as late to avoid compiler errors. This means you promise to initialize _tapRecognizer before using it.

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () { //The cascade operator (..) allows you to call or set properties on the newly created object (TapGestureRecognizer) without referring to it again explicitly.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Signup()),
        );
      };
  }

  @override
  void dispose() {
    //The dispose method is part of the Flutter widget lifecycle. It is called when a widget is removed from the widget tree and is no longer needed. This is where you perform cleanup tasks to free up resources, such as disposing of controllers or listeners.
    emailController.dispose();
    passwordController.dispose();
    _tapRecognizer.dispose();
    super.dispose(); //Calls the dispose method of the superclass (State), ensuring any additional cleanup defined in the parent class is executed.
  }

  @override
  Widget build(BuildContext context) {
    // Get the message passed from the Signup screen
    final message = ModalRoute.of(context)?.settings.arguments as String?; //Purpose: Retrieves a message passed as an argument when navigating to this screen.

    // Display the success message (if any) as a SnackBar
    if (message != null) {
      // Show SnackBar when there's a success message
      WidgetsBinding.instance.addPostFrameCallback((_) { //Schedules a callback to run after the current frame is complete.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Login",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightBlue),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                ),
                labelText: 'Email',
                floatingLabelStyle: TextStyle(color: Colors.lightBlue),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                ),
                labelText: 'Password',
                floatingLabelStyle: TextStyle(color: Colors.lightBlue),
              ),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: 'Sign up',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: _tapRecognizer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to the WelcomePage after a successful login
  void goToWelcomePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
    );
  }

  // Perform login operation
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim(); //The trim() method is used to remove any leading or trailing whitespace from a string

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email.")),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your password.")),
      );
      return;
    }

    final user = await _auth.loginUserWithEmailAndPassword(email, password); //This line of code calls an asynchronous method to log in a user with their email and password.

    if (user != null) {
      print("User Logged In");
      goToWelcomePage(context);
    } else {
      // Show an error message if login fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Please check your credentials.")),
      );
    }
  }
}
