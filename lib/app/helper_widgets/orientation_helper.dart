import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationHelper {
  static Future<void> setOrientation(BuildContext context) async {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= 600;

    if (isTablet) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final width = screenWidth;
    final height = screenHeight;
    final aspectRatio = width / height;

    final isLargeEnough = width >= 600 && height >= 600;

    final hasTabletAspectRatio = aspectRatio >= 1.3 && aspectRatio <= 1.6;

    return isLargeEnough || hasTabletAspectRatio;
  }
}
