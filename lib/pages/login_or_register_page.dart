import 'login_page.dart';
import 'package:flutter/material.dart';
import 'register_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {

  bool showLoginPage = true;

  // toggle between login and register pages
  void togglePage() {

    setState(() {
      showLoginPage = !showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (showLoginPage){
      return LoginPage(
        onTap: togglePage,
      );

    }
    else{
      return RegisterPage(
        onTap: togglePage,
      );
    }
  }
}