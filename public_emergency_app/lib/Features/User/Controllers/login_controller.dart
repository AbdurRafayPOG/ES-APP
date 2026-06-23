import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Controllers/session_controller.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/Splash/splash_screen.dart';
import '../Screens/SignUp/verify_email_page.dart';
import 'package:public_emergency_app/Features/Admin/admin_panel.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final RxBool isAdminLogging = false.obs;
  final RxBool isLoading = false.obs;  // ← ADDED THIS

  final String firebaseDatabaseUrl =
      'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app/';

  DateTime? _parseBanDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _checkBanStatus(
      DatabaseReference userRef, Map<dynamic, dynamic> data) async {
    final banned = data['banned'] ?? 'none';
    if (banned == 'none') return null;

    if (banned == 'permanent') {
      final reason = data['banReason'] ?? '';
      return reason.isNotEmpty
          ? 'Your account has been permanently banned.\nReason: $reason'
          : 'Your account has been permanently banned.';
    }

    if (banned == 'temporary') {
      final banUntilStr = data['banUntil'] ?? '';
      final banUntil = _parseBanDate(banUntilStr);
      if (banUntil == null) return null;

      if (DateTime.now().isAfter(banUntil)) {
        // // Expired — auto lift
        await userRef.update({
          'banned': 'none',
          'banReason': '',
          'banUntil': '',
        });
        return null;
      }

      final reason = data['banReason'] ?? '';
      return reason.isNotEmpty
          ? 'Your account is temporarily banned until $banUntilStr.\nReason: $reason'
          : 'Your account is temporarily banned until $banUntilStr.';
    }

    return null;
  }

  void _showBannedDialog(String message) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded,
                    color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 18),
              const Text('Account Banned',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('OK',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // // Shows deleted account dialog
  void _showDeletedDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_off_rounded,
                    color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 18),
              const Text('Account Removed',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              const Text(
                'This account has been removed by the admin.\nPlease contact support if you think this is a mistake.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black54, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('OK',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void loginUser(String email, String password) async {
    isLoading.value = true;  // ← ADDED THIS - Set loading to true for ALL logins

    // // Hardcoded admin
    if (email == 'admin' && password == 'admin123') {
      isAdminLogging.value = true;
      await Future.delayed(const Duration(milliseconds: 800));
      isAdminLogging.value = false;
      isLoading.value = false;  // ← ADDED THIS
      Get.offAll(() => const AdminPanel());
      Get.snackbar('', '',
          titleText: Row(
            children: const [
              Icon(Icons.verified_rounded,
                  color: Colors.amberAccent, size: 20),
              SizedBox(width: 8),
              Text('Welcome, Admin',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          messageText: const Text('Admin access granted',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          backgroundColor: Colors.green,
          colorText: Colors.white,
          borderRadius: 16,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP);
      return;
    }

    try {
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      SessionController().userid = cred.user!.uid;
      final String uid = cred.user!.uid;

      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: firebaseDatabaseUrl,
      );

      // // FIRST — check DeletedAccounts/ for any role
      final deletedSnap = await db.ref('DeletedAccounts').child(uid).get();
      if (deletedSnap.exists) {
        // // Block immediately — sign out and show removed dialog
        await FirebaseAuth.instance.signOut();
        SessionController().userid = '';
        isLoading.value = false;  // ← ADDED THIS
        _showDeletedDialog();
        return;
      }

      // // Check Responders/
      final responderSnap = await db.ref('Responders').child(uid).get();
      if (responderSnap.exists) {
        isLoading.value = false;  // ← ADDED THIS
        Get.offAll(() => const SplashScreen());
        Get.snackbar('Success', 'Login Successfully');
        return;
      }

      // // Check Doctors/
      final doctorSnap = await db.ref('Doctors').child(uid).get();
      if (doctorSnap.exists) {
        isLoading.value = false;  // ← ADDED THIS
        Get.offAll(() => const SplashScreen());
        Get.snackbar('Success', 'Login Successfully');
        return;
      }

      // // Regular user — check ban
      final userRef = db.ref('Users').child(uid);
      final userSnap = await userRef.get();

      if (userSnap.exists) {
        final data = Map<dynamic, dynamic>.from(userSnap.value as Map);
        final banMessage = await _checkBanStatus(userRef, data);
        if (banMessage != null) {
          await FirebaseAuth.instance.signOut();
          SessionController().userid = '';
          isLoading.value = false;  // ← ADDED THIS
          _showBannedDialog(banMessage);
          return;
        }
      }

      // // All clear — let them in
      isLoading.value = false;  // ← ADDED THIS
      Get.offAll(() => const SplashScreen());
      Get.snackbar('Success', 'Login Successfully');
    } catch (error) {
      isLoading.value = false;  // ← ADDED THIS
      isAdminLogging.value = false;
      emailController.clear();
      passwordController.clear();

      final msg = error.toString();
      if (msg.contains('user-not-found')) {
        Get.snackbar('Error', 'User Not Found');
      } else if (msg.contains('wrong-password')) {
        Get.snackbar('Error', 'Wrong Password');
      } else if (msg.contains('invalid-email')) {
        Get.snackbar('Error', 'Invalid Email');
      } else if (msg.contains('network-request-failed')) {
        Get.snackbar('Error', 'Network Error');
      } else if (msg.contains('too-many-requests')) {
        Get.snackbar('Error', 'Too Many Requests');
      } else if (msg.contains('invalid-credential')) {
        Get.snackbar('Error', 'Invalid Credential');
      } else {
        Get.snackbar('Error', msg);
      }
    }
  }
}