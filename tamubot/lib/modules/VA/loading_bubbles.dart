// lib/widgets/loading_bubbles.dart

import 'package:flutter/material.dart';

class LoadingBubbles extends StatefulWidget {
  const LoadingBubbles({super.key});

  @override
  State<LoadingBubbles> createState() => _LoadingBubblesState();
}

class _LoadingBubblesState extends State<LoadingBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBubble(0),
        _buildBubble(1),
        _buildBubble(2),
      ],
    );
  }

  Widget _buildBubble(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final delay = index * 0.2;
        final animationValue = (value - delay).clamp(0.0, 1.0);
        
        return Opacity(
          opacity: animationValue,
          child: Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
  }
}