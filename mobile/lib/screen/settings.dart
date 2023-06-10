import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String channelAccessToken =
      "8g2rzsNHv1jnflo7TtXlLFMQ3f0a5+apgLyjZcwnFaxw8Pb0qhrWA8l6UoKE+Rh7/nQoGG24ps0/EqQfaN0lajNtlgC337+qKvfKyNqh2M6qckhqdVIw0UwSO2J4a/ZIf3VB5C8wL4CrSpRJNyuzrQdB04t89/1O/w1cDnyilFU=";

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
    savedPref.setString('userID', userID);
    savedPref.setString('userImage', userImage);
    savedPref.setString('accessToken', accessToken);
    savedPref.setString('userStatus', userStatus);
  }

  void startLineLogin() async {
    try {
      final result =
          await LineSDK.instance.login(scopes: ["profile", "email", "openid"]);
      if (kDebugMode) {
        print("data = ${result.data}");
      }
      await _saveUserInfo(result);
      await _sendNotify();
      Restart.restartApp(webOrigin: '/register');
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

  void _showUnpairConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยกเลิการเชื่อมต่อนาฬิกาอัจฉริยะ'),
          content: Text('คุณต้องการที่จะยกเลิการเชื่อมต่อนาฬิกาอัจฉริยะกับแอปพลิเคชันนี้หรือไม่ ?'),
          actions: [
            TextButton(
              child: Text('ไม่'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('ใช่'),
              onPressed: () async {
                // Remove the MAC address and navigate to the register page
                SharedPreferences savedPref =
                    await SharedPreferences.getInstance();
                savedPref.remove('macAddress');
                _logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/register',
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
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
    final url = Uri.parse('https://api.line.me/v2/bot/message/multicast');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $channelAccessToken',
    };

    final requestBody = {
      'to': [userID], // Add the user ID of the recipient here
      'messages': [
        {
          'type': 'text',
          'text':
              'คุณ $userName ลงชื่อเข้าใช้งานสำเร็จ! ด้วยรหัสนาฬิกา $macAddress',
          // Modify the notification message as desired
        }
      ],
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(requestBody),
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
            child: const Text("ออกจากระบบ"),
            onPressed: () => _logout(),
          ),
        ],
      );
    } else {
      return Column(children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: const Text('บุคคลนิรนาม'),
          subtitle: Text(macAddress),
        ),
        ElevatedButton(
          child: const Text("เชื่อมต่อกับ LINE"),
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
        title: Text('การตั้งค่า'),
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          Divider(),
          SwitchListTile(
            title: Text('แจ้งเตือนผ่าน LINE'),
            subtitle: Text('ต้องการรับการแจ้งเตือนผ่าน LINE ไหม ?'),
            value: isLoggedIn,
            onChanged: (value) {
              setState(() {
                if(value == true) {
                  startLineLogin();
                } else {
                  _logout();
                }
              });

              // TODO: Update the push notification setting on the server
              // based on the value of `pushNotificationEnabled`.
            },
            secondary: Icon(Icons.notifications),
          ),
          // ListTile(
          //   onTap: () {
          //     launchUrl(Uri.parse("https://line.me/R/ti/p/@072sjexp"));
          //   }, // Update this line
          //   leading: Icon(Icons.person_add_rounded),
          //   title: Text('เพิ่มเพื่อน LINE เพื่อรับการแจ้งเตือน'),
          // ),
          ListTile(
            onTap: _showUnpairConfirmationDialog, // Update this line
            leading: Icon(Icons.remove_circle),
            title: Text('ยกเลิกการเชื่อมต่อนาฬิกาอัจฉริยะ'),
          ),
          ListTile(
            onTap: () {
              // Open details page
              Navigator.pushNamed(context, "/setalert");
            },
            leading: Icon(Icons.notifications_off),
            title: Text('ตั้งค่าการแจ้งเตือน'),
          ),
          ListTile(
            onTap: () {
              final Uri params = Uri(
                scheme: 'mailto',
                path: '62050198@kmitl.ac.th',
                query: 'subject=[แจ้งเตือน] ขอความช่วยเหลิอฉุกเฉินจากนาฬิกา&body=ขอความช่วยเหลิอฉุกเฉินจากนาฬิกา $macAddress',
              );
              launchUrl(params);
            },
            leading: Icon(Icons.help),
            title: Text('ขอความช่วยเหลือ'),
          ),
        ],
      ),
    );
  }
}
