import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:public_emergency_app/Features/User/Controllers/call_controller.dart';
import 'package:public_emergency_app/Services/emergency_assignment_service.dart'; // <-- ADD THIS IMPORT

import 'Features/Splash/splash_screen.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set navigator key
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // IMPORTANT: Call useSystemCallingUI before runApp
  await ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
    [ZegoUIKitSignalingPlugin()],
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Public Emergency App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorKey: navigatorKey,
      initialBinding: AppBinding(),
      home: const SplashScreen(),
    );
  }
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Register CallController
    Get.put<CallController>(CallController(), permanent: true);
    
    // Register EmergencyAssignmentService
    Get.put<EmergencyAssignmentService>(EmergencyAssignmentService(), permanent: true);
  }
}