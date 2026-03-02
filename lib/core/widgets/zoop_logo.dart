import 'package:flutter/material.dart';

class ZoopLogo extends StatelessWidget {
  final double size;
  
  const ZoopLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 1.5;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Z
        Text(
          'Z',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4CAF50),
            height: 1,
          ),
        ),
        // O with eyes
        _buildO(fontSize),
        // O with eyes
        _buildO(fontSize),
        // P
        _buildP(fontSize),
      ],
    );
  }

  Widget _buildO(double fontSize) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'O',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4CAF50),
            height: 1,
          ),
        ),
        // Eyes
        Positioned(
          top: fontSize * 0.25,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEye(fontSize * 0.12),
              SizedBox(width: fontSize * 0.1),
              _buildEye(fontSize * 0.12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEye(double eyeSize) {
    return Container(
      width: eyeSize,
      height: eyeSize * 1.3,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildP(double fontSize) {
    return Stack(
      children: [
        Text(
          'P',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4CAF50),
            height: 1,
          ),
        ),
        // Yellow horizontal lines on P
        Positioned(
          right: fontSize * 0.05,
          top: fontSize * 0.22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: fontSize * 0.25,
                height: fontSize * 0.06,
                color: const Color(0xFFFFD54F),
              ),
              SizedBox(height: fontSize * 0.06),
              Container(
                width: fontSize * 0.2,
                height: fontSize * 0.06,
                color: const Color(0xFFFFD54F),
              ),
              SizedBox(height: fontSize * 0.06),
              Container(
                width: fontSize * 0.15,
                height: fontSize * 0.06,
                color: const Color(0xFFFFD54F),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
