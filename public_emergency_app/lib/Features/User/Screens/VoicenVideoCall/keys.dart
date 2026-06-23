import 'dart:math';

class Keys {
  // ZEGO Credentials
  static final int appId = 396625779;
  static final String appSign =
      "9aca6107fdbcbdb5a79d977c5e7f5a43cd610deb92165e3f6e9218a429c0ced3";

  // Static user ID and name
  static String userId = "user_${Random().nextInt(999999)}";
  static String userName = "User";
  static String responderType = "";  // ← Used for display: "Cadey (FireFighter)"
  static String responderName = "";  // ← ← ← NEEDED!
  
  static void setUserInfo(String id, String name) {
    userId = id;
    userName = name;
  }
}