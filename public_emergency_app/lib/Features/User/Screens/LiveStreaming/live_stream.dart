import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'keys.dart';

class LiveStreamingPage extends StatefulWidget {
  final String liveId;
  final bool isHost;

  const LiveStreamingPage({
    Key? key,
    required this.isHost,
    required this.liveId,
  }) : super(key: key);

  @override
  State<LiveStreamingPage> createState() => _LiveStreamingPageState();
}

class _LiveStreamingPageState extends State<LiveStreamingPage> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Host ke liye config
    final hostConfig = ZegoUIKitPrebuiltLiveStreamingConfig.host()
      ..turnOnCameraWhenJoining = true
      ..turnOnMicrophoneWhenJoining = true
      ..audioVideoViewConfig.useVideoViewAspectFill = true;

    // ✅ Audience ke liye config
    final audienceConfig = ZegoUIKitPrebuiltLiveStreamingConfig.audience()
      ..audioVideoViewConfig.useVideoViewAspectFill = true;

    // ✅ Unique userID aur userName set kar rahe hain
    final String userID = widget.isHost
        ? "responder_${Keys().userId}"
        : "user_${Keys().userId}";

    final String userName = widget.isHost ? "Responder" : "User";

    return SafeArea(
      child: ZegoUIKitPrebuiltLiveStreaming(
        appID: Keys().appId,
        appSign: Keys().appSign,
        userID: userID,
        userName: userName,
        liveID: widget.liveId,
        config: widget.isHost ? hostConfig : audienceConfig,
      ),
    );
  }
}
