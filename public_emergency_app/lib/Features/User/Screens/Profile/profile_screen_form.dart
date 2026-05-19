import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:firebase_core/firebase_core.dart';


import '../../../Emergency Contacts/add_contacts.dart';
import '../../Controllers/session_controller.dart';

class ProfileFormWidget extends StatefulWidget {
  const ProfileFormWidget({Key? key}) : super(key: key);

  @override
  State<ProfileFormWidget> createState() => _ProfileFormWidgetState();
}

class _ProfileFormWidgetState extends State<ProfileFormWidget> {
  late DatabaseReference ref; // ← late declare

  @override
  void initState() {
    super.initState();

    // Initialize DatabaseReference with your Firebase App & custom databaseURL
    ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref('Users');
  }

  @override
  Widget build(BuildContext context) {
    final _formkey = GlobalKey<FormState>();
    String userEmail = '';
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: StreamBuilder(
        stream: ref.child(user!.uid).onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.data.snapshot.value != null) {
            Map<dynamic, dynamic> map = snapshot.data.snapshot.value;
            final nameController = TextEditingController(text: map['UserName']);
            final phoneController = TextEditingController(text: map['Phone']);
            userEmail = map['email'] ?? '';

            return Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User Info",
                    style: TextStyle(
                      color: Color(color),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be valid';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      labelText: "Full Name",
                      hintText: "Full Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: phoneController,
                    validator: (value) {
                      bool _isPhoneValid =
                          RegExp(r'^(?:[+0][1-9])?[0-9]{8,15}$').hasMatch(value!);
                      if (!_isPhoneValid) {
                        return 'Invalid phone number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone),
                      labelText: "Phone Number",
                      hintText: "Phone Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: map['email'],
                    enableInteractiveSelection: false,
                    focusNode: AlwaysDisabledFocusNode(),
                    validator: (value) {
                      bool _isEmailValid = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(value!);
                      if (!_isEmailValid) {
                        return 'Invalid email.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelText: "Email",
                      hintText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0F4C5C), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if ((_formkey.currentState)!.validate()) {
                          updateprofile(nameController.text.trim(),
                              phoneController.text.trim());

                          Get.snackbar(
                            "Save",
                            "Profile Updated",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                      child: Text("Update".toUpperCase()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 151, 25, 25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Get.to(
                          () => const add_contact(),
                          transition: Transition.rightToLeft,
                          duration: const Duration(seconds: 1),
                          arguments: userEmail,
                        );
                      },
                      child: Text("Emergency Contacts".toUpperCase()),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void updateprofile(String name, String phone) {
    ref.child(SessionController().userid.toString()).update({
      'UserName': name,
      'Phone': phone,
    });
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
