import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  static const double maxContentWidth = 500.0;

  final Widget Function(BuildContext context, double w, double h) builder;

  const ResponsiveWrapper({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          if (isDesktop && w > maxContentWidth) {
            return Container(
              color: const Color(0xFF0A0A0A),
              child: Center(
                child: Container(
                  width: maxContentWidth,
                  height: h,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: const Color(0xFF7000FF).withValues(alpha: 0.3), width: 2),
                      right: BorderSide(color: const Color(0xFF7000FF).withValues(alpha: 0.3), width: 2),
                    ),
                  ),
                  child: builder(context, maxContentWidth, h),
                ),
              ),
            );
          }

          return builder(context, w, h);
        },
      ),
    );
  }
}
