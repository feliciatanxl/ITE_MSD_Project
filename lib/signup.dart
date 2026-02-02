import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:proj_08_feliciatan/auth_services.dart';
import 'package:proj_08_feliciatan/login.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // For utf8.encode
import 'package:crypto/crypto.dart'; // For sha256 hashing

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  final _auth = AuthService(); //The line final _auth = AuthService(); is declaring a final variable named _auth and assigning it an instance of the AuthService class.
  late TapGestureRecognizer _loginTapRecognizer; //Since _tapRecognizer is not initialized immediately, you declare it as late to avoid compiler errors. This means you promise to initialize _tapRecognizer before using it.

  @override
  void initState() {
    super.initState();
    _loginTapRecognizer = TapGestureRecognizer()
      ..onTap = () { //The cascade operator (..) allows you to call or set properties on the newly created object (TapGestureRecognizer) without referring to it again explicitly.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      };
  }

  @override
  void dispose() {
    //The dispose method is part of the Flutter widget lifecycle. It is called when a widget is removed from the widget tree and is no longer needed. This is where you perform cleanup tasks to free up resources, such as disposing of controllers or listeners.
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    _loginTapRecognizer.dispose();
    super.dispose(); //Calls the dispose method of the superclass (State), ensuring any additional cleanup defined in the parent class is executed.
  }

  // Function to hash the password using sha256
  //This code defines a function hashPassword to securely hash a password using the SHA-256 cryptographic hash algorithm.
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString(); //Converts the resulting hash (of type Digest) into a hexadecimal string representation.
  }

  // Signup function
  Future<void> _signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final hashedPassword = hashPassword(password); // Hashing the password
    final username = usernameController.text.trim();
    final age = ageController.text.trim(); //The trim() method is used to remove any leading or trailing whitespace from a string
    final height = heightController.text.trim();
    final weight = weightController.text.trim();

    // Regex to validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    //This line defines a regular expression (regex) in Dart to validate email addresses.
    //^: Ensures the match starts at the beginning of the string.
    //[^@]+: Matches one or more characters that are not the @ symbol. This ensures there’s some text before the @.
    //@: Matches the @ symbol.
    //[^@]+: Matches one or more characters after the @ symbol that are not @.
    //\.: Matches a literal dot (.). The backslash is needed to escape the dot, as . in regex usually means "any character."
    //[^@]+: Matches one or more characters after the dot that are not @.
    //$: Ensures the match ends at the end of the string.

    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        age.isEmpty ||
        height.isEmpty ||
        weight.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    if (!emailRegex.hasMatch(email)) { //The expression !emailRegex.hasMatch(email) is a boolean condition that checks whether the given email does not match the pattern defined in the emailRegex regular expression.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address.")),
      );
      return;
    }

    if (password.length < 6) { //password must contain more than 6 characters
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters long.")),
      );
      return;
    }

    try {
      // Create the user with email and password
      final User? user = await _auth.createUserWithEmailAndPassword(email, password);
      //This method is used to create a new user in Firebase Authentication with the provided email and password. It returns a UserCredential object, which contains information about the newly created user.
      //final User? user: The ? indicates that the user can be null, meaning that if the user creation fails (e.g., invalid email or password), the result will be null. This makes the user object nullable.

      if (user != null) {
        //if (user != null): This condition checks if the user was successfully created. If user is null, it means the user creation failed, so the code inside the if block won't execute.
        final uid = user.uid; // Retrieve the UID of the authenticated user
        //final uid = user.uid;: If the user creation is successful, it retrieves the uid (unique identifier) of the newly created user. The uid is a string assigned by Firebase to uniquely identify the user in Firebase Authentication.
        final databaseRef = FirebaseDatabase.instance.ref();
        //FirebaseDatabase.instance.ref(): This initializes a reference to the Firebase Realtime Database. ref() creates a reference to the root of the database, from which you can perform read and write operations

        // Storing data under ProfileGather/{uid}
        await databaseRef.child('ProfileGather/$uid').set({
          'Username': username,
          'Email': email,
          'Password': hashedPassword, // Store the hashed password
          'Age': int.parse(age),
          'Height': int.parse(height),
          'Weight': int.parse(weight),
          'uid': uid, // Store the uid in the profile for consistency
        });

        // After successfully storing data, navigate back to the LoginPage
        Navigator.pop(context, "User account created successfully!");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create user.")),
        );
      }
    } catch (e) {
      // Catch Firebase errors and print them
      print("Error during signup: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-up failed, please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centers the items vertically
              crossAxisAlignment: CrossAxisAlignment.center, // Centers the items horizontally
              children: [
                const Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                    ),
                    labelText: 'Username',
                    floatingLabelStyle: TextStyle(color: Colors.lightBlue),
                  ),
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
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                    ),
                    labelText: 'Age',
                    floatingLabelStyle: TextStyle(color: Colors.lightBlue),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                    ),
                    labelText: 'Height',
                    floatingLabelStyle: TextStyle(color: Colors.lightBlue),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                    ),
                    labelText: 'Weight',
                    floatingLabelStyle: TextStyle(color: Colors.lightBlue),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signup,
                  child: const Text('Sign Up',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: _loginTapRecognizer,
                      ),
                    ],
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
