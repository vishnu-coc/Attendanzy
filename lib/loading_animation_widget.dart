import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingExampleScreen extends StatelessWidget {
  const LoadingExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loading Animations"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Staggered Dots Wave
          LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blueAccent,
            size: 50,
          ),
          const SizedBox(height: 20),

          // Four Rotating Dots
          LoadingAnimationWidget.fourRotatingDots(
            color: Colors.green,
            size: 50,
          ),
          const SizedBox(height: 20),

          // Bouncing Ball
          LoadingAnimationWidget.bouncingBall(color: Colors.red, size: 50),
        ],
      ),
    );
  }
}
