import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Controllers/session_controller.dart';

import '../Screens/SignUp/verify_email_page.dart';

// SignUpController is used to store user data when signing up and also create User Email & Password Authentication for login
class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  // TextField Controllers to get data from TextFields
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();
  final phoneNo = TextEditingController();

  late DatabaseReference ref;

  @override
  void onInit() {
    super.onInit();

    // Initialize DatabaseReference with your Firebase App & custom databaseURL
    ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref('Users');
  }

  void signUp(String username, String email, String password, String Phone,
      String Usertype) async {
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      UserCredential userCredential =
          await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save UID in SessionController
      SessionController().userid = userCredential.user!.uid;

      // Save user info in your custom Firebase database
      await ref.child(userCredential.user!.uid).set({
        'email': userCredential.user!.email.toString(),
        'UserName': username,
        'Phone': Phone,
        'UserType': Usertype,
      });

      Get.offAll(() => const VerifyEmailPage());
      Get.snackbar("Success", "Sign Up Successfully");

    } on FirebaseAuthException catch (error) {
      if (error.code == "email-already-in-use") {
        Get.snackbar("Error", "Email Already In Use");
      } else if (error.code == "weak-password") {
        Get.snackbar("Error", "Password Should Be At Least 6 Characters");
      } else if (error.code == "invalid-email") {
        Get.snackbar("Error", "Invalid Email");
      } else if (error.code == "network-request-failed") {
        Get.snackbar("Error", "Check Your Internet Connection");
      } else {
        Get.snackbar("Error", error.message ?? error.toString());
      }
    } catch (error) {
      Get.snackbar("Error", error.toString());
      debugPrint(error.toString());
    }
  }
}
