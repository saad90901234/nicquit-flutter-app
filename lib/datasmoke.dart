import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nicquit/UserProgressScreen.dart';

class DataSmoking extends StatefulWidget {
  const DataSmoking({Key? key}) : super(key: key);

  @override
  _DataSmokingState createState() => _DataSmokingState();
}

class _DataSmokingState extends State<DataSmoking> {
  final TextEditingController _cigarettesPerDayController = TextEditingController();
  final TextEditingController _pricePerPackController = TextEditingController();
  final TextEditingController _cigarettesPerPackController = TextEditingController();

  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String _message = '';

  // List of currencies
  String _selectedCurrency = '\$'; // Default to dollar symbol
  final List<String> _currencies = [
    '\$', '£', 'PKR', 'INR', 'SAR', '€', '¥', 'CAD', 'AUD', 'CHF', 'AED'
  ];

  // Method to select date and time
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Method to submit data
  Future<void> _submitData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _message = 'No user is currently signed in.';
      });
      return;
    }

    final String uid = user.uid; // Get the UID of the current user
    final String cigarettesPerDay = _cigarettesPerDayController.text;
    final String pricePerPack = _pricePerPackController.text;
    final String cigarettesPerPack = _cigarettesPerPackController.text;

    if (cigarettesPerDay.isEmpty || pricePerPack.isEmpty || cigarettesPerPack.isEmpty || _selectedDateTime == null) {
      setState(() {
        _message = 'All fields and the date/time are required.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update user data in Firestore against their UID
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'cigarettesPerDay': cigarettesPerDay,
        'pricePerPack': pricePerPack,
        'cigarettesPerPack': cigarettesPerPack,
        'currency': _selectedCurrency, // Store selected currency
        'quitTime': _selectedDateTime!.toIso8601String(),
      });

      setState(() {
        _message = 'Data saved successfully.';
      });

      // Navigate to UserProgressScreen and ensure they cannot go back to DataSmoking
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserProgressScreen()),
      );
    } catch (e) {
      setState(() {
        _message = 'Error saving data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF73AEF5),
              Color(0xFF61A4F1),
              Color(0xFF478DE0),
              Color(0xFF398AE5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Let\'s start your journey',
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.0),
            Card(
              color: Colors.white, // Set card color to white
              elevation: 8.0,
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _cigarettesPerDayController,
                      decoration: InputDecoration(
                        labelText: 'Cigarettes smoked per day',
                        labelStyle: TextStyle(color: Colors.blueAccent),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0), // Thicker line when focused
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    TextFormField(
                      controller: _pricePerPackController,
                      decoration: InputDecoration(
                        labelText: 'Price of a pack',
                        labelStyle: TextStyle(color: Colors.blueAccent),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    TextFormField(
                      controller: _cigarettesPerPackController,
                      decoration: InputDecoration(
                        labelText: 'Number of cigarettes per pack',
                        labelStyle: TextStyle(color: Colors.blueAccent),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    // Dropdown for currency selection
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select Currency',
                        labelStyle: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                          iconSize: 28,
                          elevation: 16,
                          style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                          dropdownColor: Colors.white,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCurrency = newValue!;
                            });
                          },
                          items: _currencies.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: () => _selectDateTime(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blueAccent, // Button color
                      ),
                      child: Text(_selectedDateTime == null
                          ? 'Select Date and Time'
                          : '${_selectedDateTime!.toLocal()}'.split(' ')[0] + ' ' + TimeOfDay.fromDateTime(_selectedDateTime!).format(context)),
                    ),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blueAccent, // Button color
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Let\'s Go'),
                    ),
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          _message,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
