import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

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
