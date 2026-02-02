import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_services.dart'; // Assuming AuthService is where sign-out logic is
import 'login.dart'; // Make sure to import your LoginPage widget

class ProfileGather extends StatefulWidget {
  const ProfileGather({Key? key}) : super(key: key);

  @override
  State<ProfileGather> createState() => _ProfileGatherState();
}

class _ProfileGatherState extends State<ProfileGather> {
  final AuthService _auth = AuthService();
  //The line final _auth = AuthService(); is declaring a final variable named _auth and assigning it an instance of the AuthService class.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String errorMessage = ''; // Variable to store error messages
  //declaring and initializing a variable called errorMessage of type String.

  // Method to load user info from Firebase Realtime Database
  Future<void> _loadUserInfo() async {
    //The provided function _loadUserInfo is an asynchronous method that retrieves the user's data from Firebase Realtime Database and populates form fields with that data.
    User? user = FirebaseAuth.instance.currentUser;
    //FirebaseAuth.instance.currentUser: This accesses the currently authenticated user using Firebase Authentication. The user object contains details about the signed-in user. If no user is signed in, currentUser will be null.
    //User? user: The user is nullable, meaning it could either be a User object or null if no user is signed in.
    if (user != null) {
      //This checks whether a user is currently signed in. If user is null, it means no user is authenticated, and the rest of the code is skipped.
      String uid = user.uid;
      //String uid = user.uid: This retrieves the unique identifier (UID) of the currently signed-in user. This UID is used to fetch the user's data from Firebase.
      DatabaseReference userRef = FirebaseDatabase.instance.ref('ProfileGather/$uid');
      //DatabaseReference userRef: This creates a reference to the user's data in Firebase Realtime Database under the path 'ProfileGather/$uid'. It uses the UID to target the correct data for the authenticated user.

      try {
        final snapshot = await userRef.get();
        //snapshot: It holds the data retrieved from Firebase. A DataSnapshot contains the data at the reference location.
        if (snapshot.exists) {
          //This checks if data exists at the specified database location. If data exists, it will proceed to retrieve and display it. If not, it sets an error message.
          var userData = snapshot.value as Map;
          //userData: The retrieved data is cast to a Map type, where the keys are field names (like 'Username', 'Age', 'Height', 'Weight'), and the values are the data corresponding to those fields.

          setState(() {
            //userData['field']?.toString() ?? '': This safely retrieves the value from userData. If the field is null, it assigns an empty string ('') as the default value to avoid errors.
            _usernameController.text = userData['Username']?.toString() ?? '';
            _ageController.text = userData['Age']?.toString() ?? '';
            _heightController.text = userData['Height']?.toString() ?? '';
            _weightController.text = userData['Weight']?.toString() ?? '';
          });
        } else {
          setState(() {
            errorMessage = "No data found for this user.";
          });
        }
      } catch (error) {
        print("Error fetching user info: $error");
        setState(() {
          errorMessage = "Error fetching user info. Please try again.";
        });
      }
    }
  }

