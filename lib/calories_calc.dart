import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calorie Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalorieCalculator(),
    );
  }
}

class CalorieCalculator extends StatefulWidget {
  const CalorieCalculator({Key? key}) : super(key: key);

  @override
  State<CalorieCalculator> createState() => _CalorieCalculatorState();
}

class _CalorieCalculatorState extends State<CalorieCalculator> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('ProfileGather');
  final DatabaseReference _entriesRef = FirebaseDatabase.instance.ref('CaloriesCalculator');

  String _gender = 'male'; // Default gender, ideally retrieved from the database
  int _age = 25;
  double _height = 170;
  double _weight = 70;
  double _calorieRequirement = 0.0;
  String _goal = 'maintain'; // User goal (maintain, lose, gain)
  String _activityLevel = 'sedentary'; // Default activity level

  // Controllers for the input fields
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  List<Map<String, dynamic>> _entries = []; // List to hold saved entries

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenToUserData();
    _loadEntries();
  }

  // Method to load user data from Firebase initially
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      final snapshot = await _userRef.child(uid).get();
      if (snapshot.exists) {
        var userData = snapshot.value as Map;
        setState(() {
          _age = int.tryParse(userData['Age'] ?? '25') ?? 25;
          _height = double.tryParse(userData['Height'] ?? '170') ?? 170;
          _weight = double.tryParse(userData['Weight'] ?? '70') ?? 70;
          _gender = userData['Gender'] ?? 'male'; // Ensure gender is stored in the database
        });
        // Set the controllers with existing data from the database
        _heightController.text = _height.toString();
        _weightController.text = _weight.toString();
        _ageController.text = _age.toString();
      }
    }
    _calculateCalories();
  }

  // Method to listen for real-time updates in user data
  void _listenToUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      _userRef.child(uid).onValue.listen((DatabaseEvent event) {
        if (!mounted) return; // Check if widget is still in the tree
        if (event.snapshot.exists) {
          var userData = event.snapshot.value as Map;
          setState(() {
            _age = int.tryParse(userData['Age'] ?? '25') ?? 25;
            _height = double.tryParse(userData['Height'] ?? '170') ?? 170;
            _weight = double.tryParse(userData['Weight'] ?? '70') ?? 70;
            _gender = userData['Gender'] ?? 'male'; // Ensure gender is stored in the database
          });
          // Update the controllers with real-time data from Firebase
          _heightController.text = _height.toString();
          _weightController.text = _weight.toString();
          _ageController.text = _age.toString();

          // Recalculate calories after data is updated
          _calculateCalories();
        }
      });
    }
  }

  // Method to load previous entries from Firebase
  Future<void> _loadEntries() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      final snapshot = await _entriesRef.child(uid).get();
      if (!mounted) return; // Check if widget is still in the tree
      if (snapshot.exists) {
        var entriesData = snapshot.value as Map;
        List<Map<String, dynamic>> entriesList = [];
        entriesData.forEach((key, value) {
          var entry = Map<String, dynamic>.from(value);
          entry['entryId'] = key; // Store the entry ID
          entriesList.add(entry);
        });
        setState(() {
          _entries = entriesList;
        });
      }
    }
  }

  // Method to save the new entry to Firebase under UserEntries node
  Future<void> _addEntry() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      //generating a unique ID for an entry, typically in a Firebase Realtime Database or another NoSQL database, with a fallback to the current timestamp if the generated ID is null.
      String entryId = _entriesRef.push().key ?? DateTime.now().toString();

      await _entriesRef.child(uid).child(entryId).set({
        'Age': _age.toString(),
        'Height': _height.toString(),
        'Weight': _weight.toString(),
        'Goal': _goal,
        'ActivityLevel': _activityLevel,
        'CalorieRequirement': _calorieRequirement.toString(), // Storing the calculated calorie value
        //ISO 8601 is a widely used format for representing date and time, which looks like: "2024-11-19T14:30:45.123456" (the exact string will depend on the current date and time).
        'Date': DateTime.now().toIso8601String(),
      });

      // Show a snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New entry created successfully!'),
          duration: Duration(seconds: 2), // Adjust duration as needed
        ),
      );

      _loadEntries(); // Reload entries after adding new one
    }
  }

  // Method to delete an entry and update the UI in real-time
  Future<void> _deleteEntry(String entryId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      await _entriesRef.child(uid).child(entryId).remove();

      // Update the UI immediately after deleting the entry
      setState(() {
        //remove an entry from the _entries list where the entry['entryId'] matches a specific entryId
        _entries.removeWhere((entry) => entry['entryId'] == entryId);
      });

      // Show a snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry deleted successfully!'),
          duration: Duration(seconds: 2), // Adjust duration as needed
        ),
      );
    }
  }

  // Method to calculate BMR and TDEE based on user data and activity level
  void _calculateCalories() {
    double bmr;

    // Calculate BMR based on the Mifflin-St Jeor Equation
    //The parameters for weight, height, and age are assumed to be in metric units (kg for weight, cm for height, years for age).
    if (_gender == 'male') {
      bmr = 10 * _weight + 6.25 * _height - 5 * _age + 5;
    } else {
      bmr = 10 * _weight + 6.25 * _height - 5 * _age - 161;
    }

    // Calculate TDEE based on activity level
    double activityFactor;
    switch (_activityLevel) {
      case 'light':
        activityFactor = 1.375;
        break;
      case 'moderate':
        activityFactor = 1.55;
        break;
      case 'active':
        activityFactor = 1.725;
        break;
      case 'very active':
        activityFactor = 1.9;
        break;
      default:
        activityFactor = 1.2; // Sedentary
    }
    double tdee = bmr * activityFactor;

    // Adjust calorie needs based on goal
    switch (_goal) {
      case 'lose':
        _calorieRequirement = tdee - 500; // Reduce 500 calories for weight loss
        break;
      case 'gain':
        _calorieRequirement = tdee + 500; // Add 500 calories for weight gain
        break;
      default:
        _calorieRequirement = tdee; // Maintain current weight
    }

    setState(() {}); // Update UI with calculated calories
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Calorie Calculator', style: TextStyle(color: Colors.lightBlue)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Daily Calorie Requirement: ${_calorieRequirement.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightBlue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Gender selection dropdown
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                setState(() {
                  _gender = value ?? 'male';
                });
                _calculateCalories();
              },
            ),
            const SizedBox(height: 20),
            // Age text field
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _age = int.tryParse(value) ?? _age;
                });
                _calculateCalories();
              },
            ),
            const SizedBox(height: 20),
            // Height text field (pre-filled with user's height)
            TextField(
              controller: _heightController,
              decoration: const InputDecoration(labelText: 'Height (cm)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _height = double.tryParse(value) ?? _height;
                });
                _calculateCalories();
              },
            ),
            const SizedBox(height: 20),
            // Weight text field (pre-filled with user's weight)
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _weight = double.tryParse(value) ?? _weight;
                });
                _calculateCalories();
              },
            ),
            const SizedBox(height: 20),
            // Goal selection dropdown
            DropdownButtonFormField<String>(
              value: _goal,
              decoration: const InputDecoration(labelText: 'Goal'),
              items: const [
                DropdownMenuItem(value: 'maintain', child: Text('Maintain weight')),
                DropdownMenuItem(value: 'lose', child: Text('Lose weight')),
                DropdownMenuItem(value: 'gain', child: Text('Gain weight')),
              ],
              onChanged: (value) {
                setState(() {
                  _goal = value ?? 'maintain';
                });
                _calculateCalories();
              },
            ),
            const SizedBox(height: 20),
            // Activity level selection dropdown
            DropdownButtonFormField<String>(
              value: _activityLevel,
              decoration: const InputDecoration(labelText: 'Activity Level'),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                DropdownMenuItem(value: 'light', child: Text('Lightly active')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderately active')),
                DropdownMenuItem(value: 'active', child: Text('Very active')),
                DropdownMenuItem(value: 'very active', child: Text('Extremely active')),
              ],
              onChanged: (value) {
                setState(() {
                  _activityLevel = value ?? 'sedentary';
                });
                _calculateCalories();
              },
            ),
            const SizedBox(height: 20),
            // Add entry button
            ElevatedButton(
              onPressed: _addEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue
              ),
              child: const Text('Save Entry',style: TextStyle(color: Colors.white),),
            ),
            const SizedBox(height: 20),
            // View saved entries button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewEntriesPage(
                      entries: _entries,
                      onDelete: _deleteEntry,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue
              ),
              child: const Text('View Saved Entries',style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewEntriesPage extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final Future<void> Function(String entryId) onDelete;

  const ViewEntriesPage({Key? key, required this.entries, required this.onDelete}) : super(key: key);

  @override
  _ViewEntriesPageState createState() => _ViewEntriesPageState();
}

class _ViewEntriesPageState extends State<ViewEntriesPage> {
  late List<Map<String, dynamic>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Entries',style: TextStyle(color: Colors.lightBlue),),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _entries.isEmpty
            ? const Center(child: Text('No entries found.'))
            : ListView.builder(
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                tileColor: Colors.lightBlue,
                title: Text('Calories: ${entry['CalorieRequirement']} kcal', style: TextStyle(color: Colors.white)),
                subtitle: Text('Date: ${entry['Date']}', style: TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    await widget.onDelete(entry['entryId']); // Deleting from Firebase and UI
                    setState(() {
                      _entries.removeWhere((e) => e['entryId'] == entry['entryId']); // Remove from local list
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
