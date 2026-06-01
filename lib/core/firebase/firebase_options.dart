// ─────────────────────────────────────────────────────────────────────────────
// firebase_options.dart — TradeRep Pro
//
// Firebase configuration for each platform.
// Android values come from google-services.json (bundled at build time).
// Web values are embedded here so the web preview works without --dart-define.
//
// The API key below is a Firebase Web API key — it is intentionally
// client-facing (same key shown in the Firebase console under "Web app").
// It is NOT a server secret. Firestore / Auth security rules control access.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ─── Web ──────────────────────────────────────────────────────────────────
  // These values come from Firebase Console → Project Settings → Web apps.
  // All are safe to embed in client code (enforced by Firebase security rules).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyCAyIMNMUXdFgST_tO9kfMBe4kjzg821co',
    appId:             '1:518784222528:web:a963d8b03f5a3fcf31a6a5',
    messagingSenderId: '518784222528',
    projectId:         'traderep-pro',
    authDomain:        'traderep-pro.firebaseapp.com',
    storageBucket:     'traderep-pro.firebasestorage.app',
    databaseURL:       'https://traderep-pro-default-rtdb.firebaseio.com',
    measurementId:     'G-0XGC6CBMRB',
  );

  // ─── Android ──────────────────────────────────────────────────────────────
  // Values from google-services.json (bundled in the APK at build time).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDGnAOUK-dsrNUUf-TGzQB38FF_ZCoQsi4',
    appId:             '1:518784222528:android:a79e6c907bef852c31a6a5',
    messagingSenderId: '518784222528',
    projectId:         'traderep-pro',
    storageBucket:     'traderep-pro.firebasestorage.app',
  );

  // ─── iOS ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyDGnAOUK-dsrNUUf-TGzQB38FF_ZCoQsi4',
    appId:             '1:518784222528:ios:a79e6c907bef852c31a6a5',
    messagingSenderId: '518784222528',
    projectId:         'traderep-pro',
    storageBucket:     'traderep-pro.firebasestorage.app',
    iosBundleId:       'com.tradereppro.rep',
  );
}
