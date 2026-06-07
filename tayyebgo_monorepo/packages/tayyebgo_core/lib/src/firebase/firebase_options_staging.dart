import 'package:firebase_core/firebase_core.dart';

class StagingFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  // TODO: Replace with actual staging Firebase project config.
  // Steps to obtain:
  //   1. Go to https://console.firebase.google.com/project/tayyebgo-staging/settings/general
  //   2. Scroll to "Your apps" > Web app > Config
  //   3. Copy the firebaseConfig values below
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyEXAMPLE_STAGING_API_KEY',
    appId: '1:STAGING_PROJECT_ID:web:staging_web_app_id',
    messagingSenderId: 'STAGING_SENDER_ID',
    projectId: 'tayyebgo-staging',
    authDomain: 'tayyebgo-staging.firebaseapp.com',
    storageBucket: 'tayyebgo-staging.firebasestorage.app',
    measurementId: 'G-STAGING_MEASUREMENT_ID',
  );
}
