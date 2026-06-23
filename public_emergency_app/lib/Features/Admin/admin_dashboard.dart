import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/Login/login_screen.dart';
import 'package:public_emergency_app/Features/Admin/Records/responder_history.dart';
import 'package:public_emergency_app/Features/Admin/Records/docter_history.dart';
import 'package:firebase_core/firebase_core.dart'; 

class EmergenciesScreen extends StatefulWidget {
  const EmergenciesScreen({Key? key}) : super(key: key);

  @override
  State<EmergenciesScreen> createState() => _EmergenciesScreenState();
}

class _EmergenciesScreenState extends State<EmergenciesScreen> {
  // ============================================================
  // DATABASE REFERENCES
  // ============================================================
  late DatabaseReference sosDoneRef;
  late DatabaseReference assignedRef;
  final String firebaseDatabaseUrl =
      'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app';
  
  // ============================================================
  // STATS VARIABLES
  // ============================================================
  int _totalRecords = 0;
  int _activeEmergencies = 0;
  int _completedEmergencies = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  // ============================================================
  // INIT STATE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  // ============================================================
  // INITIALIZE DATABASE - 🔥 FIXED: No Firebase.initializeApp()
  // ============================================================
  Future<void> _initializeDatabase() async {
    try {
      // ✅ Firebase is already initialized in main.dart
      // ❌ REMOVED: await Firebase.initializeApp();
      
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: firebaseDatabaseUrl,
      );
      sosDoneRef = db.ref().child('SOS_Done');
      assignedRef = db.ref().child('assigned');
      
      await _loadStats();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing database: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading stats';
      });
    }
  }

  // ============================================================
  // ✅ LOAD REAL STATS FROM FIREBASE
  // ============================================================
  Future<void> _loadStats() async {
    try {
      print('=== LOADING ADMIN STATS ===');
      
      final results = await Future.wait([
        sosDoneRef.once(),
        assignedRef.once(),
      ]);

      final sosDoneSnapshot = results[0];
      final assignedSnapshot = results[1];

      int completedCount = 0;
      if (sosDoneSnapshot.snapshot.value != null) {
        final sosDoneData = Map<dynamic, dynamic>.from(sosDoneSnapshot.snapshot.value as Map);
        completedCount = sosDoneData.length;
        print('📊 Completed emergencies: $completedCount');
      }

      int activeCount = 0;
      if (assignedSnapshot.snapshot.value != null) {
        final assignedData = Map<dynamic, dynamic>.from(assignedSnapshot.snapshot.value as Map);
        
        for (var responderEntry in assignedData.entries) {
          final responderData = Map<dynamic, dynamic>.from(responderEntry.value);
          for (var emergencyEntry in responderData.entries) {
            final emergencyData = Map<dynamic, dynamic>.from(emergencyEntry.value);
            final status = emergencyData['status']?.toString() ?? '';
            
            if (status != 'completed') {
              activeCount++;
            }
          }
        }
        print('📊 Active emergencies: $activeCount');
      }

      final total = completedCount + activeCount;
      print('📊 Total emergencies: $total');

      setState(() {
        _totalRecords = total;
        _activeEmergencies = activeCount;
        _completedEmergencies = completedCount;
      });
      
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() {
        _errorMessage = 'Error loading stats: $e';
      });
    }
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================
  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.shade500,
                      Colors.red.shade700,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Logout?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        FirebaseAuth.instance.signOut().then((_) {
                          Get.offAll(() => const LoginScreen());
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Yes, Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // NAVIGATION FUNCTIONS
  // ============================================================
  void _navigateToResponderHistory() {
    Get.to(() => const ResponderHistoryScreen());
  }

  void _navigateToDocterHistory() {
    Get.to(() => const DocterHistoryScreen());
  }

  // ============================================================
  // BUILD METHOD - FIXED PAGE (NO SCROLL)
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C5C),
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Get.height * 0.17),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Image.asset(
                        'assets/logos/emergencyAppLogo.png',
                        height: Get.height * 0.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Admin Dashboard',
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
              
              Positioned(
                right: 16,
                top: 6,
                child: GestureDetector(
                  onTap: _showLogoutDialog,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red,
                          Colors.redAccent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F4C5C)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0F4C5C).withOpacity(0.1),
                          const Color(0xFF1A7A8C).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0F4C5C).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Admin!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F4C5C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Track, manage, and review all emergency response and doctor records',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Stats Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.history_rounded,
                          'Total Records',
                          _totalRecords.toString(),
                          Colors.blue,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                        _buildStatItem(
                          Icons.pending_actions,
                          'Active',
                          _activeEmergencies.toString(),
                          Colors.orange,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                        _buildStatItem(
                          Icons.check_circle,
                          'Completed',
                          _completedEmergencies.toString(),
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Records Section Title
                  const Text(
                    'Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // View Responder History Button
                  _buildRecordButton(
                    title: 'View Responder History',
                    subtitle: 'View all responder emergency responses',
                    icon: Icons.person_search_rounded,
                    color1: const Color(0xFF0F4C5C),
                    color2: const Color(0xFF1A7A8C),
                    onTap: _navigateToResponderHistory,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // View Docter History Button
                  _buildRecordButton(
                    title: 'View Docter History',
                    subtitle: 'View all docter records',
                    icon: Icons.medical_services_rounded,
                    color1: const Color(0xFF2C3E50),
                    color2: const Color(0xFF4A6A7A),
                    onTap: _navigateToDocterHistory,
                  ),
                  
                  const Spacer(),
                  
                  
                  
                ],
              ),
            ),
    );
  }

  // ============================================================
  // RECORD BUTTON WIDGET
  // ============================================================
  Widget _buildRecordButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
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
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAT ITEM WIDGET
  // ============================================================
  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}