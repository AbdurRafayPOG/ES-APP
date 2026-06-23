import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../Features/User/Screens/VoicenVideoCall/keys.dart';
import '../Features/User/Screens/VoicenVideoCall/videoncall.dart';

class ZegoService {
  static final ZegoService _instance = ZegoService._internal();
  factory ZegoService() => _instance;
  ZegoService._internal();

  bool _isInitialized = false;
  
  Function(String callID, String? callerID, String? callerName)? onCallAccepted;
  Function(String callID, String? callerID)? onCallRejected;

  void initialize({required String userID, required String userName}) {
    if (_isInitialized) return;
    
    Keys.setUserInfo(userID, userName);
    _isInitialized = true;
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
    print("📤📤📤 ZegoService.sendInvitation() CALLED 📤📤📤");
    print("   calleeID: $calleeID");
    print("   calleeName: $calleeName");
    print("   callID: $callID");
    print("   inviterID: $inviterID");
    print("   inviterName: $inviterName");
    print("   isInviterHost: $isInviterHost");
    print("========================================");
    
    if (!_isInitialized) {
      print("❌❌❌ ZegoService NOT initialized! ❌❌❌");
      Get.snackbar(
        'Error',
        'ZEGO service not initialized',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      print("🟢 Calling ZegoUIKitPrebuiltCallInvitationService().send()...");
      print("   Invitees: [ZegoCallUser($calleeID, $calleeName)]");
      print("   isVideoCall: true");
      print("   callID: $callID");
      print("   timeoutSeconds: 30");
      
      final result = await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [
          ZegoCallUser(calleeID, calleeName),
        ],
        isVideoCall: true,
        customData: customData != null ? customData.toString() : '',
        callID: callID,
        timeoutSeconds: 30,
      );
      
      print("📤📤📤 ZEGO send() RESULT: $result 📤📤📤");
      
      if (!result) {
        print("❌❌❌ Invitation failed! ❌❌❌");
        Get.snackbar(
          'Error',
          'Failed to send call invitation',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        print("✅✅✅ Invitation sent successfully! ✅✅✅");
      }
    } catch (e) {
      print("========================================");
      print("❌❌❌ ZEGO send() EXCEPTION ❌❌❌");
      print("   Error: $e");
      print("========================================");
      Get.snackbar(
        'Error',
        'Failed to send call invitation',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}