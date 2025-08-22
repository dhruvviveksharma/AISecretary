
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {
//   signInWithGoogle() async {
//     // begin interactice sign in 
//     final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

//     // obtain auth details
//     final GoogleSignInAuthentication gAuth = await gUser!.authentication;

//     // final credential 
//     final credential = GoogleAuthProvider.credential(
//       accessToken: gAuth.accessToken,
//       idToken: gAuth.idToken,
//     );

//     // sign in 
//     return await FirebaseAuth.instance.signInWithCredential(credential);
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  signInWithGoogle() async {
    try {
      // Begin interactive sign in 
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      
      // If user cancels the sign-in
      if (gUser == null) {
        print('Sign in was cancelled by user');
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      print("working till here");

      // Create credential 
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      print("Credential created successfully");
      // Sign in 
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print('Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
      
    } catch (e) {
      print('Error during Google sign in: $e');
      return null;
    }
  }
}