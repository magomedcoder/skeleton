import 'package:flutter/material.dart';

class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static bool isMobile(BuildContext context) => width(context) < mobile;

  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) => width(context) >= tablet;

  static bool useDrawerForSessions(BuildContext context) => width(context) < mobile;

  static const double sidebarMinWidth = 260;

  static const double sidebarMaxWidth = 360;

  static const double sidebarDefaultWidth = 300;
}
