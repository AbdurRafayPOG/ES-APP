import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/Response%20Screen/emergencies_screen.dart';
import '../User/Controllers/login_controller.dart';
import '../User/Screens/Forget Password/forget_password.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final controller = Get.put(LoginController());
  bool _isObscure = true;
  final formKey = GlobalKey<FormState>();

  // 🔐 ADMIN PASSWORD DIALOG
  void showAdminPasswordDialog() {
    TextEditingController passwordController = TextEditingController();

    Get.defaultDialog(
      title: "Admin Access",
      content: Column(
        children: [
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Enter Admin Password",
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              String password = passwordController.text.trim();

              // 🔐 CHANGE YOUR PASSWORD HERE
              if (password == "admin123") {
                Get.back(); // close dialog
                Get.to(const EmergenciesScreen());
              } else {
                Get.snackbar(
                  "Error",
                  "Wrong Password",
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text("Enter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 250),

            // 📧 EMAIL FIELD
            TextFormField(
              controller: controller.emailController,
              validator: (value) {
                bool isValid = RegExp(
                  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+",
                ).hasMatch(value ?? "");

                if (!isValid) return 'Invalid email';
                return null;
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined),
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔑 PASSWORD FIELD
            TextFormField(
              controller: controller.passwordController,
              obscureText: _isObscure,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                if (value.trim().length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.fingerprint),
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 🔁 FORGOT PASSWORD
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Get.to(() => const ForgetPassword());
                },
                child: Text(
                  "Forget Password?",
                  style: TextStyle(color: Color(color)),
                ),
              ),
            ),

            // 🔓 LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(color),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    LoginController.instance.loginUser(
                      controller.emailController.text,
                      controller.passwordController.text.trim(),
                    );
                  }
                },
                child: Text("LOG IN"),
              ),
            ),

            const SizedBox(height: 10),

            // 🔐 ADMIN BUTTON (PROTECTED)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 30, 145, 174),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  showAdminPasswordDialog();
                },
                child: Text("ADMIN SCREEN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}