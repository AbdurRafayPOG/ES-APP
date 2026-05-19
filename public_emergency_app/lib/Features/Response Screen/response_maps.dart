import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EmergencyMaps extends StatefulWidget {
  final double latitude;
  final double longitude;
  const EmergencyMaps({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<EmergencyMaps> createState() => _EmergencyMapsState();
}

class _EmergencyMapsState extends State<EmergencyMaps> {
  final Completer<GoogleMapController> _controller = Completer();
  final DatabaseReference ref =
      FirebaseDatabase.instance.ref().child('Users');

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    // Add current user marker
    markers.add(Marker(
      markerId: const MarkerId("User"),
      position: LatLng(widget.latitude, widget.longitude),
      infoWindow: const InfoWindow(title: "You are here"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      onTap: () {
        Get.snackbar("User", "User is here");
      },
    ));

    // Fetch responders from Firebase
    getResponders();
  }

  void getResponders() {
    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        Set<Marker> newMarkers = {};
        data.forEach((key, value) {
          if (value['currentLat'] != null && value['currentLong'] != null) {
            double lat = double.tryParse(value['currentLat'].toString()) ?? 0.0;
            double long =
                double.tryParse(value['currentLong'].toString()) ?? 0.0;
            newMarkers.add(Marker(
              markerId: MarkerId(key),
              position: LatLng(lat, long),
              infoWindow:
                  InfoWindow(title: value['userName'], snippet: value['userType']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ));
          }
        });

        setState(() {
          // Keep user marker + responders
          markers = {...markers.where((m) => m.markerId.value == "User"), ...newMarkers};
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 14.4746,
        ),
        compassEnabled: true,
        markers: markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