  // Method to update user info in Firebase Realtime Database
  Future<void> _updateUserInfo() async {
    //Type: currentUser returns an object of type User?, where the ? indicates that this variable can be null if no user is signed in.
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      //The uid is a unique identifier for each user in Firebase Authentication. It is typically used to reference the user in Firebase Realtime Database, Firestore, and other Firebase services
      String uid = user.uid;
      DatabaseReference userRef = FirebaseDatabase.instance.ref('ProfileGather/$uid');

      if (_usernameController.text.isEmpty &&
          _ageController.text.isEmpty &&
          _heightController.text.isEmpty &&
          _weightController.text.isEmpty) {
        setState(() {
          errorMessage = "No changes detected. Please modify at least one field.";
        });
        return;
      }

      try {
        //The await userRef.update function is used to update existing data at a specific reference in Firebase Realtime Database
        await userRef.update({
          'Username': _usernameController.text,
          'Age': _ageController.text,
          'Height': _heightController.text,
          'Weight': _weightController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User details updated successfully')));
        setState(() {
          errorMessage = '';
        });
      } catch (error) {
        print("Error updating user info: $error");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating user details')));
      }
    }
  }

  // Method to update password in Firebase Authentication
  Future<void> _updatePassword() async {
    //This assigns the currently signed-in user (if any) to the user variable. The type of user is User?, which means it can hold a User object or null.
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      //email will always hold a valid String. If the user's email is available (i.e., not null), it will be assigned to email. If the user's email is null, an empty string ('') will be assigned to email.
      String email = user.email ?? ''; // Ensure email is not null
      String oldPassword = _oldPasswordController.text.trim();
      String newPassword = _newPasswordController.text.trim();

      // Check if fields are filled
      if (oldPassword.isEmpty || newPassword.isEmpty) {
        setState(() {
          errorMessage = "Please fill out both fields.";
        });
        return;
      }

      try {
        // Reauthenticate with old credentials
        // a user wants to perform sensitive actions like updating their password. Firebase requires reauthentication for security reasons before allowing changes to the user's account.
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: oldPassword,
        );

        //user.reauthenticateWithCredential: This method takes the credentials you created (with the email and the old password) and reauthenticates the user.
        await user.reauthenticateWithCredential(credential);

        // Update to the new password
        //user.updatePassword(newPassword): This method updates the user's password with the new password (newPassword).
        await user.updatePassword(newPassword);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully!')),
        );

        setState(() {
          errorMessage = ''; //return empty string
        });
      } on FirebaseAuthException catch (e) {
        // Handle specific error cases
        setState(() {
          //e.code contains the error code returned by Firebase, which represents the type of error encountered.
          switch (e.code) {
            //This occurs when the provided old password is incorrect during reauthentication.
            case 'wrong-password':
              errorMessage = 'The old password is incorrect.';
              break;
              //This occurs when the user trying to update the password doesn't match the user that is currently signed in. This might happen if there's a mix-up with the credentials (for example, trying to reauthenticate with a different user's email/password).
            case 'user-mismatch':
              errorMessage = 'User mismatch occurred.';
              break;
              //This occurs when no user is found with the provided email during reauthentication.
            case 'user-not-found':
              errorMessage = 'No user record found for this email.';
              break;
              //This occurs when the credential used for reauthentication is invalid. For example, the old password might not match the required format or the credential might have been corrupted.
            case 'invalid-credential':
              errorMessage =
              'Invalid credential. Please check your old password.';
              break;
            default:
              //If the error code doesn't match any of the specific cases above, the default error message is set to the message returned by Firebase (e.message), which might give more details about the specific issue.
              errorMessage = 'Error updating password: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          errorMessage = "An unexpected error occurred: $e";
        });
      }
    }
  }

  // Method to delete user info from Firebase and Firebase Authentication
  Future<void> _deleteUserAccount() async {
    //The line bool confirmDelete = await _showDeleteConfirmationDialog(context); is used to show a confirmation dialog to the user and store their response in the confirmDelete variable. The boolean result (true or false) determines whether the delete action should proceed based on the user's confirmation.
    bool confirmDelete = await _showDeleteConfirmationDialog(context);

    if (confirmDelete) {
      //to get the currently authenticated user from Firebase Authentication.
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        DatabaseReference userRef = FirebaseDatabase.instance.ref('ProfileGather/$uid');

        try {
          //delete a user’s data from Firebase Realtime Database and Firebase Authentication
          await userRef.remove();
          await user.delete();

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Account deleted successfully')));

          _auth.signOut();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } catch (error) {
          print("Error deleting account: $error");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting account')));
        }
      }
    }
  }

  // Show confirmation dialog for account deletion
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(context: context, builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.lightBlue,
        title: const Text('Confirm Deletion',style: TextStyle(color: Colors.white),),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.',style: TextStyle(color: Colors.white),),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No',style: TextStyle(color: Colors.white),),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Yes',style: TextStyle(color: Colors.white),),
          ),
        ],
      );
    }) ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Information', style: TextStyle(color: Colors.lightBlue)),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.lightBlue)),
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: Colors.lightBlue)),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(
                    labelText: 'Height',
                    labelStyle: TextStyle(color: Colors.lightBlue)),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                    labelText: 'Weight',
                    labelStyle: TextStyle(color: Colors.lightBlue)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Old Password',
                    labelStyle: TextStyle(color: Colors.lightBlue)),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.lightBlue)),
              ),
              const SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ElevatedButton(
                onPressed: _updateUserInfo,
                child: const Text('Update Info', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePassword,
                child: const Text('Update Password', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _deleteUserAccount,
                child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
