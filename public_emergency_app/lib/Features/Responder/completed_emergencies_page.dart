import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Common Widgets/constants.dart';

class CompletedEmergenciesPage extends StatefulWidget {
  final String responderId;
  
  const CompletedEmergenciesPage({
    Key? key,
    required this.responderId,
  }) : super(key: key);

  @override
  State<CompletedEmergenciesPage> createState() => _CompletedEmergenciesPageState();
}

class _CompletedEmergenciesPageState extends State<CompletedEmergenciesPage> {
  late DatabaseReference sosDoneRef;
  final String firebaseDatabaseUrl =
      'https://emergencyresponse-0xyvwt-default-rtdb.asia-southeast1.firebasedatabase.app';
  bool _isLoading = true;
  String _selectedFilter = 'Latest';
  String _searchQuery = '';
  Set<String> _expandedCards = {};
  
  // Cache for fetched data
  List<MapEntry<dynamic, dynamic>> _allEntries = [];
  List<MapEntry<dynamic, dynamic>> _filteredEntries = [];
  bool _dataFetched = false;

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
      await _fetchDataOnce();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing database: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDataOnce() async {
    try {
      final snapshot = await sosDoneRef
          .orderByChild('completedBy/uid')
          .equalTo(widget.responderId)
          .once();
      
      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final entries = data.entries.toList();
        
        setState(() {
          _allEntries = entries;
          _dataFetched = true;
          _applyFilters();
        });
      } else {
        setState(() {
          _allEntries = [];
          _filteredEntries = [];
          _dataFetched = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() {
        _dataFetched = true;
      });
    }
  }

  // ============================================================
  // ✅ APPLY FILTERS
  // ============================================================
  void _applyFilters() {
    List<MapEntry<dynamic, dynamic>> filtered = List.from(_allEntries);
    
    // Filter by Search Query (userName or responderName)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((entry) {
        final dataMap = Map<String, dynamic>.from(entry.value as Map);
        final userInfo = dataMap['userInfo'] ?? {};
        final responderInfo = dataMap['completedBy'] ?? {};
        
        final userName = userInfo['name']?.toString().toLowerCase() ?? '';
        final responderName = responderInfo['name']?.toString().toLowerCase() ?? '';
        
        return userName.contains(query) || responderName.contains(query);
      }).toList();
    }
    
    // Sort by Latest / Oldest
    if (_selectedFilter == 'Latest') {
      filtered.sort((a, b) {
        final aTime = (a.value as Map)['completedAt']?.toString() ?? '';
        final bTime = (b.value as Map)['completedAt']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });
    } else {
      filtered.sort((a, b) {
        final aTime = (a.value as Map)['completedAt']?.toString() ?? '';
        final bTime = (b.value as Map)['completedAt']?.toString() ?? '';
        return aTime.compareTo(bTime);
      });
    }
    
    setState(() {
      _filteredEntries = filtered;
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
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchDataOnce();
    setState(() {
      _isLoading = false;
    });
  }

  // ============================================================
  // ✅ HELPER: Format DateTime as string
  // ============================================================
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$hour:$minute:$second $day/$month/$year';
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown';
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

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      Get.snackbar(
        'Error',
        'No phone number available',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }
    
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        Get.snackbar(
          'Error',
          'Cannot make call',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Cannot make call',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
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
  // ✅ REDESIGNED FILTER WIDGET - No count badges on buttons
  // ============================================================
  Widget _buildFilterWidget() {
    final int totalCount = _filteredEntries.length;

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
        children: [
          Expanded(
            child: _buildFilterChip(
              label: 'Latest',
              filterType: 'Latest',
              icon: Icons.arrow_downward,
              isSelected: _selectedFilter == 'Latest',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFilterChip(
              label: 'Oldest',
              filterType: 'Oldest',
              icon: Icons.arrow_upward,
              isSelected: _selectedFilter == 'Oldest',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterType,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _handleFilterClick(filterType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Color(color),
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
                      'Completed Emergencies',
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
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(color),
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
          ? const Center(child: CircularProgressIndicator())
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
                        hintText: 'Search by User Name...',
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
                
                // ✅ FILTER WIDGET - No count badges on buttons
                _buildFilterWidget(),
                
                // ✅ Quantity Display - Shows total count
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
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_filteredEntries.length} Completed',
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
                          '${_filteredEntries.length} result${_filteredEntries.length != 1 ? 's' : ''} found',
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
                  child: _filteredEntries.isEmpty && _dataFetched
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No completed emergencies yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No results found for your search'
                                    : 'Swipe right on an emergency to mark it as done',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _refreshData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(color),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredEntries[index];
                              final dataMap = Map<String, dynamic>.from(entry.value as Map);
                              final userInfo = dataMap['userInfo'] ?? {};
                              final responderInfo = dataMap['completedBy'] ?? {};
                              final emergencyData = dataMap['emergencyData'] ?? {};
                              
                              final String userName = userInfo['name'] ?? 'Unknown User';
                              final String userPhone = userInfo['phone'] ?? '';
                              final String userAddress = emergencyData['userAddress']?.toString() ?? 'No Address';
                              final String completedAt = dataMap['completedAt']?.toString() ?? '';
                              final String responderName = responderInfo['name'] ?? 'Unknown Responder';
                              final String responderType = responderInfo['type'] ?? 'Responder';
                              final String distance = dataMap['distance'] ?? '';
                              final String emergencyDescription = emergencyData['description'] ?? '';
                              
                              // ✅ Get SOS Time from ROOT level
                              String sosTime = 'Unknown time';
                              if (dataMap['sosTimeFormatted'] != null) {
                                sosTime = dataMap['sosTimeFormatted'].toString();
                              } else if (dataMap['sosTime'] != null) {
                                try {
                                  final sosTimeMs = dataMap['sosTime'] as int;
                                  final sosDateTime = DateTime.fromMillisecondsSinceEpoch(sosTimeMs);
                                  sosTime = _formatDateTime(sosDateTime);
                                } catch (e) {
                                  sosTime = 'Unknown time';
                                }
                              }
                              
                              String totalTime = dataMap['responseTime']?.toString() ?? 'N/A';
                              
                              final String cardKey = entry.key.toString();
                              final bool isExpanded = _expandedCards.contains(cardKey);

                              return GestureDetector(
                                onTap: () => _toggleExpand(cardKey),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0F4C5C),
                                        Color(0xFF1A7A8C),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.shade400,
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green.shade300.withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Completed',
                                                    style: TextStyle(
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
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _formatDate(completedAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _toggleExpand(cardKey),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.15),
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
                                                color: Colors.white.withValues(alpha: 0.2),
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
                                                          color: Colors.white.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: Colors.white.withValues(alpha: 0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.person_outline,
                                                              color: Colors.white.withValues(alpha: 0.7),
                                                              size: 10,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'By: $responderName',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.white.withValues(alpha: 0.9),
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
                                                          color: Colors.white.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: Colors.white.withValues(alpha: 0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          responderType,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.white.withValues(alpha: 0.9),
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
                                        
                                        // Expanded Content
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
                                                color: Colors.white.withValues(alpha: 0.2),
                                              ),
                                              const SizedBox(height: 12),
                                              
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.green.shade400.withValues(alpha: 0.2),
                                                      Colors.green.shade600.withValues(alpha: 0.1),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.green.shade300.withValues(alpha: 0.3),
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
                                                        color: Colors.white.withValues(alpha: 0.9),
                                                      ),
                                                    ),
                                                    Text(
                                                      totalTime,
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
                                                            color: Colors.white.withValues(alpha: 0.9),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      sosTime,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white.withValues(alpha: 0.8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 8),
                                              
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
                                                            color: Colors.white.withValues(alpha: 0.9),
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
                                                        color: Colors.white.withValues(alpha: 0.8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
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
                                                            color: Colors.white.withValues(alpha: 0.9),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () => _makePhoneCall(userPhone),
                                                      child: Text(
                                                        userPhone.isNotEmpty ? userPhone : 'No Phone',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.blue.shade200,
                                                          decoration: userPhone.isNotEmpty ? TextDecoration.underline : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
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
                                                            color: Colors.white.withValues(alpha: 0.9),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      distance.isNotEmpty ? distance : '0 km',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white.withValues(alpha: 0.8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 8),
                                              
                                              if (emergencyDescription.isNotEmpty) ...[
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
                                                              color: Colors.white.withValues(alpha: 0.9),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          emergencyDescription,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.white.withValues(alpha: 0.8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}