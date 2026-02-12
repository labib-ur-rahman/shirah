import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// shirah brand logo with styled text using Google Fonts K2D
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'SHIRAH',
      style: GoogleFonts.k2d(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        color: Colors.white,
        height: 1.0,
      ),
    );
  }
}
