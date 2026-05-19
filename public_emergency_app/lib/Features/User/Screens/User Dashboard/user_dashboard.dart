import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Controllers/message_sending.dart';
import 'package:public_emergency_app/Features/User/Screens/User%20DashBoard/grid_dash.dart';
import 'package:public_emergency_app/Features/User/Screens/User%20DashBoard/weather_widget.dart';

// Import your AI Chat Screen
import '../Chatbot/ai_chat_screen.dart';
import '../../DoctorOptions/doctor_options.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
} 

class _UserDashboardState extends State<UserDashboard> {
  final _messageController = Get.put(MessageController());
  FirebaseAuth auth = FirebaseAuth.instance;

  void _showWeatherDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Current Weather"),
          content: SizedBox(
            width: double.maxFinite,
            child: WeatherWidget(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _openChatBot() {
    Get.to(() => const AIChatScreen());
  }

  void _openDoctorPage() {
    Get.to(() => const DoctorOptions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C5C),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),

        /// ONLY WEATHER ICON (kept)
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud, color: Colors.white),
            onPressed: _showWeatherDialog,
            tooltip: "Weather",
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        child: Column(
          children: [

            /// DOCTOR CARD (unchanged)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: _openDoctorPage,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/logos/Doctor.png",
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Emergency Doctor",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// GRID DASHBOARD
            Expanded(
              child: GridDashboard(),
            ),
          ],
        ),
      ),

      /// AI CHATBOT BUTTON (UNCHANGED)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatBot,
        backgroundColor: const Color(0xFF0F4C5C),
        elevation: 8,
        icon: const Icon(
          Icons.smart_toy,
          color: Colors.white,
          size: 26,
        ),
        label: const Text(
          "AI Agent",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        tooltip: "AI Emergency Assistant",
      ),
    );
  }
}