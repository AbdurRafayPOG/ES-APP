import 'dart:io';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import '../Response Screen/emergencies_screen.dart';

class SelectResponder extends StatefulWidget {
  final String userID;
  final double userLat;
  final double userLong;
  final String userAddress;
  final String? userPhone;

  const SelectResponder({
    Key? key,
    required this.userID,
    required this.userLat,
    required this.userLong,
    required this.userAddress,
    this.userPhone,
  }) : super(key: key);

  @override
  State<SelectResponder> createState() => _SelectResponderState();
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

class _SelectResponderState extends State<SelectResponder> {
  final String firebaseDatabaseUrl =
      'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app';

  late DatabaseReference ref;

  @override
  void initState() {
    super.initState();
    ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: firebaseDatabaseUrl,
    ).ref().child('activeResponders');
  }

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
          child: Container(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: [
                const SizedBox(width: 30),
                Center(
                  child: SizedBox.fromSize(
                    size: const Size(36, 36),
                    child: ClipOval(
                      child: Material(
                        color: Color(color),
                        child: InkWell(
                          splashColor: Colors.white,
                          onTap: () => Get.back(),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/logos/emergencyAppLogo.png",
                      height: Get.height * 0.08,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: const Text(
                        "Select Responders",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No active responders found"));
          }

          final dataSnapshot = snapshot.data!.snapshot;
          final map = Map<dynamic, dynamic>.from(dataSnapshot.value as Map);
          final list = map.values
              .map((e) => Map<dynamic, dynamic>.from(e))
              .toList(); // convert safely to list

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final responder = list[index];
              final lat = double.tryParse(responder['lat'].toString()) ?? 0.0;
              final long = double.tryParse(responder['long'].toString()) ?? 0.0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: ListTile(
                  tileColor: Color(color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Text(
                    responder['responderType'] ?? "Responder",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  subtitle: Text(
                    "Distance from user: ${calculateDistance(widget.userLat, widget.userLong, lat, long).toStringAsFixed(2)} km",
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.assignment_turned_in_outlined,
                        color: Colors.red, size: 30),
                    onPressed: () async {
                      try {
                        final usersRef = FirebaseDatabase.instanceFor(
                          app: Firebase.app(),
                          databaseURL: firebaseDatabaseUrl,
                        ).ref().child('assigned');

                        // Push key use karke naya child create karte hain
                        await usersRef
                            .child(responder['responderID'])
                            .push()
                            .set({
                          'responderLat': responder['lat'],
                          'responderLong': responder['long'],
                          'responderID': responder['responderID'],
                          'userID': widget.userID,
                          'userLat': widget.userLat,
                          'userLong': widget.userLong,
                          'userAddress': widget.userAddress,
                          'userPhone': widget.userPhone,
                        });

                        // SOS remove karte hain
                        await FirebaseDatabase.instanceFor(
                          app: Firebase.app(),
                          databaseURL: firebaseDatabaseUrl,
                        ).ref().child('sos').child(widget.userID).remove();

                        if (!mounted) return;
                        Get.snackbar(
                          "Assigned",
                          'Emergency assigned to responder',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 3),
                        );

                        Get.off(() => const EmergenciesScreen());
                      } catch (e) {
                        if (!mounted) return;
                        Get.snackbar(
                          "Error",
                          e.toString(),
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 3),
                        );
                      }
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
