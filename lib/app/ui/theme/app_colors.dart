import 'package:flutter/material.dart';

class TpsColors {
  // App theme Colors
  static const Color primary = Color(0xFF235696);
  // static const Color primary = Color(0xFF0029FF);
  // Color(0xFF0029FF);

  static const Color secondary = Color.fromARGB(255, 73, 103, 255);

  // Background colors
  static const Color light = Color(0xFFF6F6F6);
  static const Color dark = Color(0xFF272727);
  static const Color primaryBackground = Color(0xFFF3F5FF);

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Colors.white;

  // Button colors
  static const Color buttonPrimary = Color(0xFF4b68ff);
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  // Error and validation colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color.fromARGB(255, 18, 210, 28);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color darknessGrey = Color.fromARGB(255, 47, 47, 47);
  static const Color darkerGrey = Color(0xFF4F4F4F);
  static const Color darkGrey = Color(0xFF939393);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF0797FF);
  static const Color yellow = Color(0xFFFFD600);
  static const Color green = Color.fromARGB(255, 0, 208, 80);

  // Tick color
  static const Color tickOrange = Color(0xFFF86943);

  static const Color driverAppBar = Color.fromARGB(255, 0, 128, 4);

  // Product color
  static const Color octane95 = Color.fromARGB(255, 18, 210, 28);
  static const Color octane92 = Color.fromARGB(255, 255, 110, 70);
  static const Color octane97 = Color.fromARGB(255, 11, 97, 0);
  static const Color pd = Color.fromARGB(255, 0, 69, 118);
  static const Color diesel = Color(0xFF0797FF);
  static const Color chsd = Color.fromARGB(255, 68, 110, 141);
  static const Color cphsd = Color.fromARGB(255, 117, 195, 255);

  // STATUS Color
  static const Color pending = Colors.orange;
  static const Color rejected = Colors.red;
  static const Color fueling = Colors.red;
  static const Color approved = Colors.orange;
  static const Color toTerminal = Colors.green;
  static const Color discharging = Colors.blue;
  static const Color waitingTerminal = Color.fromARGB(255, 160, 96, 0);
  static const Color completed = Colors.green;

  // Music Player Colors
  static const Color musicPrimary = Color(0xFF6C63FF);
  static const Color musicSecondary = Color(0xFF4ECDC4);
  static const Color musicAccent = Color(0xFFFF6B6B);
  static const Color musicDark = Color(0xFF2D3436);
  static const Color musicLight = Color(0xFFF8F9FA);
  static const Color musicGradientStart = Color(0xFF667eea);
  static const Color musicGradientEnd = Color(0xFF764ba2);
  static const Color musicCard = Color(0xFFFFFFFF);
  static const Color musicCardDark = Color(0xFF34495E);
  static const Color musicText = Color(0xFF2D3436);
  static const Color musicTextLight = Color(0xFF636E72);
  static const Color musicBackground = Color(0xFFF8F9FA);
  static const Color musicBackgroundDark = Color(0xFF2D3436);
  static const Color musicDiscoveryStart = Color(0xFF4ECDC4);
  static const Color musicDiscoveryEnd = Color(0xFF38B2AC);

  static List<Color> primaryGradientColors = [
    musicGradientStart,
    musicGradientEnd,
  ];

  static List<Color> darkGradientColors = [
    // darkGrey,
    darkerGrey,
    // darkerGrey,
    darknessGrey,
    darknessGrey,
    dark
  ];
}
