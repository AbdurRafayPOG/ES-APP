import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Controllers/session_controller.dart';
import 'package:public_emergency_app/Services/sos_service.dart';
import 'package:public_emergency_app/Models/emergency_model.dart';
import '../../../../Common Widgets/constants.dart';
import 'videoncall.dart';
import 'emergency_status_page.dart';
import 'dart:math';

final sessionController = Get.put(SessionController());

class LiveStreamUser extends StatefulWidget {
  const LiveStreamUser({Key? key}) : super(key: key);

  @override
  State<LiveStreamUser> createState() => _LiveStreamUserState();
}

class _LiveStreamUserState extends State<LiveStreamUser>
    with SingleTickerProviderStateMixin {
  late AnimationController _wobbleController;
  bool _isAnimating = false;
  
  final SOSService _sosService = SOSService();
  
  StreamSubscription<DatabaseEvent>? _assignedStreamSubscription;
  String? _assignedEmergencyId;
  Map<String, dynamic>? _assignedResponderData;
  bool _hasActiveEmergency = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    handleLocationPermission();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAssignedEmergencyListener();
    });
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _assignedStreamSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // REAL-TIME LISTENER - Watches 'assigned' node
  // ============================================================
  void _setupAssignedEmergencyListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    _currentUserId = user.uid;

    _assignedStreamSubscription?.cancel();
    
    _assignedStreamSubscription = FirebaseDatabase.instance
        .ref('assigned')
        .onValue
        .listen((event) {
      final snapshot = event.snapshot;
      
      if (snapshot.value == null) {
        _clearEmergencyState();
        return;
      }

      try {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        bool found = false;
        
        for (var responderId in data.keys) {
          final responderValue = data[responderId];
          if (responderValue is! Map) continue;
          
          final emergencies = Map<String, dynamic>.from(responderValue as Map);
          
          for (var emergencyId in emergencies.keys) {
            final emergency = Map<String, dynamic>.from(emergencies[emergencyId] as Map);
            final status = emergency['status']?.toString() ?? '';
            
            if (emergency['userID'] == _currentUserId) {
              if (status != 'completed' && status != 'cancelled') {
                if (mounted) {
                  setState(() {
                    _hasActiveEmergency = true;
                    _assignedEmergencyId = emergencyId;
                    _assignedResponderData = emergency;
                    _assignedResponderData!['responderId'] = responderId;
                  });
                }
                found = true;
                break;
              }
            }
          }
          if (found) break;
        }
        
        if (!found) {
          _clearEmergencyState();
        }
      } catch (e) {
        _clearEmergencyState();
      }
    });
  }

  void _clearEmergencyState() {
    if (mounted) {
      setState(() {
        _hasActiveEmergency = false;
        _assignedEmergencyId = null;
        _assignedResponderData = null;
      });
    }
  }

  Future<void> handleLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Disabled',
          'Please enable location services',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is required.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Location permission error: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ============================================================
  // MANUAL CHECK - For after creating emergency
  // ============================================================
  Future<void> _checkForActiveEmergency() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('assigned')
          .get();
      
      if (snapshot.value == null) {
        _clearEmergencyState();
        return;
      }
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      for (var responderId in data.keys) {
        final responderValue = data[responderId];
        if (responderValue is! Map) continue;
        
        final emergencies = Map<String, dynamic>.from(responderValue as Map);
        
        for (var emergencyId in emergencies.keys) {
          final emergency = Map<String, dynamic>.from(emergencies[emergencyId] as Map);
          final status = emergency['status']?.toString() ?? '';
          
          if (emergency['userID'] == _currentUserId) {
            if (status != 'completed' && status != 'cancelled') {
              if (mounted) {
                setState(() {
                  _hasActiveEmergency = true;
                  _assignedEmergencyId = emergencyId;
                  _assignedResponderData = emergency;
                  _assignedResponderData!['responderId'] = responderId;
                });
              }
              return;
            }
          }
        }
      }
      
      _clearEmergencyState();
    } catch (e) {
      _clearEmergencyState();
    }
  }

  // ============================================================
  // SOS CONFIRMATION DIALOG
  // ============================================================
  Future<void> _showSOSConfirmationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F4C5C), Color(0xFF1A7A8C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sos_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Emergency Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              _buildEmergencyOption(
                icon: Icons.local_police_rounded,
                label: 'Police',
                color: Colors.blue,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _handleEmergencySelection('Police');
                },
              ),
              const SizedBox(height: 12),
              
              _buildEmergencyOption(
                icon: Icons.fire_extinguisher_rounded,
                label: 'Firefighter',
                color: Colors.orange,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _handleEmergencySelection('Firefighter');
                },
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HANDLE EMERGENCY SELECTION
  // ============================================================
  Future<void> _handleEmergencySelection(String emergencyType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    try {
      String userName = 'Unknown User';
      try {
        final userSnapshot = await FirebaseDatabase.instance
            .ref('Users')
            .child(user.uid)
            .get();
        
        if (userSnapshot.value != null) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          userName = userData['UserName']?.toString() ?? 'Unknown User';
        }
      } catch (e) {
        // Ignore
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks.first;
      String address =
          '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.postalCode ?? ''}';

      Emergency emergency = Emergency(
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: userName,
        userLat: position.latitude,
        userLong: position.longitude,
        address: address,
        emergencyType: emergencyType,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final result = await _sosService.createEmergency(emergency);

      if (result.success) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _checkForActiveEmergency();
        _showSOSSuccessDialog(result.emergencyId!, result.responderData!);
      } else {
        _showNoResponderAvailableDialog(emergencyType);
      }
    } catch (e) {
    }
  }

  void _showSOSSuccessDialog(String emergencyId, Map<String, dynamic> responderData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SOS Sent!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${responderData['UserType'] ?? 'Responder'} assigned to you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (responderData['UserName'] ?? 'R')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            responderData['UserName'] ?? 'Unknown Responder',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            responderData['UserType'] ?? 'Responder',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'En Route',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoResponderAvailableDialog(String emergencyType) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $emergencyType Available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All $emergencyType responders are currently busy or unavailable. Please try again later or contact emergency services directly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEmergencyStatus(String emergencyId) {
    Get.to(() => EmergencyStatusPage(emergencyId: emergencyId));
  }

  void _startWobbleAnimation() async {
    if (_hasActiveEmergency) {
      Get.snackbar(
        'Active Emergency',
        'You already have an active emergency. Please wait for responder.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    
    if (_isAnimating) return;
    _isAnimating = true;

    _wobbleController.reset();
    await _wobbleController.forward();
    await _showSOSConfirmationDialog();

    _isAnimating = false;
  }

 
  

  @override
  Widget build(BuildContext context) {
    String responderType = _assignedResponderData?['type'] ?? 'Responder';
    String userName = _assignedResponderData?['userName'] ?? 'User';
    
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/logos/emergencyAppLogo.png",
                      height: Get.height * 0.08,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "SOS",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _wobbleController,
                builder: (context, child) {
                  final double value = _wobbleController.value;
                  final double wobbleAngle = sin(value * 4 * 3.14159) * 0.08 * (1 - value);
                  final double scaleValue = 1.0 + (0.05 * (1 - value));
                  
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(wobbleAngle)
                      ..scale(scaleValue),
                    child: child,
                  );
                },
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: Get.width * 0.8,
                    height: Get.height * 0.25,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 20,
                        backgroundColor: _hasActiveEmergency ? Colors.grey : Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        shadowColor: _hasActiveEmergency 
                            ? Colors.grey.withOpacity(0.5) 
                            : Colors.red.withOpacity(0.5),
                      ),
                      onPressed: _hasActiveEmergency ? null : _startWobbleAnimation,
                      child: Text(
                        _hasActiveEmergency ? "ACTIVE" : "SOS",
                        style: TextStyle(
                          fontSize: _hasActiveEmergency ? 32 : 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: _hasActiveEmergency ? 4 : 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Get.height * 0.06),
              
              if (!_hasActiveEmergency)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(color).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(color).withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Press the button to send your location to the rescue headquarters.",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_hasActiveEmergency)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: GestureDetector(
                    onTap: () {
                      if (_assignedEmergencyId != null) {
                        _navigateToEmergencyStatus(_assignedEmergencyId!);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF43A047),
                            Color(0xFF2E7D32),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emergency_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'View Active Emergency',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$responderType En Route',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveCurrentLocation() async {
    // Kept for compatibility
  }
}