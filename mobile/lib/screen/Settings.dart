import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String macAddress = "";
  bool isLoggedIn = false;
  String userName = "";
  String userID = "";
  String userImage = "";
  String accessToken = "";
  String userStatus = "";

  void lineSDKInit() async {
    await LineSDK.instance.setup("1661377246").then((_) {
      if (kDebugMode) {
        print("LineSDK is Prepared");
      }
    });
  }

  @override
  void initState() {
    lineSDKInit();
    loadData();
    super.initState();
  }

  void loadData() async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    setState(() {
      macAddress = (savedPref.getString('macAddress') ?? "");
      isLoggedIn = savedPref.getBool('isLoggedIn') ?? false;
      userName = savedPref.getString('userName') ?? "";
      userID = savedPref.getString('userID') ?? "";
      userImage = savedPref.getString('userImage') ?? "";
      accessToken = savedPref.getString('accessToken') ?? "";
      userStatus = savedPref.getString('userStatus') ?? "";
    });
  }

  void saveData(bool isLoggedIn, String userName, String userID,
      String userImage, String accessToken, String userStatus) async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    savedPref.setBool('isLoggedIn', isLoggedIn);
    savedPref.setString('userName', userName);
    savedPref.setString('userEmail', userID);
    savedPref.setString('userImage', userImage);
    savedPref.setString('accessToken', accessToken);
    savedPref.setString('userStatus', userStatus);
  }

  void startLineLogin() async {
    try {
      final result =
          await LineSDK.instance.login(scopes: ["profile", "email", "openid"]);
      await _saveUserInfo(result);
      await _sendNotify();
    } on PlatformException catch (e) {
      print(e);
      switch (e.code.toString()) {
        case "CANCEL":
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "คุณยกเลิกการเข้าสู่ระบบ เมื่อสักครู่คุณกดยกเลิกการเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่อีกครั้ง"),
          ));
          if (kDebugMode) {
            print("User Cancel the login");
          }
          break;
        case "AUTHENTICATION_AGENT_ERROR":
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "คุณไม่อนุญาติการเข้าสู่ระบบด้วย LINE เมื่อสักครู่คุณกดยกเลิกการเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่อีกครั้ง"),
          ));
          if (kDebugMode) {
            print("User decline the login");
          }
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "เกิดข้อผิดพลาด เกิดข้อผิดพลาดไม่ทราบสาเหตุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง"),
          ));
          if (kDebugMode) {
            print("Unknown but failed to login");
          }
          break;
      }
    }
  }

  Future getAccessToken() async {
    try {
      final result = await LineSDK.instance.currentAccessToken;
      return result?.value;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Can't get accessToken");
      }
    }
  }

  Future<void> _saveUserInfo(LoginResult loginResult) async {
    var token = await getAccessToken();

    setState(() {
      userName = loginResult.userProfile?.displayName ?? "";
      userID = loginResult.userProfile?.userId ?? "";
      userImage = loginResult.userProfile?.pictureUrl ?? "";
      isLoggedIn = true;
      accessToken = token;
      userStatus = loginResult.userProfile!.statusMessage!;
    });

    saveData(isLoggedIn, userName, userID, userImage, accessToken, userStatus);
  }

  Future<void> _sendNotify() async {
    // Prepare the request body with your desired message and image URLs
    final requestBody = {
      "message": "Hello from Flutter!",
      "imageThumbnail": "https://example.com/image-thumbnail.jpg",
      "imageFullsize": "https://example.com/image-fullsize.jpg",
    };

    if (accessToken != null) {
      final response = await http.post(
        Uri.parse("https://notify-api.line.me/api/notify"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": "Bearer $accessToken",
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        // Notify sent successfully
        if (kDebugMode) {
          print(response.body);
        }
      } else {
        // Handle notify failure
        if (kDebugMode) {
          print(response.body);
        }
      }
    }
  }

  Widget _buildProfileSection() {
    if (isLoggedIn) {
      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userImage),
            ),
            title: Text(userName),
            subtitle: Text("$userStatus\n$macAddress"),
          ),
          ElevatedButton(
            child: Text("Logout"),
            onPressed: () => _logout(),
          ),
        ],
      );
    } else {
      return Column(children: [
        ListTile(
          leading: CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text('Not Logged In'),
          subtitle: Text(macAddress),
        ),
        ElevatedButton(
          child: Text("Login with LINE"),
          onPressed: () => startLineLogin(),
        ),
      ]);
    }
  }

  void _logout() async {
    // Clear user information from shared preference
    saveData(false, "", "", "", "", "");

    // Clear LINE SDK access token
    await LineSDK.instance.logout();

    setState(() {
      userName = "";
      userID = "";
      userImage = "";
      isLoggedIn = false;
      userStatus = "";
      accessToken = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          Divider(),
          SwitchListTile(
            title: Text('Push Notifications'),
            subtitle: Text('Receive push notifications'),
            value: true,
            onChanged: (value) {},
            secondary: Icon(Icons.notifications),
          ),
          ListTile(
            onTap: () {
              // Open details page
            },
            leading: Icon(Icons.language),
            title: Text('Language'),
          ),
          ListTile(
            onTap: () {
              // Open details page
            },
            leading: Icon(Icons.lock),
            title: Text('Privacy'),
          ),
          ListTile(
            onTap: () {
              // Open details page
            },
            leading: Icon(Icons.notifications_off),
            title: Text('Notifications'),
          ),
          ListTile(
            onTap: () {
              // Open details page
            },
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
          ),
        ],
      ),
    );
  }
}
