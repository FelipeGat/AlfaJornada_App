import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTgzx_pTS9_vv5zrrVEjgo3ObrE6up5eg',
    appId: '1:501823114178:android:b2ed953d96d91b5037245b',
    messagingSenderId: '501823114178',
    projectId: 'alfacontrol-ae4e4',
    storageBucket: 'alfacontrol-ae4e4.firebasestorage.app',
  );
}
