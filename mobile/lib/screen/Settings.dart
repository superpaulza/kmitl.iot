import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('John Doe'),
            subtitle: Text('john.doe@example.com'),
          ),
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
