import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to create a new user with email and password
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user; // Return the created user if successful
    } catch (e) {
      print("Error creating user: $e"); // Print any errors that occur
      return null; // Return null if there's an error
    }
  }

  // Method to log in an existing user with email and password
  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user; // Return the logged-in user if successful
    } catch (e) {
      print("Error logging in user: $e"); // Print any errors that occur
      return null; // Return null if there's an error
    }
  }

  // Method to sign out the user
  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Call signOut on FirebaseAuth
    } catch (e) {
      print("Error signing out: $e"); // Print the error message
    }
  }
}
