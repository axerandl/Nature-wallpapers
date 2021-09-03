import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper_bliss/env.dart';

class AdShowAid {
  static const _INITIAL = 0;
  static const _THRESH = 3;

  int _count;

  AdShowAid() {
    _count = _INITIAL;
  }

  bool ready() {
    if (_count == 0) {
      _count = _THRESH;
      return true;
    }
    --_count;
    return false;
  }
}

class SigninUtilAnonymous {
  SigninUtilAnonymous();

  Future signIn() async {
    try {
      AuthResult authResult = await FirebaseAuth.instance.signInAnonymously();
      final FirebaseUser user = authResult.user;
      assert(user.isAnonymous);
      final String userId = user.uid;
      debugPrint(
          "New anonymous user in firesore. id: $userId user: ${user.providerId}");
    } catch (err) {
      debugPrint("Signing in error: $err");
    }
  }

  Future signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (err) {
      debugPrint("Signing out error: $err");
    }
  }
}

// class SigninUtilGoogle {
//   final GoogleSignIn _googleSignin = GoogleSignIn();
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//   FirebaseUser _currentUser;
//   bool _isAuth = false;

//   SigninUtilGoogle();

//   Future init() async {
//     try {
//       _googleSignin.onCurrentUserChanged.listen(
//           (account) => _handleSignIn(account),
//           onError: (err) => debugPrint("Signing in error: $err"));
//       GoogleSignInAccount account =
//           await _googleSignin.signInSilently(suppressErrors: false);
//       _handleSignIn(account);
//     } catch (err) {
//       debugPrint("Signing in error: $err");
//     }
//   }

//   _createUserInFirestore(AuthCredential googleCredential) async {
//     final AuthResult authResult =
//         await _firebaseAuth.signInWithCredential(googleCredential);
//     _currentUser = authResult.user;

//     assert(_currentUser.email != null);
//     assert(_currentUser.displayName != null);
//     assert(!_currentUser.isAnonymous);
//     assert(await _currentUser.getIdToken() != null);
//   }

//   _handleSignIn(GoogleSignInAccount googleUser) async {
//     if (googleUser != null) {
//       debugPrint('Signed in with google id: ${googleUser.id}');

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final AuthCredential googleCredential = GoogleAuthProvider.getCredential(
//           accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

//       await _createUserInFirestore(googleCredential);
//       // await _createAnonymousUser(googleCredential);
//       _isAuth = true;
//     } else {
//       debugPrint('Signed out; account: $googleUser');
//       _isAuth = false;
//       _currentUser = null;
//     }
//   }

//   GoogleSignIn get googleSignIn => _googleSignin;
//   FirebaseAuth get firebaseAuth => _firebaseAuth;
//   FirebaseUser get currentUser => _currentUser;
//   bool get isAuthenticated => _isAuth;

//   // _createAnonymousUser(AuthCredential googleCredential) async {
//   //   final AuthResult authResult = await auth.signInAnonymously();
//   //   final FirebaseUser user = authResult.user;
//   //   assert(user.isAnonymous);
//   //   final String userId = user.uid;
//   //   debugPrint(
//   //       "New anonymous user in firesore. id: $userId user: ${user.providerId}");
//   // }
// }

class AndroidInfo {
  AndroidDeviceInfo _androidInfo;
  int _sdkInt;
  String _uuid;

  int get sdkInt {
    return _sdkInt;
  }

  String get uuid {
    return _uuid;
  }

  Future init() async {
    if (Platform.isAndroid) {
      _androidInfo = await DeviceInfoPlugin().androidInfo;
      _sdkInt = _androidInfo.version.sdkInt;
      _uuid = _androidInfo.androidId;
    } else {
      _sdkInt = 0;
      _uuid = 'anonymous';
    }
  }
}

class AdMobUtil {
  AdmobBanner admobBanner;
  AdmobInterstitial interstitialAd;

  AdMobUtil() {
    Admob.initialize();

    admobBanner = AdmobBanner(
        adUnitId: environment['banner_bottom'], adSize: AdmobBannerSize.BANNER);

    interstitialAd = AdmobInterstitial(
      adUnitId: environment['interstial_category'],
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        if (event == AdmobAdEvent.closed) interstitialAd.load();
        if (event == AdmobAdEvent.failedToLoad) {
          print("Error code: ${args['errorCode']}");
        }
      },
    );
    interstitialAd.load();
  }
}
