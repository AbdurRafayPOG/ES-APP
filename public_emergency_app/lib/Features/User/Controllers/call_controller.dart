import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:public_emergency_app/Services/zego_service.dart';
import 'package:public_emergency_app/Features/User/Screens/VoicenVideoCall/keys.dart';
import 'dart:async';

class CallController extends GetxController {
  static CallController get to => Get.find<CallController>();
  
  final RxBool isCallInProgress = false.obs;
  final RxBool isCallIncoming = false.obs;
  final RxString incomingCallerName = ''.obs;
  final RxString incomingCallerID = ''.obs;
  final RxString incomingCallID = ''.obs;
  
  final ZegoService _zegoService = ZegoService();
  
  String? _currentCallID;
  
  // Track if ZEGO is fully connected
  bool _isZegoReady = false;
  Completer<void>? _zegoReadyCompleter;
  bool _isInitializing = false;

  @override
  void onInit() {
    super.onInit();
    _setupCallbacks();
  }
  
  void _setupCallbacks() {
    _zegoService.onCallAccepted = (callID, callerID, callerName) {
      print("✅✅✅ CallController: Call accepted - $callID");
      isCallInProgress.value = true;
      isCallIncoming.value = false;
    };
    
    _zegoService.onCallRejected = (callID, callerID) {
      print("❌❌❌ CallController: Call rejected - $callID");
      isCallInProgress.value = false;
      isCallIncoming.value = false;
      incomingCallerName.value = '';
      incomingCallerID.value = '';
      incomingCallID.value = '';
    };
  }
  
  void initializeZego(String userID, String userName) {
    print("🔵🔵🔵 initializeZego CALLED");
    print("   User ID: $userID");
    print("   User Name: $userName");
    _zegoService.initialize(
      userID: userID,
      userName: userName,
    );
  }
  
  /// Initialize ZEGO and return a Future that completes when ZEGO is ready
  Future<void> initializeCallInvitationService(String userID, String userName) async {
    if (_isInitializing) {
      // Wait for the ongoing initialization to complete
      await _zegoReadyCompleter?.future;
      return;
    }
    
    _isInitializing = true;
    _zegoReadyCompleter = Completer<void>();
    
    print("========================================");
    print("🔴🔴🔴 initializeCallInvitationService CALLED 🔴🔴🔴");
    print("   User ID: $userID");
    print("   User Name: $userName");
    print("========================================");
    
    String finalUserName = userName.trim();
    if (finalUserName.isEmpty) {
      print("⚠️⚠️⚠️ USERNAME WAS EMPTY! Using 'User' as fallback");
      finalUserName = 'User';
    }
    
    Keys.setUserInfo(userID, finalUserName);
    print("📱 After Keys.setUserInfo - Keys.userName: ${Keys.userName}");
    print("📱 After Keys.setUserInfo - Keys.userId: ${Keys.userId}");
    
    try {
      print("🟢 Calling ZegoUIKitPrebuiltCallInvitationService().init()...");
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: Keys.appId,
        appSign: Keys.appSign,
        userID: userID,
        userName: finalUserName,
        plugins: [ZegoUIKitSignalingPlugin()],
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onOutgoingCallAccepted: (String callID, ZegoCallUser callee) {
            print("📞 Outgoing call accepted by ${callee.name}");
            isCallInProgress.value = true;
            // Mark as ready on first successful call
            if (!_isZegoReady && _zegoReadyCompleter != null && !_zegoReadyCompleter!.isCompleted) {
              _isZegoReady = true;
              _zegoReadyCompleter!.complete();
            }
          },
          onOutgoingCallDeclined: (String callID, ZegoCallUser callee, String customData) {
            print("📞 Outgoing call declined by ${callee.name}");
            isCallInProgress.value = false;
            Get.snackbar(
              'Call Declined',
              '${callee.name} declined your call',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          },
          onOutgoingCallTimeout: (String callID, List<ZegoCallUser> callees, bool isVideoCall) {
            print("📞 Outgoing call timed out");
            isCallInProgress.value = false;
            final calleeNames = callees.map((user) => user.name).join(', ');
            Get.snackbar(
              'Call Timeout',
              '$calleeNames did not answer your call',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          },
          onIncomingCallReceived: (
            String callID,
            ZegoCallUser caller,
            ZegoCallType callType,
            List<ZegoCallUser> callees,
            String customData,
          ) {
            print("📞 Incoming call received from ${caller.name}");
            isCallIncoming.value = true;
            incomingCallerName.value = caller.name;
            incomingCallerID.value = caller.id;
            incomingCallID.value = callID;
            // Mark as ready when we receive a call
            if (!_isZegoReady && _zegoReadyCompleter != null && !_zegoReadyCompleter!.isCompleted) {
              _isZegoReady = true;
              _zegoReadyCompleter!.complete();
            }
          },
          onIncomingCallCanceled: (
            String callID,
            ZegoCallUser caller,
            String customData,
          ) {
            print("📞 Incoming call cancelled by ${caller.name}");
            isCallIncoming.value = false;
            incomingCallerName.value = '';
            incomingCallerID.value = '';
            incomingCallID.value = '';
          },
          onIncomingCallTimeout: (String callID, ZegoCallUser caller) {
            print("📞 Incoming call timed out");
            isCallIncoming.value = false;
            incomingCallerName.value = '';
            incomingCallerID.value = '';
            incomingCallID.value = '';
          },
        ),
      );
      
      print("✅✅✅ ZEGO init() COMPLETED SUCCESSFULLY ✅✅✅");
      print("========================================");
      
      // After init, wait 3 seconds for signaling to connect
      print("⏳ Waiting 3 seconds for ZEGO signaling to connect...");
      await Future.delayed(const Duration(seconds: 3));
      
      _isZegoReady = true;
      if (_zegoReadyCompleter != null && !_zegoReadyCompleter!.isCompleted) {
        _zegoReadyCompleter!.complete();
      }
      print("✅ ZEGO signaling is ready!");
      print("========================================");
      
    } catch (e) {
      print("❌❌❌ ZEGO init() FAILED ❌❌❌");
      print("   Error: $e");
      print("========================================");
      // Even on error, mark as ready so app doesn't hang
      _isZegoReady = true;
      if (_zegoReadyCompleter != null && !_zegoReadyCompleter!.isCompleted) {
        _zegoReadyCompleter!.complete();
      }
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Wait for ZEGO to be ready (silent wait)
  Future<void> waitForZegoReady() async {
    // If already ready, return immediately
    if (_isZegoReady) {
      return;
    }
    
    // If initializing, wait for the completer
    if (_isInitializing && _zegoReadyCompleter != null) {
      print("⏳ Waiting for ZEGO initialization to complete...");
      await _zegoReadyCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print("⚠️ ZEGO wait timeout, proceeding anyway");
          _isZegoReady = true;
          return;
        },
      );
      return;
    }
    
    // If not initialized at all, wait a moment then proceed
    print("⏳ ZEGO not initialized, waiting a moment...");
    await Future.delayed(const Duration(milliseconds: 500));
    _isZegoReady = true;
  }
  
