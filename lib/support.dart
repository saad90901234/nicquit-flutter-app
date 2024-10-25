import 'package:flutter/material.dart';
import 'settings.dart';
import 'chatsupport.dart';
import 'package:nicquit/cravinglist.dart';

class SupportSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Support & Settings',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 22,
            color: Colors.white, // White app bar title
          ),
        ),
        backgroundColor: Color(0xFF1c92d2), // Custom color
        elevation: 0, // Flat AppBar for a clean modern look
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFf2fcfe),
              Color(0xFF1c92d2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSupportCard(
                context,
                icon: Icons.support_agent_outlined,
                title: 'Chat Support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen()),
                  );
                },
              ),
              SizedBox(height: 16),
              _buildSupportCard(
                context,
                icon: Icons.monitor_heart_outlined,
                title: 'Craving Monitor',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CravingListScreen()),
                  );
                },
              ),
              SizedBox(height: 16),
              _buildSupportCard(
                context,
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 10, // Higher elevation for stronger shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Larger radius for smoother corners
      ),
      shadowColor: Colors.black26,
      color: Colors.white.withOpacity(0.8), // Slight transparency for sleek look
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFf2fcfe).withOpacity(0.5),
                Color(0xFFf2fcfe),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1c92d2).withOpacity(0.1),
                    ),
                    child: Icon(
                      icon,
                      color: Color(0xFF1c92d2),
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
