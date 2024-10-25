import 'dart:convert'; // For encoding and decoding JSON
import 'dart:ui'; // For backdrop filter (glass effect)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CravingDataScreen extends StatefulWidget {
  const CravingDataScreen({Key? key}) : super(key: key);

  @override
  _CravingDataScreenState createState() => _CravingDataScreenState();
}

class _CravingDataScreenState extends State<CravingDataScreen> {
  // Optional inputs (mood, physical activity, caffeine/alcohol)
  String _selectedMood = 'Neutral'; // Default mood
  bool _hadPhysicalActivity = false;
  bool _hadCaffeineOrAlcohol = false;
  bool _usedNRT = false; // NRT usage
  String _sleepQuality = 'Good'; // Sleep Quality (Good, Average, Poor)
  String _physicalLocation = 'Home'; // Physical location (Home, Work, Social)
  String _socialEnvironment = 'Alone'; // Social environment (Alone, With Others)

  double _stressLevel = 1; // Stress level using slider
  bool _isLoading = false;

  // Mood options with emojis
  final List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😃', 'label': 'Happy'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😟', 'label': 'Anxious'},
  ];

  // Method to submit craving data and call the API
  Future<void> _submitData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('No user is currently signed in.');
      return;
    }

    final String uid = user.uid;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data for API call
      Map<String, dynamic> userInput = {
        "stressLevel": _stressLevel.toInt(),
        "mood": _selectedMood == 'Happy'
            ? 0
            : _selectedMood == 'Neutral'
            ? 1
            : _selectedMood == 'Sad'
            ? 2
            : 3,
        "physicalActivity": _hadPhysicalActivity ? 1 : 0,
        "caffeineOrAlcohol": _hadCaffeineOrAlcohol ? 1 : 0,
        "sleepQuality": _sleepQuality == 'Good'
            ? 0
            : _sleepQuality == 'Average'
            ? 1
            : 2,
        "physicalLocation": _physicalLocation == 'Home'
            ? 0
            : _physicalLocation == 'Work'
            ? 1
            : 2,
        "socialEnvironment": _socialEnvironment == 'Alone' ? 0 : 1,
        "usedNRT": _usedNRT ? 1 : 0,
      };

      // Send data to API
      final response = await http.post(
        Uri.parse('https://nicquit-58d5b5a9ba36.herokuapp.com/predict'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userInput),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> prediction = jsonDecode(response.body);
        final double cravingStrength = prediction['cravingStrength'];
        final int relapseProbability = prediction['relapseProbability'];

        // Show the prediction in a dialog box
        _showPredictionDialog(context, cravingStrength, relapseProbability);

        // Save the data to Firestore after showing the dialog
        await FirebaseFirestore.instance
            .collection('cravingPredictions')
            .doc(uid) // This ensures the data is stored against the user UID
            .collection(
            'predictions') // Sub-collection for storing multiple predictions
            .add({
          'timestamp': DateTime.now(),
          'cravingStrength': cravingStrength,
          'relapseProbability': relapseProbability == 1
              ? 'High Risk'
              : 'Low Risk',
        });
      } else {
        _showErrorDialog('Failed to get prediction');
      }
    } catch (e) {
      _showErrorDialog('Error saving data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  // Method to show prediction dialog
  void _showPredictionDialog(BuildContext context, double cravingStrength,
      int relapseProbability) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            title: Text(
              'Prediction Results',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Craving Strength: ${cravingStrength.toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Relapse Probability: ${relapseProbability == 1
                      ? 'High Risk'
                      : 'Low Risk'}',
                  style: TextStyle(
                      color: relapseProbability == 1 ? Colors.red : Colors
                          .green,
                      fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
    );
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Log Your Craving',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Color(0xFF73AEF5),
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
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
        child: ListView(
          children: [
            SizedBox(height: 20.0),

            // Other Widgets inside the ListView...
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stress level indicator using slider
                        Text(
                          'Stress Level: ${_stressLevel.toInt()}',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Slider(
                          value: _stressLevel,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withOpacity(0.3),
                          onChanged: (value) {
                            setState(() {
                              _stressLevel = value;
                            });
                          },
                        ),
                        SizedBox(height: 20.0),

                        // Mood selector with emojis
                        Center(
                          child: Column(
                            children: [
                              Text('How do you feel?',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white.withOpacity(0.8))),
                              SizedBox(height: 10.0),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 20.0,
                                children: _moodOptions.map((mood) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMood = mood['label'];
                                      });
                                    },
                                    child: Column(
                                      children: [
                                        Text(
                                          mood['emoji'],
                                          style: TextStyle(
                                            fontSize: 30.0,
                                            color: _selectedMood ==
                                                mood['label']
                                                ? Colors.yellow
                                                : Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                        SizedBox(height: 5.0),
                                        Text(
                                          mood['label'],
                                          style: TextStyle(
                                            fontWeight: _selectedMood ==
                                                mood['label']
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color:
                                            Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.0),

                        // Physical activity switch with icon
                        SwitchListTile(
                          title: Row(
                            children: [
                              Icon(Icons.fitness_center,
                                  color: Colors.white.withOpacity(0.8)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Engaged in physical activity?',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                          value: _hadPhysicalActivity,
                          onChanged: (bool value) {
                            setState(() {
                              _hadPhysicalActivity = value;
                            });
                          },
                          activeColor: Colors.white,
                        ),
                        SizedBox(height: 10.0),

                        // Caffeine or alcohol switch with icon
                        SwitchListTile(
                          title: Row(
                            children: [
                              Icon(Icons.local_drink,
                                  color: Colors.white.withOpacity(0.8)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Consumed caffeine or alcohol?',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                          value: _hadCaffeineOrAlcohol,
                          onChanged: (bool value) {
                            setState(() {
                              _hadCaffeineOrAlcohol = value;
                            });
                          },
                          activeColor: Colors.white,
                        ),
                        SizedBox(height: 10.0),

                        // NRT usage switch
                        SwitchListTile(
                          title: Row(
                            children: [
                              Icon(Icons.medical_services,
                                  color: Colors.white.withOpacity(0.8)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Used Nicotine Replacement Therapy (NRT)?',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                          value: _usedNRT,
                          onChanged: (bool value) {
                            setState(() {
                              _usedNRT = value;
                            });
                          },
                          activeColor: Colors.white,
                        ),
                        SizedBox(height: 10.0),

                        // Sleep Quality dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Sleep Quality',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.bedtime,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                          dropdownColor: Colors.blue,
                          value: _sleepQuality,
                          items: ['Good', 'Average', 'Poor']
                              .map((quality) =>
                              DropdownMenuItem(
                                child: Text(quality,
                                    style: TextStyle(color: Colors.white)),
                                value: quality,
                              ))
                              .toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _sleepQuality = value ?? 'Good';
                            });
                          },
                          style: TextStyle(color: Colors.white),
                        ),

                        SizedBox(height: 10.0),

                        // Physical Location dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Physical Location',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.location_on,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                          dropdownColor: Colors.blue,
                          value: _physicalLocation,
                          items: ['Home', 'Work', 'Social']
                              .map((location) =>
                              DropdownMenuItem(
                                child: Text(location,
                                    style: TextStyle(color: Colors.white)),
                                value: location,
                              ))
                              .toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _physicalLocation = value ?? 'Home';
                            });
                          },
                          style: TextStyle(color: Colors.white),
                        ),

                        SizedBox(height: 10.0),

                        // Social Environment dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Social Environment',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.people,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                          dropdownColor: Colors.blue,
                          value: _socialEnvironment,
                          items: ['Alone', 'With Others']
                              .map((environment) =>
                              DropdownMenuItem(
                                child: Text(environment,
                                    style: TextStyle(color: Colors.white)),
                                value: environment,
                              ))
                              .toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _socialEnvironment = value ?? 'Alone';
                            });
                          },
                          style: TextStyle(color: Colors.white),
                        ),

                        SizedBox(height: 20.0),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitData,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15.0),
                              backgroundColor: Color(0xFF1c92d2),
                              shadowColor: Colors.blueAccent.withOpacity(0.5),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                              'Save Craving Data',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
