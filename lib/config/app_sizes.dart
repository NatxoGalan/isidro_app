import 'package:flutter/material.dart';

class AppSizes {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double touchTargetMin = 48;
  static const double touchTargetOptimal = 56;
}

class Breakpoints {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1440;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < tablet;
  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= tablet && MediaQuery.sizeOf(context).width < desktop;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
}
