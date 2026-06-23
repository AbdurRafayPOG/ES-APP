import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';

class UserEmergencyHistoryPage extends StatefulWidget {
  final String userId;
  
  const UserEmergencyHistoryPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserEmergencyHistoryPage> createState() => _UserEmergencyHistoryPageState();
}

class _UserEmergencyHistoryPageState extends State<UserEmergencyHistoryPage> {
  late DatabaseReference sosDoneRef;
  final String firebaseDatabaseUrl =
      'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app';
  
  // Filter state
  String _selectedTypeFilter = 'All'; // All, Police, Firefighter
  String _searchQuery = '';
  
  List<Map<String, dynamic>> _allHistoryEntries = [];
  List<Map<String, dynamic>> _filteredHistoryEntries = [];
  Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, Map<String, dynamic>> _responderCache = {};
  bool _isLoading = true;
  String _errorMessage = '';
  Set<String> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      await Firebase.initializeApp();
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: firebaseDatabaseUrl,
      );
      sosDoneRef = db.ref().child('SOS_Done');
      
      await _loadAllDataAtOnce();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing database: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data';
      });
    }
  }

  String _normalizeType(String? type) {
    if (type == null) return '';
    final normalized = type.trim().toLowerCase();
    if (normalized == 'firefighter' || normalized == 'fire fighter' || normalized == 'fire-fighter') {
      return 'Firefighter';
    }
    if (normalized == 'police') {
      return 'Police';
    }
    return type;
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$hour:$minute:$second $day/$month/$year';
  }

  // ============================================================
  // LOAD ALL DATA FROM SOS_Done - FILTERED BY USER ID
  // ============================================================
  Future<void> _loadAllDataAtOnce() async {
    try {
      print('=== LOADING HISTORY FOR USER: ${widget.userId} ===');
      
      final usersRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: firebaseDatabaseUrl,
      ).ref('Users');
      
      final respondersRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: firebaseDatabaseUrl,
      ).ref('Responders');

      final results = await Future.wait([
        sosDoneRef.once(),
        usersRef.once(),
        respondersRef.once(),
      ]);

      final sosDoneSnapshot = results[0];
      final usersSnapshot = results[1];
      final respondersSnapshot = results[2];

      // Build user cache
      if (usersSnapshot.snapshot.value != null) {
        final usersData = Map<dynamic, dynamic>.from(usersSnapshot.snapshot.value as Map);
        for (var userEntry in usersData.entries) {
          final userId = userEntry.key;
          final userData = Map<dynamic, dynamic>.from(userEntry.value);
          _userCache[userId] = {
            'name': userData['UserName']?.toString() ?? 'Unknown User',
            'phone': userData['Phone']?.toString() ?? '',
            'email': userData['email']?.toString() ?? '',
            'address': userData['address']?.toString() ?? '',
          };
        }
      }

      // Build responder cache
      if (respondersSnapshot.snapshot.value != null) {
        final respondersData = Map<dynamic, dynamic>.from(respondersSnapshot.snapshot.value as Map);
        for (var responderEntry in respondersData.entries) {
          final responderId = responderEntry.key;
          final responderData = Map<dynamic, dynamic>.from(responderEntry.value);
          final rawType = responderData['UserType']?.toString() ?? 'Unknown';
          _responderCache[responderId] = {
            'name': responderData['UserName']?.toString() ?? 'Unknown',
            'type': _normalizeType(rawType),
            'phone': responderData['Phone']?.toString() ?? '',
            'email': responderData['email']?.toString() ?? '',
          };
        }
      }

      final List<Map<String, dynamic>> entries = [];

      // ============================================================
      // PROCESS COMPLETED EMERGENCIES (SOS_Done) - FILTER BY USER
      // ============================================================
      if (sosDoneSnapshot.snapshot.value != null) {
        print('Processing COMPLETED emergencies from SOS_Done...');
        final sosDoneData = Map<dynamic, dynamic>.from(sosDoneSnapshot.snapshot.value as Map);

        for (var entry in sosDoneData.entries) {
          final emergencyId = entry.key;
          final emergencyData = Map<dynamic, dynamic>.from(entry.value);
          
          final userInfo = emergencyData['userInfo'] ?? {};
          final userId = userInfo['uid']?.toString() ?? '';
          
          if (userId != widget.userId) continue;
          
          final userDetails = _userCache[userId] ?? {
            'name': userInfo['name']?.toString() ?? 'Unknown User',
            'phone': userInfo['phone']?.toString() ?? '',
            'email': userInfo['email']?.toString() ?? '',
            'address': userInfo['address']?.toString() ?? '',
          };

          final responderInfo = emergencyData['completedBy'] ?? {};
          final responderId = responderInfo['uid']?.toString() ?? '';
          final responderDetails = _responderCache[responderId] ?? {
            'name': responderInfo['name']?.toString() ?? 'Unknown',
            'type': _normalizeType(responderInfo['type']?.toString()),
            'phone': responderInfo['phone']?.toString() ?? '',
            'email': responderInfo['email']?.toString() ?? '',
          };

          final emergencyDataFields = emergencyData['emergencyData'] ?? {};
          
          String userAddress = emergencyDataFields['userAddress']?.toString() ?? '';
          if (userAddress.isEmpty || userAddress == 'No Address') {
            userAddress = userDetails['address'] ?? 'No Address';
          }

          String sosTime = 'Unknown time';
          if (emergencyData['sosTimeFormatted'] != null) {
            sosTime = emergencyData['sosTimeFormatted'].toString();
          } else if (emergencyData['sosTime'] != null) {
            try {
              final sosTimeMs = emergencyData['sosTime'] as int;
              final sosDateTime = DateTime.fromMillisecondsSinceEpoch(sosTimeMs);
              sosTime = _formatDateTime(sosDateTime);
            } catch (e) {
              sosTime = 'Unknown time';
            }
          }

          String responseTime = emergencyData['responseTime']?.toString() ?? 'N/A';

          entries.add({
            'emergencyId': emergencyId,
            'responderId': responderId,
            'responderName': responderDetails['name'] ?? 'Unknown',
            'responderType': responderDetails['type'] ?? 'Unknown',
            'responderPhone': responderDetails['phone'] ?? '',
            'userName': userDetails['name'] ?? 'Unknown User',
            'userPhone': userDetails['phone'] ?? '',
            'userEmail': userDetails['email'] ?? '',
            'userAddress': userAddress,
            'userLat': emergencyDataFields['userLat']?.toString() ?? '0',
            'userLong': emergencyDataFields['userLong']?.toString() ?? '0',
            'time': sosTime,
            'assignedAt': emergencyData['assignedAt']?.toString() ?? '',
            'completedAt': emergencyData['completedAt']?.toString() ?? '',
            'distance': emergencyData['distance']?.toString() ?? '0 km',
            'responseTime': responseTime,
            'description': emergencyDataFields['description']?.toString() ?? '',
            'status': 'Completed',
            'isCompleted': true,
          });
        }
      }

      entries.sort((a, b) {
        final aTime = a['completedAt']?.toString() ?? '';
        final bTime = b['completedAt']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });

      print('Total history entries found for user ${widget.userId}: ${entries.length}');

      setState(() {
        _allHistoryEntries = entries;
        _applyFilters();
        if (entries.isEmpty) {
          _errorMessage = 'No emergencies found';
        }
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _errorMessage = 'Error loading history: $e';
      });
    }
  }

  // ============================================================
  // ✅ APPLY FILTERS - Like UsersScreen
  // ============================================================
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allHistoryEntries);
    
    // Filter by Type (All / Police / Firefighter)
    if (_selectedTypeFilter != 'All') {
      filtered = filtered.where((entry) {
        final responderType = entry['responderType']?.toString() ?? '';
        final normalizedType = _normalizeType(responderType);
        return normalizedType == _selectedTypeFilter;
      }).toList();
    }
    
    // Filter by Search Query (userName or responderName)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((entry) {
        final userName = entry['userName']?.toString().toLowerCase() ?? '';
        final responderName = entry['responderName']?.toString().toLowerCase() ?? '';
        return userName.contains(query) || responderName.contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredHistoryEntries = filtered;
    });
  }

  // ============================================================
  // ✅ HANDLE SEARCH
  // ============================================================
  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  // ============================================================
  // ✅ HANDLE FILTER CLICK
  // ============================================================
  void _handleFilterClick(String filter) {
    setState(() {
      _selectedTypeFilter = filter;
      _applyFilters();
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return isoString;
    }
  }

  void _toggleExpand(String key) {
    setState(() {
      if (_expandedCards.contains(key)) {
        _expandedCards.remove(key);
      } else {
        _expandedCards.add(key);
      }
    });
  }

  // ============================================================
  // ✅ REDESIGNED FILTER WIDGET - With Counts
  // ============================================================
  Widget _buildFilterWidget() {
    final int totalCount = _allHistoryEntries.length;
    final int policeCount = _allHistoryEntries.where((entry) {
      final responderType = entry['responderType']?.toString() ?? '';
      final normalizedType = _normalizeType(responderType);
      return normalizedType == 'Police';
    }).length;
    final int firefighterCount = _allHistoryEntries.where((entry) {
      final responderType = entry['responderType']?.toString() ?? '';
      final normalizedType = _normalizeType(responderType);
      return normalizedType == 'Firefighter';
    }).length;

    final filters = ['All', 'Police', 'Firefighter'];
    final icons = {
      'All': Icons.list_alt,
      'Police': Icons.local_police,
      'Firefighter': Icons.fire_truck,
    };
    final counts = {
      'All': totalCount,
      'Police': policeCount,
      'Firefighter': firefighterCount,
    };
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedTypeFilter == filter;
          final count = counts[filter] ?? 0;
          
          return Expanded(
            child: _buildFilterChip(
              label: filter,
              filterType: filter,
              icon: icons[filter] ?? Icons.list_alt,
              count: count,
              isSelected: isSelected,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterType,
    required IconData icon,
    required int count,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _handleFilterClick(filterType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F4C5C),
                    const Color(0xFF0F4C5C).withValues(alpha: 0.8),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? null : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? const Color(0xFF0F4C5C) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 12,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD METHOD
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                      'Emergency History',
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
                    'Loading history...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // ✅ SEARCH BAR
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
                      onChanged: _handleSearch,
                      decoration: InputDecoration(
                        hintText: 'Search by Responder Name...',
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
                
                // ✅ FILTER WIDGET
                _buildFilterWidget(),
                
                // ✅ Quantity Display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0F4C5C),
                              const Color(0xFF0F4C5C).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_filteredHistoryEntries.length} Records',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          '${_filteredHistoryEntries.length} result${_filteredHistoryEntries.length != 1 ? 's' : ''} found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _filteredHistoryEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 70,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No history found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage.isNotEmpty ? _errorMessage : 'No emergencies yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAllDataAtOnce,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F4C5C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          itemCount: _filteredHistoryEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredHistoryEntries[index];
                            return _buildHistoryCard(entry);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // HISTORY CARD - UNCHANGED
  // ============================================================
  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final isCompleted = entry['isCompleted'] ?? false;
    final responderName = entry['responderName'] ?? 'Unknown';
    final responderType = _normalizeType(entry['responderType']?.toString());
    final responderPhone = entry['responderPhone'] ?? '';
    final userName = entry['userName'] ?? 'Unknown User';
    final userPhone = entry['userPhone'] ?? '';
    final userEmail = entry['userEmail'] ?? '';
    final userAddress = entry['userAddress'] ?? 'No Address';
    final time = entry['time'] ?? '';
    final completedAt = entry['completedAt'] ?? '';
    final assignedAt = entry['assignedAt'] ?? '';
    final distance = entry['distance'] ?? '0 km';
    final responseTime = entry['responseTime'] ?? 'N/A';
    final description = entry['description'] ?? '';
    final status = entry['status'] ?? 'Active';

    final String cardKey = entry['emergencyId'] ?? DateTime.now().toString();
    final bool isExpanded = _expandedCards.contains(cardKey);

    return GestureDetector(
      onTap: () => _toggleExpand(cardKey),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isCompleted ? const Color(0xFF0F4C5C) : const Color(0xFF1A3A4C),
              isCompleted ? const Color(0xFF1A7A8C) : const Color(0xFF2A5A6C),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Status, Time, and Expand Icon
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.orange.shade400, Colors.orange.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green.shade300.withOpacity(0.3)
                            : Colors.orange.shade300.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.pending,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDate(isCompleted ? completedAt : assignedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expand/Collapse Arrow Icon
                  GestureDetector(
                    onTap: () => _toggleExpand(cardKey),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpanded 
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // User Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'By: $responderName',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                responderType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // ============================================
              // EXPANDED CONTENT
              // ============================================
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    
                    // Response Time (only for completed)
                    if (isCompleted) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400.withOpacity(0.2),
                              Colors.green.shade600.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.shade300.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: Colors.green.shade300,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Response Time: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              responseTime,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // SOS Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SOS:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Row(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Address:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            userAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Phone
                    if (userPhone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Phone:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              userPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Email
                    if (userEmail.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Email:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Distance (only for completed)
                    if (isCompleted) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.route,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Distance:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              distance,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Description
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Desc:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}