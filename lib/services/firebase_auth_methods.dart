// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_firebase_auth/utils/showOTPDialog.dart';
import 'package:flutter_firebase_auth/utils/showSnackBar.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthMethods {
  final FirebaseAuth _auth;

  FirebaseAuthMethods(this._auth);

  User get user => _auth.currentUser!;

  // State Persistence

  Stream<User?> get authState => _auth.authStateChanges();
  // _auth.idTokenChanges();
  // _auth.userChanges();

  // Email SignUp

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await sendEmailVerification(context);
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  // Email Login

  Future<void> loginWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!_auth.currentUser!.emailVerified) {
        await sendEmailVerification(context);
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  // Email Verification

  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      _auth.currentUser!.sendEmailVerification();
      showSnackBar(context, 'Email verification sent!');
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  // Phone SignIn

  Future<void> phoneSignIn({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    TextEditingController codeController = TextEditingController();

    if (kIsWeb) {
      // !!! Works only on web !!!
      ConfirmationResult result =
          await _auth.signInWithPhoneNumber(phoneNumber);

      showOTPDialog(
        context: context,
        codeController: codeController,
        onPressed: () async {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: result.verificationId,
            smsCode: codeController.text.trim(),
          );
          await _auth.signInWithCredential(credential);
          Navigator.of(context).pop();
        },
      );
    } else {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (error) {
          showSnackBar(context, error.message!);
        },
        codeSent: (String verificationId, int? forceResendingToken) async {
          showOTPDialog(
            context: context,
            codeController: codeController,
            onPressed: () async {
              PhoneAuthCredential credential = PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: codeController.text.trim(),
              );
              await _auth.signInWithCredential(credential);
              Navigator.of(context).pop();
            },
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    }
  }

  // Google SignIn

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleAuthProvider = GoogleAuthProvider();

        googleAuthProvider
            .addScope('https://www.googleapis.com/auth/contacts.readonly');

        await _auth.signInWithPopup(googleAuthProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        final GoogleSignInAuthentication googleAuth =
            await googleUser!.authentication;

        if (googleAuth.accessToken != null && googleAuth.idToken != null) {
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          showSnackBar(context, userCredential.user!.email!);

          // if(userCredential.user != null) {
          //   if(userCredential.additionalUserInfo!.isNewUser) {
          //
          //   }
          //   else{
          //
          //   }
          // }
        }
      }
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  // Facebook SignIn

  Future<void> signInWithFacebook(BuildContext context) async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.token);

      await _auth.signInWithCredential(facebookAuthCredential);
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  // Facebook SignIn

  Future<void> signInAnonymously(BuildContext context) async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  // Sign out

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      showSnackBar(context, 'Signed out Successfully!');
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  //  Delete Account

  Future<void> deleteUser(BuildContext context) async {
    try {
      await _auth.currentUser!.delete();
      showSnackBar(context, 'Account deleted Successfully!');
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
  }
}
