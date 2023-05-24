import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomCardWidget extends StatelessWidget {
  final IconData iconData;
  final String dataText;
  final VoidCallback? onTap;
  final double verticalPadding; // Added property for top padding

  const CustomCardWidget({
    required this.iconData,
    required this.dataText,
    this.onTap,
    this.verticalPadding = 16.0, // Default top padding value
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      splashColor: Colors.grey.withOpacity(0.5), // Set the ripple color here
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16.0), // Use the specified top and horizontal padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 30.0),
                  // Adjust the space based on the icon size
                  Text(
                    dataText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(
                      fontSize: 20.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8.0,
              right: 8.0,
              child: Icon(
                iconData,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
