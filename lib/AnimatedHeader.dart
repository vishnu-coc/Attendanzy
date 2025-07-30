import 'package:flutter/material.dart';

class AnimatedHeader extends StatelessWidget {
  final String name; // This is the parameter you're passing

  const AnimatedHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $name!',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 5),
          const Text(
            'Welcome to your dashboard',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          const Text(
            '"Education is the most powerful weapon which you can use to change the world."',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
