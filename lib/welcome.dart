import 'package:flutter/material.dart';
import 'package:proj_08_feliciatan/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:proj_08_feliciatan/calories_calc.dart';
import 'package:proj_08_feliciatan/foodblog.dart';
import 'package:proj_08_feliciatan/profile_gather.dart';
import 'package:proj_08_feliciatan/water_log.dart';
import 'bmi_calc.dart';
import 'login.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final AuthService _auth = AuthService();

  // Function to load user info from Firebase Realtime Database
  Stream<DatabaseEvent> _getUserInfoStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      DatabaseReference userRef = FirebaseDatabase.instance.ref('ProfileGather/$uid');
      return userRef.onValue; // Listen to changes at this reference
    }
    return Stream.empty(); // Return an empty stream if no user is logged in
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: StreamBuilder<DatabaseEvent>(
          //<DatabaseEvent>: The type of data being emitted by the stream. In this case, it is a DatabaseEvent, likely from Firebase's Realtime Database SDK
          stream: _getUserInfoStream(),
          //Connects the StreamBuilder to a stream that provides real-time updates
          //_getUserInfoStream() is a function (not shown here) that likely returns a stream of user data
          builder: (context, snapshot) {
            // If no data is received or if an error occurs
            if (snapshot.connectionState == ConnectionState.waiting) {
              //This state occurs when the stream is still connecting or waiting for data.
              return const Text("Welcome Back!", style: TextStyle(color: Colors.lightBlue));
            } else if (snapshot.hasError) {
              //Triggered if an error occurs while fetching data from the stream.
              return const Text("Error loading user info", style: TextStyle(color: Colors.lightBlue));
            } else if (snapshot.hasData && snapshot.data!.snapshot.exists) {
              //Accesses the Username field from the database snapshot.
              // .value.toString() converts the value into a string for display.
              // Extract the username from the snapshot data
              var username = snapshot.data!.snapshot.child('Username').value.toString();
              return Text('Welcome Back, $username!', style: TextStyle(color: Colors.lightBlue));
            } else {
              return const Text("Welcome Back!", style: TextStyle(color: Colors.lightBlue));
            }
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BmiCalc(), // Navigate to BmiCalc
                  ),
                );
              },
              child: const Text("BMI Calculator", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
            const SizedBox(height: 10), // Adds space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalorieCalculator(), // Navigate to CalorieCalculator
                  ),
                );
              },
              child: const Text("Calories Calculator", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
            const SizedBox(height: 10), // Adds space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaterLogPage(), // Navigate to WaterIntakeLogPage
                  ),
                );
              },
              child: const Text("Daily Water Intake Log", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
            const SizedBox(height: 10), // Adds space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileGather(), // Navigate to ProfileGather
                  ),
                );
              },
              child: const Text("Profile Gathering", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
            const SizedBox(height: 10), // Adds space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlogListPage(), // Navigate to CalorieTrackerPage
                  ),
                );
              },
              child: const Text("Food Blog", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
            const SizedBox(height: 20), // Adds spacing between the last button and sign out button
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                //This line calls the signOut method on the _auth object
                //Signing out terminates the user's current session and removes their authentication tokens
                if (mounted) {
                  //mounted is a property of the State class in Flutter
                  //It checks if the widget is still part of the widget tree before performing any operations that modify the UI
                  //This prevents errors like updating the state of a widget that has already been disposed of
                  goToLogin(context);
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  void goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to LoginPage after sign-out
    );
  }
}
