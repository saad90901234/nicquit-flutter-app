import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  // Predefined text suggestions for quitting smoking
  final List<String> predefinedSuggestions = [
    "How can I deal with cravings?",
    "What are some tips to stay motivated?",
    "Tell me about products to quit smoking.",
    "How can I stay on track with my quitting journey?"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quit Support Chat'),
        backgroundColor: Color(0xFF1c92d2),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: showEndChatDialog, // Show dialog to end chat
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: fetchMessages(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length + 1, // Add one for the static greeting message
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        // Static greeting message at the top
                        return buildChatBubble(
                          'Welcome to Nicquit Support! How can we help you quit smoking today?',
                          false, // isMe is false for admin
                          '', // No timestamp for the static message
                        );
                      }

                      final messageData = messages[index];
                      String messageText = messageData['message'] ?? '';
                      bool isMe = messageData['isMe'] ?? false;
                      Timestamp? timestamp = messageData['timestamp'];

                      String formattedTime = timestamp != null
                          ? DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate())
                          : 'Unknown time';

                      return buildChatBubble(messageText, isMe, formattedTime);
                    },
                  );
                },
              ),
            ),
            // Predefined Text Suggestions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: predefinedSuggestions.map((option) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () {
                        onSendMessage(option);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        margin: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          option,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Input Field and Send Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onSubmitted: (message) => onSendMessage(message),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      onSendMessage(_messageController.text);
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF1c92d2), Color(0xFF6dd5ed)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChatBubble(String message, bool isMe, String formattedTime) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[400] : Colors.white,
          borderRadius: isMe
              ? BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          )
              : BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              formattedTime,
              style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> fetchMessages() async* {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot supportDocSnapshot = await FirebaseFirestore.instance
          .collection('support')
          .where('userUID', isEqualTo: user.uid)
          .get();

      if (supportDocSnapshot.docs.isNotEmpty) {
        DocumentReference supportDocRef = supportDocSnapshot.docs.first.reference;
        yield* supportDocRef.collection('messages').orderBy('timestamp', descending: true).snapshots();
      }
    }
  }

  Future<void> onSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    String username = await getUsernameForCurrentUser();
    await storeMessageToFirestore(message, username);

    _messageController.clear();
  }

  Future<String> getUsernameForCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          return userDoc['username'] ?? 'Unknown';
        }
      } catch (e) {
        print("Error fetching username: $e");
      }
    }
    return 'Unknown';
  }

  Future<void> storeMessageToFirestore(String message, String username) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot userDoc = await FirebaseFirestore.instance
            .collection('support')
            .where('userUID', isEqualTo: user.uid)
            .get();

        DocumentReference userDocRef;

        if (userDoc.docs.isEmpty) {
          userDocRef = await FirebaseFirestore.instance.collection('support').add({
            'userUID': user.uid,
            'username': username,
          });
        } else {
          userDocRef = userDoc.docs.first.reference;
        }

        await userDocRef.collection('messages').add({
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isMe': true,
          'senderID': user.uid,
        });
      } catch (e) {
        print("Error storing message: $e");
      }
    }
  }

  void showEndChatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('End Chat'),
          content: Text('Are you sure you want to end this chat? This will delete all chat messages.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await deleteChatMessages();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Yes, End Chat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteChatMessages() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot supportDocSnapshot = await FirebaseFirestore.instance
            .collection('support')
            .where('userUID', isEqualTo: user.uid)
            .get();

        if (supportDocSnapshot.docs.isNotEmpty) {
          DocumentReference supportDocRef = supportDocSnapshot.docs.first.reference;
          QuerySnapshot messagesSnapshot = await supportDocRef.collection('messages').get();

          for (var doc in messagesSnapshot.docs) {
            await doc.reference.delete();
          }
        }
      } catch (e) {
        print("Error deleting messages: $e");
      }
    }
  }
}
