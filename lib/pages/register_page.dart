import 'package:ai_secretary/components/my_button.dart';
import 'package:ai_secretary/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../components/my_textfield.dart';
import '../components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  RegisterPage({super.key, required this.onTap});
  

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {
  final userNameController = TextEditingController();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();


  void signUserUp() async {

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
      if (passwordController.text.trim() == confirmPasswordController.text.trim()) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userNameController.text.trim(),
          password: passwordController.text.trim(),
        );
         Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // Replace with your actual HomePage class
        );

      }
      else{
        Navigator.pop(context);
        showErrorMessage("Passwords do not match");
        print("Passwords do not match");
      }
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
      print("There is something wrong " + e.code);
    }
    
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.teal[100],
          title: Text(
            message,
            style: TextStyle(color: Colors.indigo[900]),
          ),
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
              SizedBox(height: 20),
              Icon(
                Icons.lock, 
                size: 90, 
                color: Colors.teal[400],
                ),
              
              SizedBox(height: 20),
              
              // welcome back
              Text(
                'Let\'s create an account for you!',
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
              //ask again
              MyTextfield(
                Controller: confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: true,
                icon: Icons.lock,
              ),
              
              MyButton(
                onTap: signUserUp,
                text: "Register",
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
                    onTap: () => AuthService().signInWithGoogle().then((value) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()), // Replace with your actual HomePage class
                      );
                    }),
                    imagePath: 'lib/images/Google.png'),
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
                    'Already have an account? ',
                    style: TextStyle(color: Colors.indigo[900]),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Login now",
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