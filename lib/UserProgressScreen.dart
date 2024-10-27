import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'community.dart';
import 'support.dart';
import 'achievements.dart';
import 'ecom.dart';
import 'package:nicquit/HealthImprovementsScreen.dart';

class UserProgressScreen extends StatefulWidget {
  const UserProgressScreen({Key? key}) : super(key: key);

  @override
  _UserProgressScreenState createState() => _UserProgressScreenState();
}

class _UserProgressScreenState extends State<UserProgressScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  String _username = '';
  DateTime _quitTime = DateTime.now();
  int _cigarettesPerDay = 0;
  double _pricePerPack = 0.0;
  int _cigarettesPerPack = 0;
  String _currency = '\$'; // Default to dollar symbol
  bool _isLoading = true;
  Timer? _timer;
  Duration _timeSinceQuit = Duration.zero;
  late AnimationController _controller;
  late Animation<double> _animation;

  _UserProgressScreenState() {
    _pageController = PageController();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(hours: 24),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final String uid = user.uid; // Use the uid instead of email

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc.data()?['username'] ?? '';
          _quitTime = DateTime.parse(userDoc.data()?['quitTime'] ?? DateTime.now().toIso8601String());
          _cigarettesPerDay = int.parse(userDoc.data()?['cigarettesPerDay'] ?? '0');
          _pricePerPack = double.parse(userDoc.data()?['pricePerPack'] ?? '0.0');
          _cigarettesPerPack = int.parse(userDoc.data()?['cigarettesPerPack'] ?? '0');
          _currency = userDoc.data()?['currency'] ?? '\$'; // Fetch the currency, default to dollar
          _timeSinceQuit = DateTime.now().difference(_quitTime);
          _isLoading = false;
        });
        _startTimer();
        _controller.repeat();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeSinceQuit = DateTime.now().difference(_quitTime);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  double get _progress {
    final int totalSeconds = _timeSinceQuit.inSeconds;
    final int maxSeconds = 24 * 60 * 60; // Number of seconds in a day
    return (totalSeconds % maxSeconds) / maxSeconds;
  }

  double get _moneySaved {
    double costPerCigarette = (_pricePerPack / _cigarettesPerPack).toDouble();
    return costPerCigarette * _cigarettesPerDay * _timeSinceQuit.inDays;
  }

  int get _lifeSaved {
    return (_cigarettesPerDay * 11 * _timeSinceQuit.inDays).toInt(); // Assuming 11 minutes per cigarette
  }

  int get _cigarettesUnsmoked {
    return _cigarettesPerDay * _timeSinceQuit.inDays;
  }

  double _calculateHealthProgress(double initial, double finalValue, Duration duration) {
    final totalSeconds = duration.inSeconds;
    double progress = initial + ((finalValue - initial) * (_timeSinceQuit.inSeconds.toDouble() / totalSeconds.toDouble()));
    return progress.clamp(0.0, 100.0); // Clamps the progress between 0 and 100
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);  // Navigate between pages
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1C92D2), // Start color
              Color(0xFFF2FCFE), // End color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: <Widget>[
                _buildMainPage(),
                CommunityScreen(),
                Achievements(),
                EcomScreen(),
                SupportSettingsScreen(),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
        child: GNav(
          gap: 8,
          backgroundColor: Colors.white,
          color: Colors.grey[800],
          activeColor: Colors.black,
          tabBackgroundColor: Colors.blue[100]!,
          padding: EdgeInsets.all(16),
          selectedIndex: _selectedIndex,
          onTabChange: _onItemTapped,
          tabs: [
            GButton(
              icon: Icons.home,
              text: 'Home',
            ),
            GButton(
              icon: Icons.chat,
              text: 'Chat',
            ),
            GButton(
              icon: Icons.celebration,
              text: 'Miles',
            ),
            GButton(
              icon: Icons.store,
              text: 'Store',
            ),
            GButton(
              icon: Icons.tips_and_updates,
              text: 'Support',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.0), // Add top spacing before the greeting
            _buildGreeting(),
            SizedBox(height: 25.0), // Additional spacing below the greeting
            _buildProgressCircle(),
            SizedBox(height: 30.0), // Spacing between circular bar and card
            ModernCard(
              cigarettesUnsmoked: _cigarettesUnsmoked,
              lifeSaved: '${(_lifeSaved / 1440).toStringAsFixed(0)} days', // Removing minutes from life saved
              moneySaved: '$_currency ${_moneySaved.toStringAsFixed(0)}',
            ),
            SizedBox(height: 40.0),
            _buildHealthImprovementsCard(context),
          ],
        ),
      ),
    );
  }


  Widget _buildGreeting() {
    return Row(
      children: [
        Text(
          'Welcome ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          _username,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }


  Widget _buildProgressCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer progress indicator with gradient
        SizedBox(
          width: 230,
          height: 230,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 12.0,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        // Inner ring for more complexity
        SizedBox(
          width: 200,
          height: 200,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 8.0,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        // BackdropFilter with blur effect only applied to this container
        ClipRRect(
          borderRadius: BorderRadius.circular(90), // Clip the blurred area to match the circle shape
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        // Gesture detector to show detailed time
        GestureDetector(
          onTap: () => _showDetailedTime(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text for the number of smoke-free days with darker vibrant color
              Text(
                '${_timeSinceQuit.inDays} DAYS',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white // Darker vibrant color applied
                ),
              ),
              SizedBox(height: 8),
              // Text for the time display with hours, minutes, seconds with darker vibrant color
              Text(
                '${(_timeSinceQuit.inHours % 24).toString().padLeft(2, '0')} : ${(_timeSinceQuit.inMinutes % 60).toString().padLeft(2, '0')} : ${(_timeSinceQuit.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                    color: Colors.white  // Darker vibrant color applied
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildHealthImprovementsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the HealthImprovementsScreen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HealthImprovementsScreen()),
        );
      },
      child: Card(
        elevation: 8, // Add elevation to the card
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Color(0xFF1c92d2), Color(0xFF81D4FA),],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Improvements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.white), // White icon
              ],
            ),
          ),
        ),
      ),
    );
  }




  void _showDetailedTime(BuildContext context) {
    // Calculate years and months
    final int totalDays = _timeSinceQuit.inDays;
    final int years = totalDays ~/ 365; // Calculate full years
    final int months = (totalDays % 365) ~/ 30; // Calculate full months from the remaining days
    final int days = totalDays % 30; // Calculate remaining days

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detailed Time Since Quit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Years: $years'),
              Text('Months: $months'),
              Text('Days: $days'),
              Text('Hours: ${_timeSinceQuit.inHours % 24}'),
              Text('Minutes: ${_timeSinceQuit.inMinutes % 60}'),
              Text('Seconds: ${_timeSinceQuit.inSeconds % 60}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}


class ModernCard extends StatefulWidget {
  final int cigarettesUnsmoked;
  final String lifeSaved;
  final String moneySaved;

  ModernCard({required this.cigarettesUnsmoked, required this.lifeSaved, required this.moneySaved});

  @override
  _ModernCardState createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> with SingleTickerProviderStateMixin {
  double _elevation = 5;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // Duration of the rotation animation
    );

    // Define the rotation animation from 0 to 1 (representing 0 to 360 degrees)
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Reset the animation when it completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Start the rotation animation
        _controller.forward();
      },
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.1415926535, // Rotate from 0 to 360 degrees
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 280, // Increased width for the card
          child: Card(
            elevation: _elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), // Rounded corners for a sleek look
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1c92d2), Color(0xFF81D4FA),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0), // Reduced padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _buildInfoRow(FontAwesomeIcons.smokingBan, 'Cigarettes Unsmoked', widget.cigarettesUnsmoked.toString()),
                  Divider(color: Colors.white60, thickness: 1),
                  _buildInfoRow(FontAwesomeIcons.heartbeat, 'Life Saved', widget.lifeSaved),
                  Divider(color: Colors.white60, thickness: 1),
                  _buildInfoRow(FontAwesomeIcons.moneyBillWave, 'Money Saved', widget.moneySaved),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FaIcon(icon, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18, // Increased font size for label
                fontWeight: FontWeight.w600, // Increased font weight for better readability
                letterSpacing: 0.5, // Adds a bit of spacing between letters for clarity
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        SizedBox(height: 4), // Slightly increased spacing
        Text(
          value,
          style: TextStyle(
            fontSize: 26, // Larger font size for value
            fontWeight: FontWeight.w800, // Bolder text for more impact
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 8,
                color: Colors.black38, // Slightly stronger shadow for better contrast
              ),
            ],
          ),
        ),
      ],
    );
  }
}
