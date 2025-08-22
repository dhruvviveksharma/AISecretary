
import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final Controller;
  final String hintText;
  final bool obscureText;
  final IconData icon;

  const MyTextfield({
    super.key,
    required this.Controller,
    required this.hintText,
    required this.obscureText,
    required this.icon,
    });

  @override
  Widget build(BuildContext context) {
      return Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: Controller,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    prefixIcon: Icon(icon, color: Colors.indigo[900]),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    hintText: hintText,
                    hintStyle: TextStyle(color: const Color.fromARGB(255, 12, 2, 126)),
                  ),
                ),

              );
  }
}