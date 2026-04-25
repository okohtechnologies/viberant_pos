import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  static int gridColumns(double width) {
    if (width < 400) return 1;
    if (width < mobile) return 2;
    if (width < 900) return 3;
    return 4;
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= Breakpoints.mobile && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
