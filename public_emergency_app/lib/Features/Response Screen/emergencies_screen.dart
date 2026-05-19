import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ListOfResponders/select_responder.dart';
import '../User/Screens/LiveStreaming/live_stream.dart';

class EmergenciesScreen extends StatefulWidget {
  const EmergenciesScreen({Key? key}) : super(key: key);

  @override
  State<EmergenciesScreen> createState() => _EmergenciesScreenState();
}

class _EmergenciesScreenState extends State<EmergenciesScreen> {
  final DatabaseReference ref = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref('sos');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Get.height * 0.1),
          child: Column(
            children: [
              Image.asset(
                "assets/logos/emergencyAppLogo.png",
                height: Get.height * 0.08,
              ),
              const SizedBox(height: 8),
              const Text(
                "Emergencies",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              snapshot.data!.snapshot.value != null) {

            Map<dynamic, dynamic>? map =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;

            if (map == null) {
              return const Center(child: Text("No data found"));
            }

            List<dynamic> list = map.values.toList();

            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                var item = list[index];

                return Container(
                  margin: EdgeInsets.symmetric(
                    vertical: Get.height * 0.015,
                    horizontal: Get.width * 0.018,
                  ),
                  child: ListTile(
                    onTap: () {
                      double lat =
                          double.tryParse(item['lat']?.toString() ?? "") ?? 0.0;
                      double long =
                          double.tryParse(item['long']?.toString() ?? "") ?? 0.0;

                      String address =
                          item['address']?.toString() ?? "No Address";

                      String userId =
                          item['videoId']?.toString() ?? "";

                      Get.to(() => SelectResponder(
                            userLat: lat,
                            userLong: long,
                            userAddress: address,
                            userID: userId,
                          ));
                    },
                    tileColor: Color(color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: Text(
                      item['address']?.toString() ?? "No Address",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      item['time']?.toString() ?? "",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.location_on,
                              color: Colors.amberAccent, size: 25),
                          onPressed: () async {
                            var lat = item['lat']?.toString() ?? "0";
                            var long = item['long']?.toString() ?? "0";

                            String url =
                                'https://www.google.com/maps/search/?api=1&query=$lat,$long';

                            if (Platform.isAndroid) {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            } else {
                              String appleUrl =
                                  'https://maps.apple.com/?q=$lat,$long';

                              if (await canLaunchUrl(Uri.parse(appleUrl))) {
                                await launchUrl(Uri.parse(appleUrl));
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.video_call,
                              color: Colors.red, size: 25),
                          onPressed: () {
                            Get.to(() => LiveStreamingPage(
                                  liveId:
                                      item['videoId']?.toString() ?? "",
                                  isHost: false,
                                ));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}