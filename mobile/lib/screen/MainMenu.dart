import 'dart:async';

import 'package:bee_project/widget/CustomCardWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _dataSubscription;

  double bodyTemp = 0.0;
  double heartrateBPM = 0.0;
  String macAddress = "";

  @override
  void initState() {
    super.initState();
    loadData().then((_) {
      _dataSubscription = databaseReference
          .child('/$macAddress/body_temp/C')
          .onValue
          .listen((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          setState(() {
            bodyTemp = double.parse(event.snapshot.value.toString());
            // Update your dataText variables with the fetched data
          });
        }
      });
      _dataSubscription = databaseReference
          .child('/$macAddress/heart_rate/Avg BPM')
          .onValue
          .listen((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          setState(() {
            heartrateBPM = double.parse(event.snapshot.value.toString());
            // Update your dataText variables with the fetched data
          });
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _dataSubscription?.cancel();
  }

  loadData() async {
    SharedPreferences savedPref = await SharedPreferences.getInstance();
    setState(() {
      macAddress = (savedPref.getString('macAddress') ?? "");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: GoogleFonts.montserrat(
                fontSize: 25, fontStyle: FontStyle.italic),
          ),
          actions: <Widget>[
            Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, "/settings");
                  },
                  child: const Icon(
                    Icons.settings,
                    size: 26.0,
                  ),
                )),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.favorite,
                      dataText: "$heartrateBPM \nรอบ (BPM)",
                      verticalPadding: 50,
                      onTap: () {
                        Navigator.pushNamed(context, "/heartrate");
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.ac_unit,
                      dataText: "${bodyTemp.toStringAsFixed(2)} \nองศา (°C)",
                      verticalPadding: 50,
                      onTap: () {
                        Navigator.pushNamed(context, "/bodytemp");
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.local_hospital_rounded,
                      dataText: 'หน่วยแพทย์ฉุกเฉิน(ทั่วไทย)',
                      onTap: () {
                        launchUrl(Uri.parse("tel://1669"));
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.local_police,
                      dataText: 'แจ้งเหตุด่วน - เหตุร้ายทุกชนิด',
                      onTap: () {
                        launchUrl(Uri.parse("tel://191"));
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.fire_truck,
                      dataText: 'แจ้งไฟไหม้ - ดับเพลิง',
                      onTap: () {
                        launchUrl(Uri.parse("tel://199"));
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.directions_boat_filled,
                      dataText: 'แจ้งอุบัติเหตุทางน้ำ',
                      onTap: () {
                        launchUrl(Uri.parse("tel://1196"));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
