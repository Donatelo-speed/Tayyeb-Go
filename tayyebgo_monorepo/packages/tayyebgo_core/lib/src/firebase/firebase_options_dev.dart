import 'package:firebase_core/firebase_core.dart';

class DevFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  // TODO: Replace with actual dev Firebase project config.
  // Steps to obtain:
  //   1. Go to https://console.firebase.google.com/project/tayyebgo-dev/settings/general
  //   2. Scroll to "Your apps" > Web app > Config
  //   3. Copy the firebaseConfig values below
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyEXAMPLE_DEV_API_KEY',
    appId: '1:DEV_PROJECT_ID:web:dev_web_app_id',
    messagingSenderId: 'DEV_SENDER_ID',
    projectId: 'tayyebgo-dev',
    authDomain: 'tayyebgo-dev.firebaseapp.com',
    storageBucket: 'tayyebgo-dev.firebasestorage.app',
    measurementId: 'G-DEV_MEASUREMENT_ID',
  );
}
