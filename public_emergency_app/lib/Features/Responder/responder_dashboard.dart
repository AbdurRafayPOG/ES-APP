import 'dart:io';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/User/Screens/Profile/profile_screen.dart';
import 'package:public_emergency_app/Features/User/Screens/LiveStreaming/live_stream.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_switch/sliding_switch.dart';
import 'package:url_launcher/url_launcher.dart';
import '../User/Controllers/message_sending.dart';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({Key? key}) : super(key: key);

  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  final locationController = Get.put(MessageController());

  late DatabaseReference assignedRef;
  late DatabaseReference activeRespondersRef;
  late DatabaseReference userRef;

  final String firebaseDatabaseUrl =
      'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app';

  bool _switchValue = false;
  String status = '';
  String userType = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      initializeFirebase();
    } else {
      _isLoading = false;
    }
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: firebaseDatabaseUrl,
    );

    userRef = db.ref().child('Users');
    assignedRef = db.ref().child('assigned').child(user!.uid);
    activeRespondersRef = db.ref().child('activeResponders');

    await _loadSwitchValue();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSwitchValue() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _switchValue = prefs.getBool('switchValue') ?? false;
      status = _switchValue ? 'Available' : 'Unavailable';
    });
    if (_switchValue) await setResponderData();
  }

  Future<void> _saveSwitchValue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('switchValue', value);
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> setResponderData() async {
    if (user == null) return;

    userType = '';
    bool permissionGranted = await locationController.handleLocationPermission();
    if (!permissionGranted) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      DataSnapshot snapshot = await userRef.child(user!.uid).get();
      if (snapshot.value != null) {
        Map<dynamic, dynamic> map =
            Map<dynamic, dynamic>.from(snapshot.value as Map);
        userType = map['UserType'] ?? '';
        await activeRespondersRef.child(user!.uid).set({
          "lat": position.latitude.toString(),
          "long": position.longitude.toString(),
          "responderType": userType,
          "responderID": user!.uid,
        });
      }
    } catch (e) {
      debugPrint('Error in setResponderData: $e');
    }
  }

  String getDistance(Map list) {
    try {
      if (list['userLat'] == null ||
          list['userLong'] == null ||
          list['responderLat'] == null ||
          list['responderLong'] == null) return '';
      double dist = calculateDistance(
        double.tryParse(list['userLat'].toString()) ?? 0.0,
        double.tryParse(list['userLong'].toString()) ?? 0.0,
        double.tryParse(list['responderLat'].toString()) ?? 0.0,
        double.tryParse(list['responderLong'].toString()) ?? 0.0,
      );
      return '${dist.toStringAsFixed(2)} km';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(color),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(
            side: BorderSide(color: Colors.white24, width: 4)),
        onPressed: () => Get.to(() => const ProfileScreen()),
        child: const Icon(Icons.person),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      appBar: AppBar(
        backgroundColor: Color(color),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Get.height * 0.16),
          child: Column(
            children: [
              Image.asset(
                "assets/logos/emergencyAppLogo.png",
                height: Get.height * 0.07,
              ),
              const SizedBox(height: 8),
              const Text(
                "Responder Dashboard",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              SlidingSwitch(
                value: _switchValue,
                width: 100,
                height: 40,
                textOff: 'OFF',
                textOn: 'ON',
                colorOn: Colors.green,
                colorOff: Colors.red,
                onChanged: (value) async {
                  await _saveSwitchValue(value);
                  if (!mounted) return;
                  setState(() {
                    _switchValue = value;
                    status = value ? 'Available' : 'Unavailable';
                  });
                  if (value) {
                    await setResponderData();
                  } else {
                    activeRespondersRef.child(user!.uid).remove();
                  }
                },
                onTap: () {},
                onDoubleTap: () {},
                onSwipe: () {},
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: assignedRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData = snapshot.data!.snapshot.value;

          if (rawData == null) {
            return const Center(child: Text("No emergency requests assigned"));
          }

          if (rawData is! Map) {
            return const Center(child: Text("Invalid data format"));
          }

          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(rawData);
          final emergencies = <Map<dynamic, dynamic>>[];

          data.forEach((key, value) {
            if (value is Map) {
              emergencies.add(Map<dynamic, dynamic>.from(value));
            }
          });

          if (emergencies.isEmpty) {
            return const Center(child: Text("No emergency requests assigned"));
          }

          return ListView.builder(
            itemCount: emergencies.length,
            itemBuilder: (context, index) {
              Map list = emergencies[index];
              return Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: ListTile(
                  onTap: () async {
                    var lat = list['userLat'];
                    var long = list['userLong'];
                    if (lat == null || long == null) {
                      Get.snackbar('Error', 'No Emergency Location Found');
                      return;
                    }
                    String url = Platform.isAndroid
                        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$long'
                        : 'https://maps.apple.com/?q=$lat,$long';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                      Get.snackbar('Error', 'Cannot open maps');
                    }
                  },
                  tileColor: Color(color),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  title: Text(
                    list['userAddress'] ?? 'No Address',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  subtitle: Text(
                    'Distance: ${getDistance(list)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.video_call,
                        color: Colors.red, size: 30),
                    onPressed: () {
                      if (list['userLat'] == null || list['userLong'] == null) {
                        Get.snackbar('Error', 'No Emergency Request Yet');
                        return;
                      }
                      Get.to(() => LiveStreamingPage(
                            liveId: list['userID'],
                            isHost: false,
                          ));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