  Future<void> sendInvitation({
    required String calleeID,
    required String calleeName,
    required String callID,
    required String inviterID,
    required String inviterName,
    required bool isInviterHost,
    Map<String, dynamic>? customData,
  }) async {
    print("========================================");
    print("📤📤📤 sendInvitation CALLED 📤📤📤");
    print("   calleeID: $calleeID");
    print("   calleeName: $calleeName");
    print("   callID: $callID");
    print("   inviterID: $inviterID");
    print("   inviterName: $inviterName");
    print("   isInviterHost: $isInviterHost");
    print("========================================");
    
    // ✅ Wait for ZEGO to be ready (silent wait - no popup)
    await waitForZegoReady();
    
    _currentCallID = callID;
    isCallInProgress.value = true;
    
    await _zegoService.sendInvitation(
      calleeID: calleeID,
      calleeName: calleeName,
      callID: callID,
      inviterID: inviterID,
      inviterName: inviterName,
      isInviterHost: isInviterHost,
      customData: customData,
    );
  }
  
  void onIncomingCallReceived(String callerName, String callerID, String callID) {
    print("📞📞📞 Incoming call received in CallController");
    print("   callerName: $callerName");
    print("   callerID: $callerID");
    print("   callID: $callID");
    isCallIncoming.value = true;
    incomingCallerName.value = callerName;
    incomingCallerID.value = callerID;
    incomingCallID.value = callID;
  }
  
  void acceptCall() {
    if (incomingCallID.value.isNotEmpty) {
      isCallIncoming.value = false;
    }
  }
  
  void rejectCall() {
    isCallIncoming.value = false;
    incomingCallerName.value = '';
    incomingCallerID.value = '';
    incomingCallID.value = '';
  }
  
  void endCall() {
    isCallInProgress.value = false;
    _currentCallID = null;
  }
  
  bool get isInCall => isCallInProgress.value || isCallIncoming.value;
  
  void deinitializeCallInvitationService() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
  
  @override
  void onClose() {
    _zegoService.dispose();
    super.onClose();
  }
}