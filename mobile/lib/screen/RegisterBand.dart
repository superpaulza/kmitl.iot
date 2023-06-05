import 'package:flutter/material.dart';

import 'MainMenu.dart';

class RegisterSmartBandPage extends StatefulWidget {
  @override
  _RegisterSmartBandPageState createState() => _RegisterSmartBandPageState();
}

class _RegisterSmartBandPageState extends State<RegisterSmartBandPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _macAddressController = TextEditingController();
  bool _isMacAddressValid = true;

  @override
  void dispose() {
    _macAddressController.dispose();
    super.dispose();
  }

  void _validateMacAddress(String value) {
    // Example validation - verify the MAC address format
    final macAddressPattern =
        RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    setState(() {
      _isMacAddressValid = macAddressPattern.hasMatch(value);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // MAC address is valid, navigate to the main menu
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: "อบอุ่นหัวใจ",)),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invalid MAC Address'),
          content: Text(
              'Your MAC Address is not in the correct format. Please try again!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _macAddressController.clear();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100.0),
                Icon(
                  Icons.watch,
                  size: 100.0,
                  color: Colors.blue,
                ),
                SizedBox(height: 20.0),
                Text(
                  'Register Smart Band',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                Text(
                  'Please enter your smart band\'s MAC Address',
                  style: TextStyle(fontSize: 16.0),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _macAddressController,
                  decoration: InputDecoration(
                    labelText: 'MAC Address',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isMacAddressValid ? Colors.grey : Colors.red,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                      ),
                    ),
                    suffixIcon: _isMacAddressValid
                        ? Icon(Icons.check, color: Colors.green)
                        : Icon(Icons.close, color: Colors.red),
                  ),
                  keyboardType: TextInputType.text,
                  onChanged: _validateMacAddress,
                  // onTap: () {
                  //   FocusScope.of(context).requestFocus(FocusNode());
                  //   showDialog(
                  //     context: context,
                  //     builder: (context) => AlertDialog(
                  //       title: Text('Keyboard Closed'),
                  //       content: Text('You have closed the keyboard.'),
                  //       actions: [
                  //         TextButton(
                  //           onPressed: () {
                  //             Navigator.of(context).pop();
                  //           },
                  //           child: Text('OK'),
                  //         ),
                  //       ],
                  //     ),
                  //   );
                  // },
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
