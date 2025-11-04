// ignore_for_file: constant_identifier_names

//App State
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const APPNAME = "Sonus Music Player";

RxString androidVersion = "".obs;
RxString aosBuildNo = "".obs;

const USERKEY = 'userkey';

// final isTablet = () {
//   final width = Get.width;
//   final height = Get.height;
//   final aspectRatio = width / height;

//   final isLargeEnough = width >= 600 && height >= 600;

//   final hasTabletAspectRatio = aspectRatio >= 1.3 && aspectRatio <= 1.6;

//   return isLargeEnough || hasTabletAspectRatio;
// }();

final screenWidth = MediaQuery.of(Get.context!).size.width;
final orientation = MediaQuery.of(Get.context!).orientation;

// Determine layout based on screen size and orientation
final isTablet = screenWidth >= 768; // Tablet breakpoint
// final isLandscape = orientation == Orientation.landscape;
// final isTabletLandscape = isTablet && isLandscape;
// final isPhoneLandscape = !isTablet && isLandscape;

// Notifications
const CHANNELKEY = 'basic_channel';
const CHANNELNAME = 'Basic Notifications';
const CHANNELDESCRIPTION = 'Notification channel for basic notifications';
