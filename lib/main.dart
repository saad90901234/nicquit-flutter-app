import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'userprogressscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase Initialized Successfully");
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashScreenTimer();
  }

  void _startSplashScreenTimer() {
    // Display the splash screen for 2 seconds before checking login status
    Future.delayed(Duration(seconds: 2), _checkLoginStatus);
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if "Remember me" is selected
    bool rememberMe = prefs.getBool('rememberMe') ?? false;

    print('rememberMe: $rememberMe');

    // Navigate based on the "Remember me" preference only
    if (rememberMe) {
      print("Navigating to UserProgressScreen");
      _navigateToUserProgress();
    } else {
      print("Navigating to LoginScreen");
      _navigateToLogin();
    }
  }

  void _navigateToUserProgress() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserProgressScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  // Call this method when the user successfully logs in
  void _setLoginSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', true); // Save "Remember me" preference
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1c92d2), // primary color
      body: Center(
        child: Text(
          'NICQUIT',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFFf2fcfe), // secondary color
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
