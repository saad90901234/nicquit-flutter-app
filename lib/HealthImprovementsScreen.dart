import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HealthImprovementsScreen extends StatefulWidget {
  const HealthImprovementsScreen({Key? key}) : super(key: key);

  @override
  _HealthImprovementsScreenState createState() => _HealthImprovementsScreenState();
}

class _HealthImprovementsScreenState extends State<HealthImprovementsScreen> {
  DateTime _quitTime = DateTime.now();
  bool _isLoading = true;
  int completedMilestones = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _quitTime = DateTime.parse(userDoc.data()?['quitTime'] ?? DateTime.now().toIso8601String());
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  double _calculateHealthProgress(Duration milestoneDuration) {
    final timeSinceQuit = DateTime.now().difference(_quitTime);
    final progress = (timeSinceQuit.inSeconds / milestoneDuration.inSeconds).clamp(0.0, 1.0);
    return progress * 100;
  }

  void _showHealthDetailDialog(String description, String durationText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.access_time, color: Color(0xFF1c92d2)),
              SizedBox(width: 8),
              Text(durationText),
            ],
          ),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close", style: TextStyle(color: Color(0xFF1c92d2))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> healthData = [
      {
        'text': 'Your heart rate and blood pressure drop',
        'duration': Duration(minutes: 20),
        'description': 'Your heart rate and blood pressure drop to normal levels.',
        'durationText': '20 minutes',
        'icon': FontAwesomeIcons.heartbeat
      },
      {
        'text': 'The carbon monoxide level in your blood drops to normal',
        'duration': Duration(hours: 8),
        'description': 'The carbon monoxide level in your blood returns to normal.',
        'durationText': '8 hours',
        'icon': FontAwesomeIcons.smog
      },
      {
        'text': 'Your circulation improves and your lung function increases',
        'duration': Duration(days: 14),
        'description': 'Circulation improves and lung function increases significantly.',
        'durationText': '14 days',
        'icon': FontAwesomeIcons.lungs
      },
      {
        'text': 'Coughing and shortness of breath decrease',
        'duration': Duration(days: 30),
        'description': 'Coughing and shortness of breath decrease.',
        'durationText': '30 days',
        'icon': FontAwesomeIcons.wind
      },
      {
        'text': 'Your risk of coronary heart disease is about half that of a smoker\'s',
        'duration': Duration(days: 365),
        'description': 'Your risk of coronary heart disease reduces by half.',
        'durationText': '1 year',
        'icon': FontAwesomeIcons.heart
      },
      {
        'text': 'The stroke risk is that of a nonsmoker\'s',
        'duration': Duration(days: 5 * 365),
        'description': 'Your stroke risk becomes equivalent to that of a nonsmoker.',
        'durationText': '5 years',
        'icon': FontAwesomeIcons.brain
      },
      {
        'text': 'Your risk of lung cancer falls to about half that of a smoker',
        'duration': Duration(days: 10 * 365),
        'description': 'Your risk of lung cancer reduces significantly.',
        'durationText': '10 years',
        'icon': FontAwesomeIcons.radiation
      },
      {
        'text': 'The risk of coronary heart disease is that of a nonsmoker\'s',
        'duration': Duration(days: 15 * 365),
        'description': 'Your risk of coronary heart disease is similar to that of a nonsmoker.',
        'durationText': '15 years',
        'icon': FontAwesomeIcons.heartBroken
      },
    ];

    completedMilestones = 0;

    for (var data in healthData) {
      final double progress = _calculateHealthProgress(data['duration']);
      if (progress >= 100) {
        completedMilestones++;
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1c92d2), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Color(0xFF1c92d2),
              floating: true,
              pinned: true,
              iconTheme: IconThemeData(color: Colors.white),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Health Bar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.solidCheckCircle, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '$completedMilestones/8',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Health Journey',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...healthData.map((data) {
                      final double progress = _calculateHealthProgress(data['duration']);

                      return GestureDetector(
                        onTap: () {
                          _showHealthDetailDialog(data['description'], data['durationText']);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  data['icon'],
                                  color: Color(0xFF1c92d2),
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['text'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: Colors.grey[300],
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1c92d2)),
                                          minHeight: 14,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '${progress.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
