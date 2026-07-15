import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget childMobile;
  final Widget? childTablet;
  final Widget childDesktop;

  const ResponsiveLayout({
    super.key,
    required this.childMobile,
    this.childTablet,
    required this.childDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return childDesktop;
    } else if (Responsive.isTablet(context) && childTablet != null) {
      return childTablet!;
    } else {
      return childMobile;
    }
  }
}
