import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;

  const SquareTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(  // Add this wrapper
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20), // Add some padding
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromARGB(255, 213, 225, 224),
        ),
        child: Image.asset(
          imagePath,
          height: 50,
          width: 50,
        ),
      ),
    );
  }
}
