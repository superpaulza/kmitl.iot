import 'dart:async';

import 'package:bee_project/widget/CustomCardWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

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

  @override
  void initState() {
    super.initState();
    _dataSubscription = databaseReference
        .child('/80:7D:3A:5A:4F:CC/body_temp/C')
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
        .child('/80:7D:3A:5A:4F:CC/heart_rate/Avg BPM')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          heartrateBPM = double.parse(event.snapshot.value.toString());
          // Update your dataText variables with the fetched data
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _dataSubscription?.cancel();
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
                    ),
                  ),
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.ac_unit,
                      dataText: "${bodyTemp.toStringAsFixed(2)} \nองศา (°C)",
                      verticalPadding: 50,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomCardWidget(
                      iconData: Icons.alarm,
                      dataText: 'แจ้งเตือนเวลารับประทานยา',
                      onTap: () {
                        // bodyTemp = "0";
                        // print('Card clicked!');
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
                      iconData: Icons.medical_services_rounded,
                      dataText: 'เรียกรถพยาบาลฉุกเฉิน',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
