import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'cravingscreen.dart';
import 'package:intl/intl.dart'; // For date formatting

class CravingListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user UID
    final userUID = FirebaseAuth.instance.currentUser?.uid;

    // If the userUID is null, show an error message or handle it gracefully
    if (userUID == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'AI-Powered Craving Log',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        body: Center(
          child: Text(
            'Error: User is not authenticated.',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI-Powered Craving Log', // Label for the app bar
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text for the app bar
          ),
        ),
        backgroundColor: Colors.transparent, // Transparent background for a sleek look
        elevation: 0, // Remove shadow for a flat design
        centerTitle: true, // Center the title text
        iconTheme: IconThemeData(
          color: Colors.white, // Set the back button color to white
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 20.0), // Adjust top padding since we now have an app bar
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cravingPredictions')
                    .doc(userUID) // Fetch the document by the user's UID
                    .collection('predictions') // Access the sub-collection for multiple predictions
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error fetching data: ${snapshot.error}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No cravings data available.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    );
                  }

                  final data = snapshot.data!.docs; // Fetch the data from the sub-collection

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      var cravingData = data[index];
                      String cravingStrength = cravingData['cravingStrength'].toString();
                      String relapseProbability = cravingData['relapseProbability'];
                      Timestamp timestamp = cravingData['timestamp'];
                      DateTime dateTime = timestamp.toDate();
                      String formattedTime = "${dateTime.hour}:${dateTime.minute} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";

                      // Formatting the date: Today, Yesterday, or the actual date
                      String displayDate = _getDisplayDate(dateTime);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: CravingCard(
                          cravingStrength: cravingStrength,
                          relapseProbability: relapseProbability,
                          time: formattedTime,
                          date: displayDate, // Pass the formatted date
                        ),
                      );
                    },
                  );
                },
              )
          ),
        ],
      ),
      // Floating Action Button for adding new data
      floatingActionButton: AnimatedPulseFab(), // Updated FAB with pulse animation
    );
  }

  // Method to determine if the date is Today, Yesterday, or older
  String _getDisplayDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      // Display the date in 'MMM d, yyyy' format for older dates
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}

class CravingCard extends StatelessWidget {
  final String cravingStrength;
  final String relapseProbability;
  final String time;
  final String date; // Add date

  CravingCard({
    required this.cravingStrength,
    required this.relapseProbability,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 1,
            offset: Offset(0, 10),
          )
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Craving Strength
          Text(
            'Craving Strength: $cravingStrength',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          // Risk of Relapse
          Text(
            'Risk of Relapse: $relapseProbability',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 18,
            ),
          ),
          SizedBox(height: 12),
          // Time and Date
          Text(
            'Time: $time | Date: $date', // Display time and date
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Floating Action Button with pulse animation
class AnimatedPulseFab extends StatefulWidget {
  @override
  _AnimatedPulseFabState createState() => _AnimatedPulseFabState();
}

class _AnimatedPulseFabState extends State<AnimatedPulseFab> with SingleTickerProviderStateMixin {
  // Proper declaration of AnimationController and Animation
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController and define duration
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true); // Repeats the animation in reverse after it completes

    // Define the animation (scaling effect)
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed from the widget tree
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: FloatingActionButton(
            onPressed: () {
              // Navigate to the CravingDataScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CravingDataScreen()),
              );
            },
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 36),
            ),
            elevation: 0,
          ),
        );
      },
    );
  }
}