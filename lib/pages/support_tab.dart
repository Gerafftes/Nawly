import 'package:flutter/material.dart';

class SupportTabContent extends StatelessWidget {
  const SupportTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Support',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
