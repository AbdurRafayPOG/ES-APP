import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:public_emergency_app/Features/User/Screens/FirefighterOptions/firefighter_options.dart';
import 'package:public_emergency_app/Features/User/Screens/HospitalOptions/hospital_options.dart';
import 'package:public_emergency_app/Features/User/Screens/PoliceOptions/police_options.dart';
import 'package:public_emergency_app/Features/User/Screens/PharmacyOptions/pharmacy_options.dart';

// ✅ NEW IMPORTS
import 'package:public_emergency_app/Features/User/Screens/BloodBankOptions/bloodbank_options.dart';
import 'package:public_emergency_app/Features/User/Screens/HelplineOptions/helpline_options.dart';

class GridDashboard extends StatelessWidget {
  GridDashboard({super.key});

  // 🔥 SERVICE ITEMS
  final Items item1 = Items(
    title: "Police",
    subtitle: "Emergency Police",
    event: "",
    img: "assets/logos/policeman.png",
  );

  final Items item2 = Items(
    title: "Fire Brigade",
    subtitle: "Emergency Fire Brigade",
    event: "",
    img: "assets/logos/fire-truck.png",
  );

  final Items item3 = Items(
    title: "Pharmacy",
    subtitle: "Emergency Pharmacy",
    event: "",
    img: "assets/logos/pharmacy.png",
  );

  final Items item4 = Items(
    title: "Hospitals",
    subtitle: "Emergency Hospitals",
    event: "",
    img: "assets/logos/hospital.png",
  );

  // ✅ NEW SERVICES
  final Items item5 = Items(
    title: "Blood Bank",
    subtitle: "Emergency Blood Services",
    event: "",
    img: "assets/logos/BloodBank.png",
  );

  final Items item6 = Items(
    title: "Helpline",
    subtitle: "Emergency Helpline",
    event: "",
    img: "assets/logos/Helpline.png",
  );

  // 🔥 COLORS
  Color getServiceColor(String title) {
    switch (title) {
      case "Police":
        return const Color(0xFF1E3A8A);

      case "Fire Brigade":
        return const Color(0xFFDC2626);

      case "Pharmacy":
        return const Color(0xFF059669);

      case "Hospitals":
        return const Color(0xFF7C3AED);

      case "Blood Bank":
        return const Color(0xFFB91C1C);

      case "Helpline":
        return const Color(0xFF2563EB);

      default:
        return const Color(0xFF0F4C5C);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Items> myList = [item1, item2, item3, item4, item5, item6];

    return GridView.count(
      childAspectRatio: 1.0,
      padding: const EdgeInsets.only(left: 6, right: 6, top: 10),
      crossAxisCount: 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      children: myList.map((data) {
        return GestureDetector(
          onTap: () {
            switch (data.title) {
              case "Police":
                Get.to(() => const PoliceOptions());
                break;

              case "Fire Brigade":
                Get.to(() => const FireFighterOptions());
                break;

              case "Pharmacy":
                Get.to(() => const PharmacyOptions());
                break;

              case "Hospitals":
                Get.to(() => const HospitalOptions());
                break;

              case "Blood Bank":
                Get.to(() => const BloodBankOptions());
                break;

              case "Helpline":
                Get.to(() => const HelplineOptions());
                break;

              default:
                Get.snackbar("Error", "Service not available");
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  getServiceColor(data.title),
                  getServiceColor(data.title).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: getServiceColor(data.title).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  data.img,
                  width: data.title == "Blood Bank"
                      ? 85
                      : data.title == "Helpline"
                      ? 65
                      : 42,
                ),
                const SizedBox(height: 14),

                Text(
                  data.title,
                  style: GoogleFonts.openSans(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 🔥 MODEL CLASS
class Items {
  String title;
  String subtitle;
  String event;
  String img;

  Items({
    required this.title,
    required this.subtitle,
    required this.event,
    required this.img,
  });
}
