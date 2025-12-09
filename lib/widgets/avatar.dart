import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String text;
  final double size;
  final bool showPlus;

  const Avatar({
    super.key,
    required this.text,
    this.size = 50,
    this.showPlus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF0088CC),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          showPlus ? '+' : text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}