import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';  // Import login screen
import 'datasmoke.dart';  // Import DataSmoking screen

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isUsernameTyped = false;
  bool _isPasswordTyped = false;
  bool _isLoadingUsername = false;
  bool _isLoadingPassword = false;
  String _oldPassword = '';
  String _newPassword = '';
  String _username = '';
  bool _isOldPasswordCorrect = false;  // Track if old password is correct

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _passwordController = TextEditingController(); // Controller for the password field

  // Function to check if the username already exists in Firestore
  Future<bool> _checkUsernameExists(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return result.docs.isNotEmpty;
  }

  // Function to simulate loading for username and update in Firestore
  Future<void> _startUsernameLoading() async {
    setState(() {
      _isLoadingUsername = true;
    });

    if (await _checkUsernameExists(_username)) {
      _showErrorDialog('Username already exists');
    } else {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({'username': _username});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Username updated successfully!')));
      }
    }

    setState(() {
      _isLoadingUsername = false;
    });
  }

  // Function to simulate loading for password change
  // Function to update password
  Future<void> _startPasswordLoading() async {
    setState(() {
      _isLoadingPassword = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Re-authenticate user with the old password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPassword,
        );
        await user.reauthenticateWithCredential(credential);

        setState(() {
          _isOldPasswordCorrect = true;
        });

        // Clear the text fields for both old and new passwords when the button is pressed
        _passwordController.clear();

        // Don't check the new password if it's empty
        if (_newPassword.isEmpty) {
          setState(() {
            _isLoadingPassword = false;
          });
          return;
        }

        // Check if the new password is at least 8 characters long
        if (_newPassword.length < 8) {
          _showErrorDialog('Password must be at least 8 characters long.');
        } else if (_newPassword == _oldPassword) {
          _showErrorDialog('New password cannot be the same as the old password.');
        } else {
          // Update to new password
          await user.updatePassword(_newPassword);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated successfully!')));

          // Reset the UI to ask for old password again after success
          setState(() {
            _isOldPasswordCorrect = false;  // Reset old password check
            _oldPassword = '';  // Reset old password
            _newPassword = '';  // Reset new password
            _isPasswordTyped = false;  // Reset arrow button visibility
          });
        }
      } catch (e) {
        // Error when old password doesn't match
        _showErrorDialog('Old password is incorrect.');
        setState(() {
          _isOldPasswordCorrect = false;  // Reset old password correct flag
        });
      }
    }

    // Clear the text fields for both old and new passwords when the button is pressed (after any action)
    _passwordController.clear();

    setState(() {
      _isLoadingPassword = false;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Clear the session flags
    await prefs.clear(); // Alternatively, you can just remove specific flags like prefs.remove('isLoggedIn')

    // Navigate to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false, // Remove all previous routes
    );
  }



  // Error dialog
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xff1c92d2)),
          onPressed: () {
            Navigator.pop(context); // Go back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Change Username Field
            Text(
              "Change Username",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  _username = value;
                  _isUsernameTyped = value.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter new username',
                hintStyle: TextStyle(color: Colors.black38),
                suffixIcon: _isLoadingUsername
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xff1c92d2),
                    strokeWidth: 2,
                  ),
                )
                    : IconButton(
                  icon: Icon(
                    _isUsernameTyped ? Icons.arrow_forward : Icons.person_outline,
                    color: Color(0xff1c92d2),
                  ),
                  onPressed: _isUsernameTyped ? _startUsernameLoading : null,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff1c92d2)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff1c92d2)),
                ),
              ),
            ),
            SizedBox(height: 40),

            // Change Password Field
            Text(
              "Change Password",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextField(
              controller: _passwordController,  // Link controller
              obscureText: true,
              onChanged: (value) {
                if (!_isOldPasswordCorrect) {
                  setState(() {
                    _oldPassword = value;
                    _isPasswordTyped = value.isNotEmpty; // Update arrow icon when typing
                  });
                } else {
                  setState(() {
                    _newPassword = value;
                    _isPasswordTyped = value.isNotEmpty; // Update arrow icon when typing
                  });
                }
              },
              decoration: InputDecoration(
                hintText: _isOldPasswordCorrect ? 'Enter new password' : 'Enter old password',
                hintStyle: TextStyle(color: Colors.black38),
                suffixIcon: _isLoadingPassword
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xff1c92d2),
                    strokeWidth: 2,
                  ),
                )
                    : IconButton(
                  icon: Icon(
                    _isPasswordTyped ? Icons.arrow_forward : Icons.lock_outline,
                    color: Color(0xff1c92d2),
                  ),
                  onPressed: _isPasswordTyped || !_isOldPasswordCorrect ? _startPasswordLoading : null,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff1c92d2)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff1c92d2)),
                ),
              ),
            ),
            SizedBox(height: 40),

            // Relapsed text and Reset button
            Center(
              child: Column(
                children: [
                  Text(
                    "Relapsed? Reset your quit.",
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 10), // Space between text and button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DataSmoking()),  // Navigate to DataSmoking screen
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff1c92d2), // Blue button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      'Reset Quit',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Spacer to push logout button to bottom
            Spacer(),

            // Logout Button
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                onPressed: _logout,
                backgroundColor: Color(0xff1c92d2),
                child: Icon(Icons.logout, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
