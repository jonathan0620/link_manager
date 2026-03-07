import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ZoopLogo extends StatelessWidget {
  final double size;

  const ZoopLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    // SVG 원본 비율: 320 x 100 (가로:세로 = 3.2:1)
    final height = size;
    final width = size * 3.2;

    return SvgPicture.asset(
      'assets/images/logo.svg',
      height: height,
      width: width,
      fit: BoxFit.contain,
    );
  }
}
