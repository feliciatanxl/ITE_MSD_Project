import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class WaterLogPage extends StatefulWidget {
  @override
  _WaterLogPageState createState() => _WaterLogPageState();
}

class _WaterLogPageState extends State<WaterLogPage> {
  final DatabaseReference waterLogsRef = FirebaseDatabase.instance.ref('WaterIntakeLog');
  User? currentUser = FirebaseAuth.instance.currentUser; // Get the authenticated user
  //declares a nullable DateTime variable named selectedDate in Dart.
  DateTime? selectedDate; // Date selected for filtering
  //declares a list called filteredLogs which holds Map objects with keys of type String and values of type dynamic.
  List<Map<String, dynamic>> filteredLogs = []; // Filtered logs based on selected date

  Future<void> _addLog(int amount, String waterType, DateTime date) async {
    if (currentUser == null) {
      print("User is not authenticated");
      return; // Ensure the user is logged in
    }

    final userId = currentUser!.uid;
    final newLogRef = waterLogsRef.child(userId).push();

    try {
      await newLogRef.set({
        'amount': amount,
        'waterType': waterType,
        'date': date.toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data added successfully")),
      );
    } catch (e) {
      print("Error adding log: $e");
    }
  }

  Future<void> _updateLog(String logId, int amount, String waterType, DateTime date) async {
    if (currentUser == null) return; // Ensure the user is logged in

    //retrieves the uid (user ID) of the currently authenticated user from Firebase Authentication.
    final userId = currentUser!.uid;

    try {
      await waterLogsRef.child(userId).child(logId).update({
        'amount': amount,
        'waterType': waterType,
        'date': date.toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Edited successfully")),
      );
    } catch (e) {
      print("Error updating log: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchLogs() {
    if (currentUser  == null) return Stream.value([]); // Ensure the user is logged in

    final userId = currentUser !.uid;

    return waterLogsRef.child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.entries
          .map((entry) => {
        'id': entry.key,
        ...Map<String, dynamic>.from(entry.value as Map),
      })
          .toList();
    });
  }

  // Function to filter logs based on the selected date
  void _filterLogsByDate(DateTime selectedDate) {
    setState(() {
      this.selectedDate = selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Water Intake Tracker",style: TextStyle(color: Colors.lightBlue),),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: currentUser == null
          ? Center(child: Text("You need to log in to view water intake logs."))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? "Select a date to filter"
                      : "Selected Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  style: TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            primaryColor: Colors.lightBlue, // Header and active text color
                            dialogBackgroundColor: Colors.white, // Dialog background color
                            textTheme: TextTheme(
                              bodyMedium: TextStyle(color: Colors.black), // Calendar text color
                            ),
                            colorScheme: ColorScheme.light(
                              primary: Colors.lightBlue, // Highlight color for selected date
                              onPrimary: Colors.white,  // Text color on the primary color
                              onSurface: Colors.black,  // Default text color
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      _filterLogsByDate(pickedDate);
                    }
                  },
                  child: Text(
                    "Select Date",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchLogs(), // Use the stream method here
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No water intake logs found."));
                }

                // Filter logs based on the selected date
                List<Map<String, dynamic>> logs = snapshot.data!;
                if (selectedDate != null) {
                  logs = logs.where((log) {
                    DateTime logDate = DateTime.parse(log['date']);
                    return logDate.year == selectedDate!.year &&
                        logDate.month == selectedDate!.month &&
                        logDate.day == selectedDate!.day;
                  }).toList();
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final amount = log['amount'];
                    final waterType = log['waterType'];
                    final date = DateTime.parse(log['date']);
                    return ListTile(
                      tileColor: Colors.lightBlue,
                      title: Text('$amount mL - $waterType', style: TextStyle(color: Colors.white)),
                      subtitle: Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _showEditLogDialog(context, log['id'], amount, waterType, date),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _deleteLog(log['id']),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: currentUser == null
          ? null
          : FloatingActionButton(
        backgroundColor: Colors.lightBlue,
        onPressed: () => _showAddLogDialog(context),
        child: Icon(Icons.add,color: Colors.white, ),
      ),
    );
  }

  Future<void> _deleteLog(String logId) async {
    if (currentUser == null) return; // Ensure the user is logged in

    final userId = currentUser!.uid;
    await waterLogsRef.child(userId).child(logId).remove();
    setState(() {}); // Refresh the logs
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Deleted successfully")),
    );
  }

  Future<void> _showAddLogDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final customWaterTypeController = TextEditingController();
    String selectedWaterType = "Coffee";
    DateTime selectedDate = DateTime.now();

    final waterTypes = [
      "Coffee",
      "Tea",
      "Juice",
      "Sport Drink",
      "Coconut Water",
      "Smoothie",
      "Chocolate Drink",
      "Carbonated Water",
      "Soda",
      "Wine",
      "Beer",
      "Liquor",
      "Others",
    ];

    showDialog(
      context: context,
      builder: (context) {
        DateTime tempSelectedDate = selectedDate;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.lightBlue,
              title: Text("Add Water Intake",style: TextStyle(color: Colors.white,),textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Amount (mL)",labelStyle: TextStyle(color: Colors.white),),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10,),
                    DropdownButtonFormField<String>(
                      value: selectedWaterType,
                      items: waterTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type,style: TextStyle(color: Colors.white),),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          //The statement selectedWaterType = value!; is assigning a value to a variable called selectedWaterType.
                          selectedWaterType = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: "Water Type",labelStyle: TextStyle(color: Colors.white),),
                      style: TextStyle(color: Colors.lightBlue),
                      dropdownColor: Colors.lightBlue,
                      iconEnabledColor: Colors.white,
                    ),
                    //if (selectedWaterType == "Others")
                      //TextField(
                        //controller: customWaterTypeController,
                        //decoration: InputDecoration(labelText: "Custom Water Type"),
                      //),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${tempSelectedDate.day}/${tempSelectedDate.month}/${tempSelectedDate.year}",
                          style: TextStyle(fontSize: 16,color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: tempSelectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    primaryColor: Colors.lightBlue, // Header and active text color
                                    dialogBackgroundColor: Colors.lightBlue.shade100, // Dialog background
                                    textTheme: TextTheme(
                                      bodyMedium: TextStyle(color: Colors.white), // Calendar text color
                                    ),
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.lightBlue, // Highlight color for selected date
                                      onPrimary: Colors.white,  // Text color on the primary color
                                      onSurface: Colors.black,  // Default text color
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                tempSelectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text(
                            "Select Date",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel",style: TextStyle(color: Colors.white),),
                ),
                ElevatedButton(
                  onPressed: () {
                    final waterTypeToSave = selectedWaterType == "Others"
                        ? customWaterTypeController.text
                        : selectedWaterType;
                    _addLog(
                      int.tryParse(amountController.text) ?? 0,
                      waterTypeToSave,
                      tempSelectedDate,
                    );
                    Navigator.pop(context);
                  },
                  child: Text("Save",style: TextStyle(color: Colors.lightBlue),),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditLogDialog(BuildContext context, String logId, int amount, String waterType, DateTime date) async {
    final amountController = TextEditingController(text: amount.toString());
    final customWaterTypeController = TextEditingController(text: waterType);
    String selectedWaterType = waterType;
    DateTime selectedDate = date;

    final waterTypes = [
      "Coffee",
      "Tea",
      "Juice",
      "Sport Drink",
      "Coconut Water",
      "Smoothie",
      "Chocolate Drink",
      "Carbonated Water",
      "Soda",
      "Wine",
      "Beer",
      "Liquor",
      "Others",
    ];

    showDialog(
      context: context,
      builder: (context) {
        DateTime tempSelectedDate = selectedDate;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.lightBlue,
              title: Text("Edit Water Intake",style: TextStyle(color: Colors.white),textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Amount (mL)",labelStyle: TextStyle(color: Colors.white)),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10,),
                    DropdownButtonFormField<String>(
                      value: selectedWaterType,
                      items: waterTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type,style: TextStyle(color: Colors.white),),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWaterType = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: "Water Type",labelStyle: TextStyle(color: Colors.white)),
                      style: TextStyle(color: Colors.lightBlue),
                      dropdownColor: Colors.lightBlue,
                      iconEnabledColor: Colors.white,
                    ),
                    //if (selectedWaterType == "Others")
                      //TextField(
                        //controller: customWaterTypeController,
                        //decoration: InputDecoration(labelText: "Custom Water Type"),
                      //),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${tempSelectedDate.day}/${tempSelectedDate.month}/${tempSelectedDate.year}",
                          style: TextStyle(fontSize: 16,color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: tempSelectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    primaryColor: Colors.lightBlue,
                                    dialogBackgroundColor: Colors.lightBlue.shade100,
                                    textTheme: TextTheme(
                                      bodyMedium: TextStyle(color: Colors.black),
                                    ),
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.lightBlue,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                tempSelectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text("Select Date",style: TextStyle(color: Colors.white),),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel",style: TextStyle(color: Colors.white),),
                ),
                ElevatedButton(
                  onPressed: () {
                    final waterTypeToSave = selectedWaterType == "Others"
                        ? customWaterTypeController.text
                        : selectedWaterType;
                    _updateLog(
                      logId,
                      int.tryParse(amountController.text) ?? 0,
                      waterTypeToSave,
                      tempSelectedDate,
                    );
                    Navigator.pop(context);
                  },
                  child: Text("Save",style: TextStyle(color: Colors.lightBlue),),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
