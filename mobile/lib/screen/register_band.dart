import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_menu.dart';

class RegisterSmartBandPage extends StatefulWidget {
  const RegisterSmartBandPage({super.key});

  @override
  _RegisterSmartBandPageState createState() => _RegisterSmartBandPageState();
}

class _RegisterSmartBandPageState extends State<RegisterSmartBandPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _macAddressController = TextEditingController();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool _isMacAddressValid = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _prefs.then((SharedPreferences prefs) {
      if (prefs.getString('macAddress') != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const MyHomePage(
                    title: "อบอุ่นหัวใจ",
                  )),
        );
      }
    });
  }

  @override
  void dispose() {
    _macAddressController.dispose();
    super.dispose();
  }

  void _validateMacAddress(String value) {
    // Example validation - verify the MAC address format
    final macAddressPattern =
        RegExp(r'^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$');
    setState(() {
      _isMacAddressValid = macAddressPattern.hasMatch(value);
    });
  }

  Future<void> _submitForm() async {
    final SharedPreferences prefs = await _prefs;
    if (_formKey.currentState!.validate()) {
      // MAC address is valid, navigate to the main menu
      prefs
          .setString('macAddress', _macAddressController.text)
          .then((bool success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const MyHomePage(
                    title: "อบอุ่นหัวใจ",
                  )),
        );
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invalid MAC Address'),
          content: const Text(
              'Your MAC Address is not in the correct format. Please try again!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _macAddressController.clear();
              },
              child: const Text('OK'),
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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100.0),
                const Icon(
                  Icons.watch,
                  size: 100.0,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Register Smart Band',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Please enter your smart band\'s MAC Address \n(Example: 00:B0:D0:63:C2:26)',
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter MAC address';
                    }
                    if (!_isMacAddressValid) {
                      return 'Not valid MAC address';
                    }
                    return null;
                  },
                  controller: _macAddressController,
                  decoration: InputDecoration(
                    labelText: 'MAC Address',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isMacAddressValid ? Colors.grey : Colors.red,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                      ),
                    ),
                    suffixIcon: _isMacAddressValid
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.close, color: Colors.red),
                  ),
                  keyboardType: TextInputType.text,
                  onChanged: _validateMacAddress,
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
