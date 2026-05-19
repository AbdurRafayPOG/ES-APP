import 'dart:math';

class Keys {
  final int appId = 824447623; // ✅ Your ZEGO App ID
  final String appSign =
      "dc1cb7b2602bd8502c1361a9a5f45b377b1453a6ecd9494fe742b4311a1f93aa"; // ✅ Your ZEGO App Sign

  // 🔥 Generate unique random userID (less chance of duplicate)
  final String userId = "user_${Random().nextInt(999999)}";
}
