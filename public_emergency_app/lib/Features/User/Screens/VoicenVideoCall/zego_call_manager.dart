import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'keys.dart';

class ZegoCallManager {
  static final ZegoCallManager _instance = ZegoCallManager._internal();
  factory ZegoCallManager() => _instance;
  ZegoCallManager._internal();

  bool _isInitialized = false;
  String? _currentUserID;
  String? _currentCallID;
  
  // Callbacks
  VoidCallback? onCallEnd;
  Function(String error)? onError;

  // ✅ Initialize ZEGO
  Future<void> initialize({
    required String userID,
    required String userName,
  }) async {
    if (_isInitialized && _currentUserID == userID) {
      debugPrint("✅ ZEGO already initialized for user: $userID");
      return;
    }

    if (_isInitialized) {
      await uninitialize();
    }

    try {
      debugPrint("🔄 Initializing ZEGO for user: $userID");
      
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: Keys.appId,
        appSign: Keys.appSign,
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );

      _isInitialized = true;
      _currentUserID = userID;
      debugPrint("✅ ZEGO initialized successfully");
    } catch (e) {
      debugPrint("❌ ZEGO initialization failed: $e");
      onError?.call(e.toString());
      rethrow;
    }
  }

  // ✅ End current call - Simplified approach
  Future<void> endCall({BuildContext? context}) async {
    if (!_isInitialized) {
      debugPrint("⚠️ ZEGO not initialized, cannot end call");
      return;
    }

    try {
      debugPrint("📞 Ending call...");
      
      // ✅ CORRECT: hangUp needs BuildContext
      // Using the context passed from the widget
      if (context != null) {
        await ZegoUIKitPrebuiltCallController().hangUp(context);
      } else {
        // If no context, just clean up state
        debugPrint("⚠️ No context provided, skipping hangUp");
      }
      
      _currentCallID = null;
      debugPrint("✅ Call ended successfully");
      
      onCallEnd?.call();
      
    } catch (e) {
      debugPrint("⚠️ Error ending call: $e");
      onError?.call(e.toString());
    }
  }

  // ✅ Uninitialize ZEGO completely
  Future<void> uninitialize() async {
    if (!_isInitialized) {
      debugPrint("ℹ️ ZEGO already uninitialized");
      return;
    }

    try {
      debugPrint("🔄 Uninitializing ZEGO...");
      
      // ✅ CORRECT: uninit exists
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      
      _isInitialized = false;
      _currentUserID = null;
      _currentCallID = null;
      debugPrint("✅ ZEGO uninitialized successfully");
      
    } catch (e) {
      debugPrint("⚠️ Error uninitializing ZEGO: $e");
      _isInitialized = false;
      _currentUserID = null;
      _currentCallID = null;
      onError?.call(e.toString());
    }
  }

  // ✅ Send invitation
  Future<bool> sendInvitation({
    required String calleeID,
    required String calleeName,
    required String callID,
    required String inviterID,
    required String inviterName,
    required bool isVideoCall,
    int timeoutSeconds = 60,
    Map<String, dynamic>? customData,
  }) async {
    if (!_isInitialized) {
      final error = "ZEGO not initialized";
      onError?.call(error);
      throw Exception(error);
    }

    try {
      _currentCallID = callID;
      
      debugPrint("📤 Sending invitation to: $calleeName ($calleeID)");
      
      final result = await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [
          ZegoCallUser(calleeID, calleeName),
        ],
        isVideoCall: isVideoCall,
        timeoutSeconds: timeoutSeconds,
        customData: customData?.toString() ?? '',
        callID: callID,
      );

      if (result) {
        debugPrint("✅ Invitation sent successfully");
      } else {
        debugPrint("❌ Invitation failed");
        onError?.call("Failed to send invitation");
      }

      return result;

    } catch (e) {
      debugPrint("❌ Send invitation error: $e");
      onError?.call(e.toString());
      return false;
    }
  }

  // ✅ Cancel invitation
  Future<bool> cancelInvitation({
    required String callID,
    required List<ZegoCallUser> callees,
    String customData = '',
  }) async {
    if (!_isInitialized) {
      final error = "ZEGO not initialized";
      onError?.call(error);
      throw Exception(error);
    }

    try {
      debugPrint("📤 Cancelling invitation...");
      
      final result = await ZegoUIKitPrebuiltCallInvitationService().cancel(
        callees: callees,
        customData: customData,
      );

      if (result) {
        debugPrint("✅ Invitation cancelled");
      }

      return result;

    } catch (e) {
      debugPrint("❌ Cancel invitation error: $e");
      onError?.call(e.toString());
      return false;
    }
  }

  // ✅ Get current state
  bool get isInitialized => _isInitialized;
  String? get currentUserID => _currentUserID;
  String? get currentCallID => _currentCallID;
}