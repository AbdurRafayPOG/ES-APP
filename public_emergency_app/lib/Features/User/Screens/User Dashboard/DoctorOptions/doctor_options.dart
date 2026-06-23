import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorOptions extends StatelessWidget {
  const DoctorOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the center position of the app bar content
    final double appBarHeight = Get.height * 0.1 + kToolbarHeight;
    final double iconHeight = Get.height * 0.08;
    final double iconCenterY = appBarHeight / 2; // Since content is centered

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content - centered
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/logos/emergencyAppLogo.png",
                      height: iconHeight,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Doctor Options",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Back button - positioned at the center of the app icon
              Positioned(
                left: 16,
                top: iconCenterY - 20, // Subtract half of button height (40/2)
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF0F4C5C),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Find Nearby Doctors
            Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
                tileColor: Color(color),
                leading: const Icon(Icons.map, color: Colors.yellowAccent),
                title: const Text(
                  'Find Nearby Doctors',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Locate the nearest available doctors',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  try {
                    Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );
                    double lat = position.latitude;
                    double long = position.longitude;

                    String url = Platform.isAndroid
                        ? "https://www.google.com/maps/search/doctor/@$lat,$long,12.5z"
                        : "https://maps.apple.com/?q=$lat,$long";

                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                      throw 'Could not launch map';
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Unable to get current location or launch map: $e',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
            ),

            // Call Doctor Helpline
            Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
                tileColor: Color(color),
                leading: const Icon(Icons.call, color: Colors.yellowAccent),
                title: const Text(
                  'Call',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Directly call a doctor helpline',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  if (await Permission.phone.request().isGranted) {
                    try {
                      var url = Uri.parse("tel:102"); // Example helpline number
                      await launchUrl(url);
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Failed to make a call: $e',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  } else {
                    Get.snackbar(
                      'Permission Denied',
                      'Phone permission is required to make calls.',
                      backgroundColor: Colors.orange,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}