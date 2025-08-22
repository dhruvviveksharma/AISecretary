import 'package:ai_secretary/components/my_button.dart';
import 'package:ai_secretary/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../components/my_textfield.dart';
import '../components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  LoginPage({super.key, required this.onTap});
  

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final userNameController = TextEditingController();

  final passwordController = TextEditingController();


  void signUserIn() async {

    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        );
      }
    );

    
    // Implement sign-in logic here
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userNameController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // Replace with your actual HomePage class
      );

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'invalid-email' || e.code == 'user-disabled' || e.code == 'user-not-found') {
        wrongEmailMessage();
      } 
      else if (e.code == 'invalid-credential') {
        wrongPasswordMessage();
      }
      print("There is something wrong " + e.code);
    }
    
  }

  void wrongEmailMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Error: No User with that email found'),
        );
      },
    );
  }

  void wrongPasswordMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Error: wrong password'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(

          child: SingleChildScrollView(
            child: Column(
             
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              //logo  
              SizedBox(height: 50),
              Icon(
                Icons.lock, 
                size: 100, 
                color: Colors.teal[400],
                ),
              
              SizedBox(height: 50),
              
              // welcome back
              Text(
                'Welcome to your AI Secretary!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.indigo[900],
                  fontWeight: FontWeight.bold,
                ),
                
              ),
              SizedBox(height: 20),
              // username
              
              MyTextfield(
                Controller: userNameController,
                hintText: 'Username',
                obscureText: false,
                icon: Icons.person,
              ),
              // pwd
              MyTextfield(
                Controller: passwordController,
                hintText: 'Password',
                obscureText: true,
                icon: Icons.lock,
              ),
              // const SizedBox(height: 10),
              // forgot pwd
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.indigo[900],
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // sign in
              MyButton(
                onTap: signUserIn,
                text: "Sign In"
              ),
            
              const SizedBox(height: 20),
              // or continue with
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.purple[700],
                      )
                    ),
                
                    Text("Or continue with", style: TextStyle(color: Colors.indigo[900])),
                
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.purple[700],
                      )
                    ),
                  ],
                ),
              ),
            
              // google + apple
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // google button
                  SquareTile(
                    onTap: () => AuthService().signInWithGoogle(),
                    // Navigate to HomePage after successful sign-in
                    imagePath: 'lib/images/Google.png'
                    ),
                  SizedBox(width: 100),
                  // apple button
                  // SquareTile(imagePath: 'lib/images/apple.png'),
                ],
              ),
              const SizedBox(height: 50),
              // Not a member? Register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member? ',
                    style: TextStyle(color: Colors.indigo[900]),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Register now",
                      style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold)
                      ),
                  )
                  ],
                )
              ],
            ),
          ),
        ),
      )
    );
  }
}