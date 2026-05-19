import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../Features/Login/login_screen.dart';
import '../Features/User/Controllers/session_controller.dart';
import '../Features/User/Screens/SignUp/verify_email_page.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final PageController controller = PageController();

  bool lastPage = false;

  final List<Map<String, dynamic>> pages = [
    {
      "image": "assets/Responder.png",
      "title": "Emergency Patrol",
      "subtitle":
          "Instantly connect with police, ambulance, and firefighters during emergencies.",
      "color1": const Color(0xffFF6B6B),
      "color2": const Color(0xffFF8E53),
      "icon": Icons.local_hospital_rounded,
    },
    {
      "image": "assets/Quick.png",
      "title": "Fast Emergency Response",
      "subtitle":
          "Send alerts in seconds and share your live location with responders.",
      "color1": const Color(0xff4FACFE),
      "color2": const Color(0xff00F2FE),
      "icon": Icons.flash_on_rounded,
    },
    {
      "image": "assets/Choose.png",
      "title": "Choose Your Responder",
      "subtitle":
          "Find the right doctor or responder based on your emergency situation.",
      "color1": const Color(0xff43E97B),
      "color2": const Color(0xff38F9D7),
      "icon": Icons.support_agent_rounded,
    },
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void handleNavigation() {
    final user = auth.currentUser;

    if (user != null) {
      SessionController().userid = user.uid.toString();

      Timer(
        const Duration(milliseconds: 200),
        () => Get.offAll(() => const VerifyEmailPage()),
      );
    } else {
      Timer(
        const Duration(milliseconds: 200),
        () => Get.offAll(() => const LoginScreen()),
      );
    }
  }

  Widget buildPage({
    required String image,
    required String title,
    required String subtitle,
    required Color color1,
    required Color color2,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color1,
            color2,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// TOP ICON
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              const Spacer(),

              /// IMAGE CARD
              Container(
                height: Get.height * 0.40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Hero(
                  tag: title,
                  child: Padding(
                    padding: EdgeInsets.all(
                      image == "assets/Choose.png" ? 5 : 20,
                    ),
                    child: Image.asset(
                      image,

                      /// CHOOSE IMAGE BIGGER
                      fit: image == "assets/Choose.png"
                          ? BoxFit.cover
                          : BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 45),

              /// TITLE
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 18),

              /// SUBTITLE
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// PAGE VIEW
          PageView.builder(
            controller: controller,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() {
                lastPage = index == pages.length - 1;
              });
            },
            itemBuilder: (context, index) {
              final item = pages[index];

              return buildPage(
                image: item['image'],
                title: item['title'],
                subtitle: item['subtitle'],
                color1: item['color1'],
                color2: item['color2'],
                icon: item['icon'],
              );
            },
          ),

          /// BOTTOM CONTROLS
          Positioned(
            bottom: 35,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// SKIP BUTTON
                TextButton(
                  onPressed: handleNavigation,
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// INDICATOR
                SmoothPageIndicator(
                  controller: controller,
                  count: pages.length,
                  effect: ExpandingDotsEffect(
                    expansionFactor: 4,
                    spacing: 8,
                    radius: 12,
                    dotHeight: 10,
                    dotWidth: 10,
                    dotColor: Colors.white.withOpacity(0.4),
                    activeDotColor: Colors.white,
                  ),
                ),

                /// NEXT / GET STARTED BUTTON
                GestureDetector(
                  onTap: () {
                    if (lastPage) {
                      handleNavigation();
                    } else {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 60,
                    width: lastPage ? 150 : 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: lastPage
                          ? const Text(
                              "Get Started",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.black,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
