import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(NicquitApp());
}

class NicquitApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nicquit Achievement Screen',
      theme: ThemeData(
        primaryColor: Color(0xFF1c92d2),
        scaffoldBackgroundColor: Color(0xFFf2fcfe),
      ),
      home: Achievements(),
    );
  }
}

class Achievements extends StatefulWidget {
  @override
  _AchievementsState createState() => _AchievementsState();
}

class _AchievementsState extends State<Achievements> {
  DateTime _quitTime = DateTime.now();
  int _cigarettesPerDay = 0;
  double _pricePerPack = 0.0;
  int _cigarettesPerPack = 0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> achievements = [
    {'title': '1 Day Smoke-Free', 'subtitle': 'You\'ve completed your first smoke-free day!', 'requirement': 1, 'type': 'days'},
    {'title': '3 Days Smoke-Free', 'subtitle': 'Nicotine is leaving your body!', 'requirement': 3, 'type': 'days'},
    {'title': '1 Week Smoke-Free', 'subtitle': 'Your taste and smell have started improving.', 'requirement': 7, 'type': 'days'},
    {'title': '2 Weeks Smoke-Free', 'subtitle': 'Breathing becomes easier as lung function improves.', 'requirement': 14, 'type': 'days'},
    {'title': '1 Month Smoke-Free', 'subtitle': 'Blood circulation starts improving significantly.', 'requirement': 30, 'type': 'days'},
    {'title': '3 Months Smoke-Free', 'subtitle': 'Energy levels rise, lung health shows marked improvement.', 'requirement': 90, 'type': 'days'},
    {'title': '6 Months Smoke-Free', 'subtitle': 'Reduced coughing and shortness of breath.', 'requirement': 180, 'type': 'days'},
    {'title': '1 Year Smoke-Free', 'subtitle': 'You\'ve saved a significant amount of money!', 'requirement': 365, 'type': 'days'},
    {'title': '2 Years Smoke-Free', 'subtitle': 'Risk of heart disease decreases by 50%.', 'requirement': 2 * 365, 'type': 'days'},
    {'title': '1,000 Cigarettes Unsparked', 'subtitle': 'You’ve avoided a thousand cigarettes.', 'requirement': 1000, 'type': 'cigarettes'},
    {'title': '\$100 Saved', 'subtitle': 'You’ve saved \$100 by quitting smoking.', 'requirement': 100.0, 'type': 'money'},
    {'title': '\$500 Saved', 'subtitle': 'You’ve saved \$500!', 'requirement': 500.0, 'type': 'money'},
    {'title': '\$1,000 Saved', 'subtitle': 'A major financial milestone!', 'requirement': 1000.0, 'type': 'money'},
    {'title': 'Life Regained: 1 Day', 'subtitle': 'You\'ve added a full day back to your life expectancy.', 'requirement': 1440, 'type': 'life'},
    {'title': 'Life Regained: 1 Week', 'subtitle': 'You’ve gained back a week of your life.', 'requirement': 10080, 'type': 'life'},
    {'title': 'Life Regained: 1 Month', 'subtitle': 'You\'ve added a full month back to your life expectancy.', 'requirement': 43200, 'type': 'life'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String uid = user.uid; // Use uid instead of email

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          _quitTime = DateTime.parse(userDoc.data()?['quitTime'] ?? DateTime.now().toIso8601String());
          _cigarettesPerDay = int.parse(userDoc.data()?['cigarettesPerDay'] ?? '0');
          _pricePerPack = double.parse(userDoc.data()?['pricePerPack'] ?? '0.0');
          _cigarettesPerPack = int.parse(userDoc.data()?['cigarettesPerPack'] ?? '0');
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  int get daysSmokeFree => DateTime.now().difference(_quitTime).inDays;

  double get moneySaved {
    double costPerCigarette = _pricePerPack / _cigarettesPerPack;
    return costPerCigarette * _cigarettesPerDay * daysSmokeFree;
  }

  int get cigarettesUnsmoked => _cigarettesPerDay * daysSmokeFree;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate unlocked achievements
    int unlockedAchievementsCount = achievements.where((achievement) => _checkIfUnlocked(achievement)).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),  // Set title color to white
        ),
        backgroundColor: Color(0xFF1c92d2), // Change the app bar color to blue
        automaticallyImplyLeading: false, // Remove the back button
        actions: [
          // Achievement icon with count on the trailing side
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.white),
                SizedBox(width: 4.0),
                Text(
                  '$unlockedAchievementsCount / ${achievements.length}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                bool isUnlocked = _checkIfUnlocked(achievement);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AchievementCard(
                    title: achievement['title'],
                    subtitle: achievement['subtitle'],
                    isUnlocked: isUnlocked,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to check if an achievement is unlocked
  bool _checkIfUnlocked(Map<String, dynamic> achievement) {
    switch (achievement['type']) {
      case 'days':
        return daysSmokeFree >= achievement['requirement'];
      case 'cigarettes':
        return cigarettesUnsmoked >= achievement['requirement'];
      case 'money':
        return moneySaved >= achievement['requirement'];
      case 'life':
        int minutesGained = cigarettesUnsmoked * 11; // Assuming 11 minutes gained per cigarette
        return minutesGained >= achievement['requirement'];
      default:
        return false;
    }
  }
}

class AchievementCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isUnlocked;

  AchievementCard({required this.title, required this.subtitle, required this.isUnlocked});

  @override
  _AchievementCardState createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 3));
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: false); // Shimmer moves continuously from top-left to bottom-right
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Card content with shimmer
        _buildShimmeringCard(),
        if (!widget.isUnlocked) _buildLockedOverlay(), // Grey filter for locked achievements
      ],
    );
  }

  Widget _buildShimmeringCard() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),  // Fully transparent
                Colors.white.withOpacity(0.5),  // Mid-opacity for shimmer effect
                Colors.white.withOpacity(0.0),  // Fully transparent
              ],
              stops: [0.1, 0.5, 0.9],  // Control the shimmer spread
              begin: Alignment.topLeft,  // Starting point (top-left)
              end: Alignment.bottomRight,  // Ending point (bottom-right)
              transform: _createShimmerTransform(rect), // Movement of the gradient across the card
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: buildCardContent(),
        );
      },
    );
  }

  GradientTransform _createShimmerTransform(Rect rect) {
    return SlidingGradientTransform(slidePercent: _shimmerAnimation.value); // Moves gradient across diagonal path
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.6), // Grey overlay with some transparency
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

  Widget buildCardContent() {
    return Material(
      elevation: 8.0,
      borderRadius: BorderRadius.circular(16.0),
      color: Color(0xFF1c92d2),
      shadowColor: Colors.black.withOpacity(0.25),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement Icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(16.0),
              child: Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 48.0,
              ),
            ),
            SizedBox(height: 16.0),
            // Achievement Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.0),
            // Achievement Subtitle
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, bounds.height * slidePercent, 0.0);
  }
}
