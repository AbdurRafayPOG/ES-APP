import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref('Users');

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  
  // Filter type: 'all' or 'banned'
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> users = [];
        data.forEach((uid, value) {
          if (value is Map) {
            users.add({
              'uid': uid,
              'name': value['UserName'] ?? 'Unknown',
              'email': value['email'] ?? '',
              'phone': value['Phone'] ?? '',
              'userType': value['UserType'] ?? 'User',
              'banned': value['banned'] ?? 'none',
              'banReason': value['banReason'] ?? '',
              'banUntil': value['banUntil'] ?? '',
            });
          }
        });
        if (mounted) {
          setState(() {
            _allUsers = users;
            _applyFilterAndSearch();
          });
        }
      }
    });
  }

  void _applyFilterAndSearch() {
    List<Map<String, dynamic>> filtered = _filterType == 'banned'
        ? _allUsers.where((u) => u['banned'] != 'none').toList()
        : _allUsers;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((u) {
        final name = u['name'].toString().toLowerCase();
        final email = u['email'].toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
            email.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilterAndSearch();
    });
  }

  // ============================================================
  // REDESIGNED USER PROFILE BOTTOM SHEET
  // ============================================================
  void _showUserProfile(Map<String, dynamic> user) {
    final isBanned = user['banned'] != 'none';
    final banType = user['banned'];
    final isPermanent = banType == 'permanent';
    
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Header with avatar and name
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isBanned
                          ? [Colors.red.shade400, Colors.red.shade700]
                          : [const Color(0xFF0F4C5C), const Color(0xFF1A7A8C)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      user['name'].isNotEmpty
                          ? user['name'][0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isBanned ? Colors.red.shade700 : const Color(0xFF0F4C5C),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isBanned
                                    ? [Colors.red.shade400, Colors.red.shade700]
                                    : [const Color(0xFF0F4C5C), const Color(0xFF1A7A8C)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user['userType'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isBanned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPermanent
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPermanent
                                      ? Colors.red.shade200
                                      : Colors.orange.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPermanent
                                        ? Icons.block_rounded
                                        : Icons.timer_rounded,
                                    color: isPermanent
                                        ? Colors.redAccent
                                        : Colors.orange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPermanent ? 'Permanent Ban' : 'Temp Ban',
                                    style: TextStyle(
                                      color: isPermanent
                                          ? Colors.redAccent
                                          : Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            // Info Cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user['email'],
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: user['phone'].isNotEmpty ? user['phone'] : 'Not provided',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ban Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isBanned
                      ? [Colors.red.shade50, Colors.orange.shade50]
                      : [Colors.green.shade50, Colors.teal.shade50],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isBanned
                      ? (isPermanent ? Colors.red.shade200 : Colors.orange.shade200)
                      : Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBanned
                          ? (isPermanent ? Colors.red.shade100 : Colors.orange.shade100)
                          : Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBanned ? Icons.block_rounded : Icons.check_circle_rounded,
                      color: isBanned
                          ? (isPermanent ? Colors.redAccent : Colors.orange)
                          : Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBanned ? 'Banned' : 'Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isBanned
                                ? (isPermanent ? Colors.redAccent : Colors.orange)
                                : Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        if (isBanned && user['banReason'].isNotEmpty)
                          Text(
                            'Reason: ${user['banReason']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        if (isBanned && !isPermanent && user['banUntil'].isNotEmpty)
                          Text(
                            'Until: ${user['banUntil']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (!isBanned)
                          const Text(
                            'Full access granted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ban / Unban action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBanned ? Colors.green : Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: Icon(
                  isBanned
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  isBanned ? 'Unban User' : 'Ban User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
                  Get.back();
                  if (isBanned) {
                    _showUnbanDialog(user);
                  } else {
                    _showBanDialog(user);
                  }
                },
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BAN DIALOG
  // ============================================================
  void _showBanDialog(Map<String, dynamic> user) {
    String selectedBan = 'temporary';
    final reasonController = TextEditingController(text: user['banReason']);
    DateTime? banUntilDate;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade700],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ban User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user['name'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Ban type
                  const Text(
                    'Ban Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _BanTypeChip(
                        label: 'Temporary',
                        selected: selectedBan == 'temporary',
                        color: Colors.orange,
                        onTap: () => setDialogState(() => selectedBan = 'temporary'),
                      ),
                      const SizedBox(width: 10),
                      _BanTypeChip(
                        label: 'Permanent',
                        selected: selectedBan == 'permanent',
                        color: Colors.redAccent,
                        onTap: () => setDialogState(() => selectedBan = 'permanent'),
                      ),
                    ],
                  ),

                  if (selectedBan == 'temporary') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Ban Until',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: const Color(0xFF0F4C5C),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => banUntilDate = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: banUntilDate != null
                                ? const Color(0xFF0F4C5C)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: banUntilDate != null
                              ? const Color(0xFF0F4C5C).withOpacity(0.05)
                              : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: banUntilDate != null
                                  ? const Color(0xFF0F4C5C)
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              banUntilDate != null
                                  ? '${banUntilDate!.day}/${banUntilDate!.month}/${banUntilDate!.year}'
                                  : 'Select end date',
                              style: TextStyle(
                                color: banUntilDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Reason
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFF0F4C5C)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: const Color(0xFF0F4C5C)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedBan == 'temporary' && banUntilDate == null) {
                              Get.snackbar(
                                'Select Date',
                                'Please select a ban end date',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            final banUntilStr = selectedBan == 'temporary'
                                ? '${banUntilDate!.day}/${banUntilDate!.month}/${banUntilDate!.year}'
                                : '';

                            _ref.child(user['uid']).update({
                              'banned': selectedBan,
                              'banReason': reasonController.text.trim(),
                              'banUntil': banUntilStr,
                            });

                            Get.back();
                            Get.snackbar(
                              'User Banned',
                              selectedBan == 'permanent'
                                  ? '${user['name']} permanently banned.'
                                  : '${user['name']} banned until $banUntilStr.',
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Ban',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // UNBAN DIALOG
  // ============================================================
  void _showUnbanDialog(Map<String, dynamic> user) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unban User?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will restore full access for ${user['name']}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF0F4C5C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: const Color(0xFF0F4C5C)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _ref.child(user['uid']).update({
                          'banned': 'none',
                          'banReason': '',
                          'banUntil': '',
                        });
                        Get.back();
                        Get.snackbar(
                          'User Unbanned',
                          '${user['name']} has been unbanned.',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Unban',
                        style: TextStyle(
                          color: Colors.white,
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
  // BUILD METHOD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    // ✅ Calculate counts based on filtered results when searching
    final int totalUsers = _searchQuery.isNotEmpty 
        ? _filteredUsers.length 
        : _allUsers.length;
    
    final int bannedUsers = _searchQuery.isNotEmpty
        ? _filteredUsers.where((u) => u['banned'] != 'none').length
        : _allUsers.where((u) => u['banned'] != 'none').length;
    
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
          preferredSize: Size.fromHeight(Get.height * 0.16),
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
                        height: Get.height * 0.07,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Users',
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
                left: 12,
                top: 6,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.white,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: const Color(0xFF0F4C5C),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          
          // FILTER CHIPS WITH COUNTERS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Users',
                  filterType: 'all',
                  count: totalUsers,
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  label: 'Banned',
                  filterType: 'banned',
                  count: bannedUsers,
                ),
              ],
            ),
          ),
          
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredUsers.length} user${_filteredUsers.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty 
                              ? Icons.search_off_rounded 
                              : Icons.people_outline_rounded,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No users found'
                              : 'No users added yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isBanned = user['banned'] != 'none';
                      final banType = user['banned'];
                      final isPermanent = banType == 'permanent';

                      // ============================================================
                      // REDESIGNED USER CARD
                      // ============================================================
                      return GestureDetector(
                        onTap: () => _showUserProfile(user),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isBanned
                                  ? [
                                      isPermanent
                                          ? Colors.red.shade50
                                          : Colors.orange.shade50,
                                      Colors.white,
                                    ]
                                  : [
                                      const Color(0xFF0F4C5C).withOpacity(0.05),
                                      Colors.white,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isBanned
                                  ? (isPermanent
                                      ? Colors.red.shade200
                                      : Colors.orange.shade200)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isBanned
                                        ? [Colors.red.shade300, Colors.red.shade600]
                                        : [const Color(0xFF0F4C5C), const Color(0xFF1A7A8C)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    user['name'].isNotEmpty
                                        ? user['name'][0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isBanned
                                          ? Colors.red.shade700
                                          : const Color(0xFF0F4C5C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 14),
                              
                              // User info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isBanned)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPermanent
                                                  ? Colors.red.shade50
                                                  : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isPermanent
                                                    ? Colors.red.shade200
                                                    : Colors.orange.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isPermanent
                                                      ? Icons.block_rounded
                                                      : Icons.timer_rounded,
                                                  color: isPermanent
                                                      ? Colors.redAccent
                                                      : Colors.orange,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isPermanent ? 'Banned' : 'Temp',
                                                  style: TextStyle(
                                                    color: isPermanent
                                                        ? Colors.redAccent
                                                        : Colors.orange,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          color: Colors.grey.shade500,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user['email'],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (user['phone'].isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            color: Colors.grey.shade500,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            user['phone'],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (isBanned && user['banReason'].isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: Colors.orange.shade400,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Reason: ${user['banReason']}',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (isBanned && !isPermanent && user['banUntil'].isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: Colors.orange.shade400,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Until: ${user['banUntil']}',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Action buttons
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Ban/Unban button
                                  GestureDetector(
                                    onTap: () => isBanned
                                        ? _showUnbanDialog(user)
                                        : _showBanDialog(user),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isBanned
                                            ? Colors.green.withOpacity(0.12)
                                            : Colors.redAccent.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isBanned
                                            ? Icons.lock_open_rounded
                                            : Icons.block_rounded,
                                        color: isBanned
                                            ? Colors.green
                                            : Colors.redAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // View profile indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.grey.shade400,
                                          size: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP WITH COUNTER
  // ============================================================
  Widget _buildFilterChip({
    required String label,
    required String filterType,
    required int count,
  }) {
    final isSelected = _filterType == filterType;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = filterType;
            _applyFilterAndSearch();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F4C5C),
                      const Color(0xFF1A7A8C),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F4C5C)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F4C5C).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BAN TYPE CHIP
// ============================================================
class _BanTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _BanTypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 16,
              ),
            if (selected) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.black54,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}