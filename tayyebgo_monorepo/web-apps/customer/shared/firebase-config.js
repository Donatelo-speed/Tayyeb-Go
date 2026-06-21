// Firebase Configuration for TayyebGo Customer Web App
// Uses the same Firebase project as the Flutter apps

import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import { getAuth, GoogleAuthProvider, PhoneAuthProvider, OAuthProvider } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';
import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';
import { getStorage } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-storage.js';
import { getMessaging } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging.js';

// Firebase config - Production
const firebaseConfig = {
  apiKey: "AIzaSyBwVf76nVKlxpVloPRklEax7EjlXivZcK4",
  authDomain: "tayyebgo.firebaseapp.com",
  projectId: "tayyebgo",
  storageBucket: "tayyebgo.firebasestorage.app",
  messagingSenderId: "704530942839",
  appId: "1:704530942839:web:7e11271910bc913d6e2f72",
  measurementId: "G-R72V81JGFF"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export let messaging = null;

// Initialize messaging (only in browser)
try {
  if ('serviceWorker' in navigator) {
    messaging = getMessaging(app);
  }
} catch (e) {
  console.log('Messaging not available:', e);
}

// Auth providers
export const googleProvider = new GoogleAuthProvider();
export const appleProvider = new OAuthProvider('apple.com');
export const phoneProvider = new PhoneAuthProvider(auth);

export default app;
