import 'package:firebase_core/firebase_core.dart';

/// Paste your Firebase Web App config here.
///
/// Get these values from your Firebase Console:
///   Project Settings → General → Your apps → Web app → Config
///
/// Example from console:
///   const firebaseConfig = {
///     apiKey: "AIzaSy...",
///     authDomain: "your-project.firebaseapp.com",
///     projectId: "your-project",
///     storageBucket: "your-project.firebasestorage.app",
///     messagingSenderId: "123456789",
///     appId: "1:123456789:web:abc123...",
///     measurementId: "G-XXXXXXXXXX"
///   };
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  // ─────────────────────────────────────────────────────────
  // 👇 REPLACE the dummy values below with YOUR real keys
  // ─────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwVf76nVKlxpVloPRklEax7EjlXivZcK4',
    appId: '1:704530942839:web:7e11271910bc913d6e2f72',
    messagingSenderId: '704530942839',
    projectId: 'tayyebgo',
    authDomain: 'tayyebgo.firebaseapp.com',
    storageBucket: 'tayyebgo.firebasestorage.app',
    measurementId: 'G-R72V81JGFF',
  );
}
