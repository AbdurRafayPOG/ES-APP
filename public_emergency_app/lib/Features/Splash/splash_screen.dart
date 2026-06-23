import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/Responder/responder_dashboard.dart';
import 'package:public_emergency_app/Features/User/Screens/bottom_nav.dart';
import 'package:public_emergency_app/Features/Login/login_screen.dart';
import 'package:public_emergency_app/Common Widgets/Onboarding.dart';
import 'package:public_emergency_app/Features/Splash/loading_indicator.dart';
import 'package:public_emergency_app/Features/User/Controllers/call_controller.dart';
import 'package:public_emergency_app/Features/User/Screens/VoicenVideoCall/keys.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserTypeAndNavigate();
  }

  /// Initialize ZEGO for the logged-in user
  void _initializeZegoForUser(User user, String userType) {
    try {
      final CallController callController = Get.find<CallController>();
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      
      // Determine which node to fetch name from
      final String node = userType == 'responder' ? 'Responders' : 'Users';
      
      database
          .child(node)
          .child(user.uid)
          .get()
          .then((snapshot) {
            if (snapshot.value != null) {
              final data = Map<String, dynamic>.from(snapshot.value as Map);
              String userName = data['UserName']?.toString() ?? 
                                (userType == 'responder' ? 'Responder' : 'User');
              String userTypeValue = data['UserType']?.toString() ?? '';
              
              // Store user info
              Keys.userName = userName;
              Keys.userId = user.uid;
              
              if (userType == 'responder') {
                Keys.responderName = userName;
                Keys.responderType = userTypeValue;
              }
              
              // ✅ Initialize ZEGO ONCE - This will stay connected
              callController.initializeZego(user.uid, userName);
              callController.initializeCallInvitationService(user.uid, userName);
              
              print("✅ ZEGO initialized for $userType: $userName");
            } else {
              // Fallback if no data found
              String fallbackName = userType == 'responder' ? 'Responder' : 'User';
              Keys.userName = fallbackName;
              Keys.userId = user.uid;
              
              callController.initializeZego(user.uid, fallbackName);
              callController.initializeCallInvitationService(user.uid, fallbackName);
            }
          })
          .catchError((e) {
            // If name fetch fails, use fallback
            String fallbackName = userType == 'responder' ? 'Responder' : 'User';
            Keys.userName = fallbackName;
            Keys.userId = user.uid;
            
            callController.initializeZego(user.uid, fallbackName);
            callController.initializeCallInvitationService(user.uid, fallbackName);
          });
    } catch (e) {
      // Silent catch - ZEGO init will happen later if needed
      print("ZEGO initialization error: $e");
    }
  }

  Future<void> _checkUserTypeAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Get.offAll(() => const OnBoardingScreen());
      return;
    }

    try {
      final db = FirebaseDatabase.instance;
      final userRef = db.ref().child('Users').child(user.uid);
      final responderRef = db.ref().child('Responders').child(user.uid);

      // Check if user is a responder
      final responderSnapshot = await responderRef.get();
      if (responderSnapshot.value != null) {
        // ✅ Initialize ZEGO for responder (ONCE at login)
        _initializeZegoForUser(user, 'responder');
        Get.offAll(() => const ResponderDashboard());
        return;
      }

      // Check if user is a regular user
      final userSnapshot = await userRef.get();
      if (userSnapshot.value != null) {
        // ✅ Initialize ZEGO for regular user (ONCE at login)
        _initializeZegoForUser(user, 'user');
        Get.offAll(() => const NavBar());
        return;
      }

      Get.offAll(() => const OnBoardingScreen());
    } catch (e) {
      debugPrint('Error checking user type: $e');
      Get.offAll(() => const OnBoardingScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F4C5C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logos/emergencyAppLogo.png',
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 30),
            const Text(
              'Emergency Service',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'One Tap. Every Emergency.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            const PremiumLoadingIndicator(),
            const SizedBox(height: 30),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}