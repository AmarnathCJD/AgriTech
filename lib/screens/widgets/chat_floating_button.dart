import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../screens/chat_screen.dart';

class ChatFloatingButton extends StatelessWidget {
  const ChatFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      },
      backgroundColor: const Color(0xFF2E7D32), // Deep Green
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
    )
        .animate()
        .scale(delay: 500.ms, duration: 300.ms, curve: Curves.easeOutBack);
  }
}
