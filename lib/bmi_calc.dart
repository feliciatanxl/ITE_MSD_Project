import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class BmiCalc extends StatelessWidget {
  const BmiCalc({super.key});

  @override
  Widget build(BuildContext context) {
    return BMI();
  }
}

class BMI extends StatefulWidget {
  const BMI({super.key});

  @override
  State<BMI> createState() => _BMIState();
}

class _BMIState extends State<BMI> {
  final TextEditingController _heightController = TextEditingController(); //To capture height
  final TextEditingController _weightController = TextEditingController(); //To capture weight
  double _result = 0.0; //_result: store the calculated BMI value
  String _bmiCategory = ""; //_bmiCategory: store the BMI category
  final _genderList = ["Female", "Male"]; //_genderList: predefined gender options for a dropdown menu
  var _selectGender = ""; //_selectGender: store the selected gender
  final _databaseReference = FirebaseDatabase.instance.ref(); //_databaseReference: reference to the firebase realtime database root
  late User _user; //_user: the autenticated user from firebase auth
  late DatabaseReference _userBmiRef; //reference to the specific user's BMI data in the database

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!; //initializes _user with the current logged-in firebase user
    _userBmiRef = _databaseReference.child('BMI_Calc/${_user.uid}'); //sets _userBmiRef to point to the user's BMI data in the database
  }

  // Function to add BMI data to Firebase
  // Pushes a new BMI entry with details like gender, height, weight, BMI, and timestamp into the firebase database
  void addData(double bmi, String category) {
    _userBmiRef.push().set({
      'gender': _selectGender,
      'height': _heightController.text,
      'weight': _weightController.text,
      'bmi': bmi,
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
    }).then((_) {
      print("BMI data added successfully!");
      // Show SnackBar to inform the user that the entry was added successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('BMI entry added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) { // this accepts a function as an argument, where error is the variable representing the error details. To handle any failure gracefully without crashing the app
      print("Failed to add BMI data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add BMI data'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Function to calculate BMI
  // Validates inputs and calculates BMI using the formula: BMI= Weight/Height
  void calculateBMI() {
    // Check if height or weight is empty
    if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
      // Show SnackBar if any field is blank
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both height and weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;  // Exit the function if fields are empty
    }

    // Proceed with BMI calculation if fields are filled
    double height = double.parse(_heightController.text) / 100; // converting the height from cm to m by dividing the value by 100
    double weight = double.parse(_weightController.text);
    double result = weight / (height * height);
    result = result * pow(10.0, 2).toDouble(); //multiplies the result by 100 to shift the decimal point two places to the right
    result = result.round().toDouble(); //rounds the shifted result to the nearest whole number,, converts the rounded number back to a double to maintain compatibility
    result = result / pow(10.0, 2).toDouble(); //divide the result by 100 to shift the decimal point two places to the original position
    _bmiCategory = _getResult(result); //Call the method to determine the BMI category
    _result = result; //storing the data in this variable

    // Add data to Firebase after calculation
    addData(_result, _bmiCategory); //adding data to firebase

    setState(() {});  // Trigger UI refresh
  }

  // Function to determine BMI category
  String _getResult(double bmi) {
    if (bmi <= 18.4) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return 'Normal';
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  // Function to delete BMI data from Firebase
  void deleteData(String key) {
    _userBmiRef.child(key).remove().then((_) {
      print("BMI data deleted successfully!");
      // Show SnackBar to inform the user that the data has been deleted successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('BMI data deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});  // Refresh data after deletion
    }).catchError((error) {
      print("Failed to delete BMI data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete BMI data'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Function to edit BMI data in Firebase and trigger a UI refresh
  void editData(String key, double bmi, String category, String height, String weight) {
    _userBmiRef.child(key).update({
      'bmi': bmi,
      'category': category,
      'height': height,
      'weight': weight,
    }).then((_) {
      print("BMI data updated successfully!");
      // Show SnackBar to inform the user that the data was updated successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('BMI data updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});  // Trigger UI update after the edit
    }).catchError((error) {
      print("Failed to update BMI data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update BMI data'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Dialog to edit BMI data
  Future<void> _showEditDialog(String key, String currentHeight, String currentWeight, double currentBmi, String currentCategory) async {
    TextEditingController heightController = TextEditingController(text: currentHeight);
    TextEditingController weightController = TextEditingController(text: currentWeight);
    TextEditingController bmiController = TextEditingController(text: currentBmi.toString()); //convert int to string
    TextEditingController categoryController = TextEditingController(text: currentCategory);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.lightBlue,
          title: const Text('Edit BMI Data',style: TextStyle(color: Colors.white),textAlign: TextAlign.center,),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  style: TextStyle(color: Colors.white),
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)',labelStyle: TextStyle(color: Colors.white)),
                ),
                TextField(
                  style: TextStyle(color: Colors.white),
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)',labelStyle: TextStyle(color: Colors.white)),
                ),
                TextField(
                  style: TextStyle(color: Colors.white),
                  controller: bmiController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'BMI',labelStyle: TextStyle(color: Colors.white)),
                ),
                TextField(
                  style: TextStyle(color: Colors.white),
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category',labelStyle: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save',style: TextStyle(color: Colors.white),),
              onPressed: () {
                double editedBmi = double.parse(bmiController.text);
                String editedCategory = categoryController.text;
                String editedHeight = heightController.text;
                String editedWeight = weightController.text;

                // Recalculate BMI after editing height or weight
                double heightInMeters = double.parse(editedHeight) / 100; //convert editedHeight from cm to m by dividing by 100
                double weightInKg = double.parse(editedWeight); //parses editedWeight as kg
                double recalculatedBmi = weightInKg / (heightInMeters * heightInMeters); // BMI formula
                recalculatedBmi = recalculatedBmi * pow(10.0, 2).toDouble(); //multiples the bmi value by 100 to shift the decimal point two places to the right
                recalculatedBmi = recalculatedBmi.round().toDouble(); //round the shifted result to the nearest whole number using .round
                recalculatedBmi = recalculatedBmi / pow(10.0, 2).toDouble(); //divides the rounded number by 100 to return the decimal point to its original position

                // Update the data in Firebase
                String updatedCategory = _getResult(recalculatedBmi); //call the _getResult function to determine the updated BMI category based on the recalculated BMI value
                editData(key, recalculatedBmi, updatedCategory, editedHeight, editedWeight); //calls the editData function to update the user's BMI data in firebase

                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Confirmation dialog before deleting BMI data
  void _showDeleteConfirmationDialog(String key) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this BMI data?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();  // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                deleteData(key);  // Perform the deletion
                Navigator.of(context).pop();  // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator',style: TextStyle(color: Colors.lightBlue),),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height in cm',
                icon: Icon(Icons.height),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight in kg',
                icon: Icon(Icons.line_weight),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              items: _genderList.map((e) {
                return DropdownMenuItem(
                  child: Text(
                    e,
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: e,
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectGender = val as String; // val represent a variable holding a value that is being explicitly cast to the type string using as operator
                });
              },
              icon: const Icon(
                Icons.arrow_drop_down_circle,
                color: Colors.lightBlue,
              ),
              dropdownColor: Colors.lightBlue,
              decoration: InputDecoration(
                labelText: 'Gender',
                labelStyle: TextStyle(
                  color: _selectGender.isEmpty
                      ? Colors.grey
                      : (_selectGender == "Male" ? Colors.blue : Colors.pink), //true/false
                ),
                prefixIcon: const Icon(
                  Icons.account_box,
                  color: Colors.grey,
                ),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.lightBlue,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: calculateBMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Calculate BMI',
                style: TextStyle(fontSize: 18,color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Your BMI: $_result',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _result == 0.0 ? "" : _bmiCategory, // true:empty string/false
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Expanded(
              child: StreamBuilder(
                stream: _userBmiRef.orderByChild('timestamp').limitToLast(10).onValue,
                //_userBmiRef: firebase database reference
                //orderByChild('timestamp'): sorts data by the timestamp field (assumes each entry has a timestamp for chronological order)
                //limitToLast(10): limits the results to the 10 most recent entries
                //onValue: listens for real-time updates from firebase
                builder: (context, snapshot) { //snapshot: contains the real-time firebase data, the current connection state, and any errors
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); //shows a loading indicator while the data is being fetched
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data')); //displays an error message if the data stream encounters and issue
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('No BMI data available')); //handles cases where no BMI data exists in the database
                  }

                  var data = snapshot.data!.snapshot.value as Map; //data extraction: the snapshot.value is cast as a map(key-value pairs from firebase)
                  List<dynamic> bmiList = []; //list conversion: loops through the data and converts each entry into a structured format
                  data.forEach((key, value) {
                    bmiList.add({
                      'key': key,
                      'height': value['height'],
                      'weight': value['weight'],
                      'bmi': value['bmi'],
                      'category': value['category'],
                    });
                  });

                  return ListView.builder(
                    itemCount: bmiList.length, //itemCount: specifies the number of items to generate (bmiList.length)
                    itemBuilder: (context, index) { //itemBuilder: builds each item widget dynamically
                      var bmiData = bmiList[index];
                      //purpose: accesses the BMI entry at the specific index from the bmiList
                      //bmiList: a list containing BMI data entries, where each entry is a Map with details like key, height,weight, bmi, and category.
                      //index: the current index of the ListView.builder, which iterates through all items in bmiList
                      String key = bmiData['key'];
                      //string key: stores the extracted value as a string
                      //purpose: extracts the unique key for the current BMI entry
                      return Card(
                        child: ListTile(
                          tileColor: Colors.lightBlue,
                          title: Text("BMI: ${bmiData['bmi']}",style: TextStyle(color: Colors.white),),
                          subtitle: Text("Category: ${bmiData['category']}",style: TextStyle(color: Colors.white),),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete,color: Colors.white,),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(key);  // Show confirmation dialog
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,color: Colors.white,),
                                onPressed: () {
                                  _showEditDialog(
                                    key,
                                    bmiData['height'],
                                    bmiData['weight'],
                                    bmiData['bmi'],
                                    bmiData['category'],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}