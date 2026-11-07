// PLACEHOLDER — this file is REPLACED when you run:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure
//
// flutterfire generates the real values for your own Firebase project.
// The app will not connect to Firebase until you do this.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD7zTnZk2wrUYA6eL656kjW_7fTV2CugZE',
    appId: '1:993442167946:web:d259e2f2081a18eab28173',
    messagingSenderId: '993442167946',
    projectId: 'campus-incident-app-f129c',
    authDomain: 'campus-incident-app-f129c.firebaseapp.com',
    storageBucket: 'campus-incident-app-f129c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQ4I4iKeTNvCMxv9x5ARUy3owz79_8qz4',
    appId: '1:993442167946:android:67ebe859cb6e2182b28173',
    messagingSenderId: '993442167946',
    projectId: 'campus-incident-app-f129c',
    storageBucket: 'campus-incident-app-f129c.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'com.example.campusIncidentApp',
  );
}
