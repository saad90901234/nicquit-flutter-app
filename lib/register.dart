import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // Import the login screen

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegistering = false;
  String _registerMessage = '';

  Future<bool> checkUserExists(String username, String email) async {
    try {
      // Check if username already exists
      QuerySnapshot<Map<String, dynamic>> users = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (users.docs.isNotEmpty) {
        _showErrorDialog('Username already exists');
        return true;
      }

      // Check if email already exists
      users = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (users.docs.isNotEmpty) {
        _showErrorDialog('Email already exists');
        return true;
      }

      return false;
    } catch (e) {
      _showErrorDialog('Error checking user existence: $e');
      return true; // Assuming user exists if there's an error
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      setState(() {
        _isRegistering = true; // Start progress indicator
      });

      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      // Show the success dialog with the verification email message
      _showSuccessDialog('Verification email sent! Please check your inbox.');

      setState(() {
        _isRegistering = false;
      });

      // Once verified, add user to Firestore
      String uid = userCredential.user!.uid;
      await addUserToFirestore(username, email, uid);

      setState(() {
        _registerMessage = 'Registration successful!';
      });

    } catch (e) {
      setState(() {
        _isRegistering = false; // Stop progress indicator on error
      });
      _showErrorDialog('Registration failed: $e');
    }
  }


  Future<void> addUserToFirestore(String username, String email, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'uid': uid, // Store the UID in Firestore
      });
    } catch (e) {
      print("Error: $e");
      _showErrorDialog('Failed to add user to Firestore: $e');
    }
  }

  void _registerUser(String username, String email, String password) {
    if (_validateFields()) {
      checkUserExists(username, email).then((exists) {
        if (!exists) {
          registerWithEmailAndPassword(email, password, username); // Pass username as well
        } else {
          setState(() {
            _isRegistering = false; // Stop progress indicator if user exists
          });
        }
      });
    }
  }

  bool isPasswordValid(String password) {
    return password.length >= 8;
  }

  bool isEmailValid(String email) {
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$',
    );
    return emailRegExp.hasMatch(email);
  }

  bool _validateFields() {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('All fields are mandatory');
      return false;
    }
    if (!isEmailValid(_emailController.text)) {
      _showErrorDialog('Please enter a valid email address');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF73AEF5), // Set AppBar color
        elevation: 0, // Remove the shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Back button
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Login()), // Navigate to the login screen
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height, // Set height to full screen
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF73AEF5),
                Color(0xFF61A4F1),
                Color(0xFF478DE0),
                Color(0xFF398AEF),
              ],
              stops: [0.1, 0.4, 0.7, 0.9],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35), // Align with text fields
                child: Text(
                  'Create\nAccount',
                  style: TextStyle(color: Colors.white, fontSize: 33, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 60), // Adjust this space for better alignment
              Container(
                margin: EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _usernameController,
                      hintText: "Username",
                    ),
                    SizedBox(height: 30),
                    _buildTextField(
                      controller: _emailController,
                      hintText: "Email",
                    ),
                    SizedBox(height: 30),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: "Password",
                      obscureText: true,
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _isRegistering
                            ? CircularProgressIndicator(color: Colors.white) // Show progress indicator while registering
                            : CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            color: Colors.black,
                            onPressed: () {
                              String username = _usernameController.text;
                              String email = _emailController.text;
                              String password = _passwordController.text;

                              if (isPasswordValid(password)) {
                                _registerUser(username, email, password);
                              } else {
                                _showErrorDialog('Password must be at least 8 characters long');
                              }
                            },
                            icon: Icon(Icons.arrow_forward),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 10),
                    if (_registerMessage.isNotEmpty)
                      Text(
                        _registerMessage,
                        style: TextStyle(color: Colors.white),
                      ),
                    SizedBox(height: 50), // Space at the bottom to avoid overlap with keyboard
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.withOpacity(0.5), // Background color for the text field
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color.fromRGBO(232, 170, 84, 1.0),
          ),
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
