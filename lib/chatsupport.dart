import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Text controller for input field
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    addBotMessage("How can I assist you today?");
  }

  // Method to add bot message
  void addBotMessage(String message) {
    setState(() {
      messages.add({"message": message, "isMe": false});
    });
  }

  // Method to add user message
  void addUserMessage(String message) {
    setState(() {
      messages.add({"message": message, "isMe": true});
    });
  }


  // Method to store user messages to Firestore
  Future<void> storeMessageToFirestore(String message, String username) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // checking if the user already has a document in the 'support' collection
        QuerySnapshot userDoc = await FirebaseFirestore.instance
            .collection('support')
            .where('userUID', isEqualTo: user.uid)
            .get();

        DocumentReference userDocRef;

        if (userDoc.docs.isEmpty) {
          // If no document exists, create a new one with userUID and username
          userDocRef = await FirebaseFirestore.instance.collection('support').add({
            'userUID': user.uid,
            'username': username,
          });
        } else {
          // If the document exists, use the existing document reference
          userDocRef = userDoc.docs.first.reference;
        }

        // Store the message in the messages sub-collection
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

  // Method to send message
  void onSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Fetch the username from Firestore (asynchronous call)
    String username = await getUsernameForCurrentUser();

    addUserMessage(message);  // Add the message to the chat UI
    storeMessageToFirestore(message, username);  // Store the message in Firestore

    // Clear the message input field after sending
    _messageController.clear();
  }

  // get username
  Future<String> getUsernameForCurrentUser() async {
    User? user = _auth.currentUser;  // Get the current logged-in user
    if (user != null) {
      try {
        // Access the 'users' collection and fetch the document with the current user's UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          // Return the username from the document, if it exists
          return userDoc['username'] ?? 'Unknown';
        }
      } catch (e) {
        print("Error fetching username: $e");
      }
    }

    return 'Unknown';  // Fallback in case no user is found or error occurs
  }

  Stream<QuerySnapshot> fetchMessages() async* {
    User? user = _auth.currentUser;

    if (user != null) {
      // Step 1: Query to find the document with the matching userUID
      QuerySnapshot supportDocSnapshot = await FirebaseFirestore.instance
          .collection('support')
          .where('userUID', isEqualTo: user.uid)
          .get();

      if (supportDocSnapshot.docs.isNotEmpty) {
        // Step 2: If a matching document is found, access the 'messages' sub-collection
        DocumentReference supportDocRef = supportDocSnapshot.docs.first.reference;

        // Fetch the messages from the 'messages' sub-collection
        yield* supportDocRef.collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots();
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support'),
        backgroundColor: Color(0xFF1c92d2),
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
          children: <Widget>[
            // Fetch messages from Firestore and display them in a ListView
            Expanded(
              child: StreamBuilder(
                stream: fetchMessages(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No messages yet.'));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData = messages[index];
                      String messageText = messageData['message'] ?? '';
                      bool isMe = messageData['isMe'] ?? false;
                      Timestamp? timestamp = messageData['timestamp'];

                      // Format the timestamp to show date and time
                      String formattedTime = timestamp != null
                          ? DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate())
                          : 'Unknown time';

                      return buildChatBubble(messageText, isMe, formattedTime);
                    },
                  );
                },
              ),
            ),
            // Input field and send button for user to send messages
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
                        onSubmitted: (message) => onSendMessage(message), // Send message on enter
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      // Send message using the send button
                      onSendMessage(_messageController.text);
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1c92d2), Color(0xFF6dd5ed)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
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

  // Chat bubble widget to display messages
// Chat bubble widget to display messages with timestamp
  Widget buildChatBubble(String message, bool isMe, String formattedTime) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[200] : Colors.white,
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
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment
              .start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            Text(
              formattedTime,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
