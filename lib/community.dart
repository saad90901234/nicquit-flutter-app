import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  late Stream<QuerySnapshot> _messagesStream;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _messagesStream = _firestore.collection('messages').orderBy('timestamp', descending: true).snapshots();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));

    // Observe app lifecycle changes to detect when the app is resumed
    WidgetsBinding.instance.addObserver(this);
    _checkIfAppClosedAndReopened();
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);  // Remove lifecycle observer
    super.dispose();
  }

  // Check app lifecycle to determine if it has been closed and reopened
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has been resumed, check if it should show the community guidelines
      _checkIfAppClosedAndReopened();
    }
  }

  // Function to check if the app was completely closed and reopened
  Future<void> _checkIfAppClosedAndReopened() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenGuidelines = prefs.getBool('hasSeenGuidelines') ?? false;

    if (!hasSeenGuidelines) {
      // Show guidelines if not seen and set flag that they have been shown this session
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCommunityGuidelinesDialog();
      });
    }
  }

  // Function to update the user's activity timestamp in Firestore
  Future<void> _updateUserActivity() async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Function to get the active user count based on recent activity
  Stream<int> _getActiveUserCount() {
    return _firestore
        .collection('users')
        .where('lastActive',
        isGreaterThan:
        Timestamp.now().toDate().subtract(Duration(minutes: 5)))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.length;
    });
  }

  // Function to get a username by user ID (uid)
  Future<String> _getUsernameById(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
    await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['username'] ?? 'Unknown';
  }

  // Function to show the community guidelines dialog
  void _showCommunityGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Icon(Icons.group, color: Color(0xFF1c92d2)),
              SizedBox(width: 10),
              Text(
                "Community Guidelines",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1c92d2),
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We’re excited to have you here! Our goal is to create a supportive, positive, and smoke-free community. Please keep the following in mind:",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 20),
                _buildGuidelineItem(
                  icon: Icons.share,
                  title: "Share Your Journey",
                  description:
                  "Open up about your experiences, challenges, and victories in quitting smoking. Your story could inspire others.",
                ),
                SizedBox(height: 15),
                _buildGuidelineItem(
                  icon: Icons.help_outline,
                  title: "Seek and Offer Support",
                  description:
                  "Don’t hesitate to ask for help when you need it. Likewise, offer support to fellow members who are on their journey.",
                ),
                SizedBox(height: 15),
                _buildGuidelineItem(
                  icon: Icons.sentiment_satisfied_alt,
                  title: "Stay Respectful",
                  description:
                  "Keep interactions friendly and respectful. Any form of harmful language, racism, or abuse will lead to account suspension.",
                ),
                SizedBox(height: 15),
                _buildGuidelineItem(
                  icon: Icons.block,
                  title: "Zero Tolerance Policy",
                  description:
                  "We have a zero-tolerance policy for harassment, hate speech, or offensive behavior. Violations will result in immediate account suspension.",
                ),
                SizedBox(height: 20),
                Text(
                  "Let’s work together to create a positive, smoke-free space!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1c92d2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  child: Text(
                    "Got it!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasSeenGuidelines', true); // Set flag so guidelines are not shown again during the session

                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuidelineItem(
      {required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFF1c92d2), size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String messageText = _controller.text;
      _controller.clear(); // Clear the text field

      await _updateUserActivity(); // Update user's last activity

      DocumentReference docRef = await _firestore.collection('messages').add({
        'text': messageText,
        'senderId': _user?.uid ?? 'Unknown', // Use uid instead of email
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sending',
      });

      try {
        // Simulate delivery confirmation
        await Future.delayed(Duration(seconds: 1));
        await docRef.update({'status': 'delivered'});
      } catch (e) {
        await docRef.update({'status': 'error'});
      }

      _animationController.forward().then((_) => _animationController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false, // Remove default back button
            backgroundColor: Color(0xFF1c92d2),
            elevation: 0,
            titleSpacing: 0, // Ensure the title starts at the leading position
            title: Padding(
              padding: const EdgeInsets.only(left: 16.0), // Adjust if needed
              child: Text(
                'Community',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            centerTitle: false, // Ensure the title is on the left
            actions: [
              IconButton(
                icon: Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showCommunityGuidelinesDialog,
              ),
              StreamBuilder<int>(
                stream: _getActiveUserCount(),
                builder: (context, snapshot) {
                  int activeUserCount = snapshot.data ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.group, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          '$activeUserCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16, // Adjust to match icon size
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          )
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // To show the latest message at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageData = message.data() as Map<String, dynamic>;
                    final messageText = messageData['text'] ??
                        ''; // Default to empty string if text is null
                    final senderId = messageData['senderId'] ??
                        'Unknown'; // Use senderId (uid) instead of email
                    final messageStatus = messageData['status'] ?? 'sending';

                    final isSentByUser = senderId == _user?.uid;

                    return FutureBuilder<String>(
                      future: _getUsernameById(senderId),
                      // Fetch the username from Firestore using uid
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final messageSender = snapshot.data ?? 'Unknown';

                        return ChatBubble(
                          text: messageText,
                          isSentByUser: isSentByUser,
                          sender: messageSender,
                          status: messageStatus,
                          messageId: message.id,
                          // Pass messageId here (Firestore's document ID)
                          senderId: senderId, // Pass senderId here
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromRGBO(230, 240, 255, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Type a message...',
                      hintStyle:
                      TextStyle(color: Color.fromRGBO(150, 150, 150, 1)),
                    ),
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + 0.1 * _animationController.value,
                      child: ElevatedButton(
                        onPressed: _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(33, 150, 243, 1),
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(12.0),
                          elevation: 5,
                        ),
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSentByUser;
  final String sender;
  final String status;
  final String messageId; // Add this to pass message ID for reporting
  final String senderId; // Add sender's ID to report the user

  ChatBubble({
    required this.text,
    required this.isSentByUser,
    required this.sender,
    required this.status,
    required this.messageId,
    required this.senderId, // Add sender's ID
  });

  void _reportMessage(BuildContext context) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? _user = _auth.currentUser;

    // Store the report in the Firestore 'reports' collection
    if (_user != null) {
      await _firestore.collection('reports').add({
        'reportedBy': _user.uid,
        'reportedMessage': text,
        'reportedMessageId': messageId,
        'reportedUserId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message reported')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Column(
          crossAxisAlignment:
              isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isSentByUser)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 250),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(230, 240, 255, 1),
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              '@$sender',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Divider(
                            thickness: 1.0,
                            color: Colors.grey[300],
                            height: 1.0,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Report') {
                        _reportMessage(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'Report',
                        child: Text('Report'),
                      ),
                    ],
                    icon: Icon(Icons.more_vert),
                  ),
                ],
              ),
            if (isSentByUser)
              Container(
                constraints: BoxConstraints(maxWidth: 250),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(33, 150, 243, 0.2),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            if (isSentByUser)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'sending') AnimatedDots(),
                    if (status == 'delivered')
                      Icon(Icons.done_all, color: Colors.blueGrey, size: 16.0),
                    if (status == 'error')
                      Icon(Icons.error, color: Colors.red, size: 16.0),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AnimatedDots extends StatefulWidget {
  @override
  _AnimatedDotsState createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            SizedBox(width: 2),
            _buildDot(1),
            SizedBox(width: 2),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final animationValue = _animation.value;
    final opacity = (index == 0
            ? animationValue
            : index == 1
                ? animationValue - 0.33
                : animationValue - 0.66)
        .clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
