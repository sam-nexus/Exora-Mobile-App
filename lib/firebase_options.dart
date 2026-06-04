import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAn8wRpEYyNoLqG1xTxv5O2DtBm4EFHYA8',
    appId: '1:455487033561:android:8128058553f55625f82ec8',
    messagingSenderId: '455487033561',
    projectId: 'avian-brand-474607-g8',
    storageBucket: 'avian-brand-474607-g8.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAn8wRpEYyNoLqG1xTxv5O2DtBm4EFHYA8',
    appId: '1:455487033561:web:71239dc5da4e969af82ec8',
    messagingSenderId: '455487033561',
    projectId: 'avian-brand-474607-g8',
    authDomain: 'avian-brand-474607-g8.firebaseapp.com',
    storageBucket: 'avian-brand-474607-g8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAn8wRpEYyNoLqG1xTxv5O2DtBm4EFHYA8',
    appId: '1:455487033561:ios:71239dc5da4e969af82ec8',
    messagingSenderId: '455487033561',
    projectId: 'avian-brand-474607-g8',
    storageBucket: 'avian-brand-474607-g8.firebasestorage.app',
    iosBundleId: 'com.exora.app',
  );
}