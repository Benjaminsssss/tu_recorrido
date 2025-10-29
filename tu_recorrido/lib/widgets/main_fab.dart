import 'package:flutter/material.dart';

class MainFab extends StatelessWidget {
  const MainFab({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: const Color(0xFFFACC15),
            elevation: 7,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Color(0xFF0B1020)),
          ),
        );
      },
    );
  }
}
