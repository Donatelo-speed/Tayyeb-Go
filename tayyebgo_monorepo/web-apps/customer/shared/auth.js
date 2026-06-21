// Authentication Service for TayyebGo Customer Web App
import { auth, db, googleProvider, appleProvider } from './firebase-config.js';
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signInWithPopup,
  signInWithPhoneNumber,
  sendPasswordResetEmail,
  signOut,
  onAuthStateChanged,
  updateProfile
} from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';
import { doc, getDoc, setDoc, serverTimestamp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';

class AuthService {
  constructor() {
    this.currentUser = null;
    this.listeners = [];
  }

  // Listen for auth state changes
  onAuthChange(callback) {
    this.listeners.push(callback);
    return onAuthStateChanged(auth, (user) => {
      this.currentUser = user;
      callback(user);
    });
  }

  // Email/Password Signup
  async signupWithEmail(email, password, displayName) {
    try {
      const result = await createUserWithEmailAndPassword(auth, email, password);
      await updateProfile(result.user, { displayName });
      await this.createUserDocument(result.user, displayName);
      return { success: true, user: result.user };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Email/Password Login
  async loginWithEmail(email, password) {
    try {
      const result = await signInWithEmailAndPassword(auth, email, password);
      return { success: true, user: result.user };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Google Sign-In
  async loginWithGoogle() {
    try {
      const result = await signInWithPopup(auth, googleProvider);
      await this.createUserDocument(result.user, result.user.displayName);
      return { success: true, user: result.user };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Apple Sign-In
  async loginWithApple() {
    try {
      const result = await signInWithPopup(auth, appleProvider);
      await this.createUserDocument(result.user, result.user.displayName);
      return { success: true, user: result.user };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Phone OTP - Send code
  async sendPhoneOTP(phoneNumber, appVerifier) {
    try {
      const confirmation = await signInWithPhoneNumber(auth, phoneNumber, appVerifier);
      return { success: true, confirmation };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Phone OTP - Verify code
  async verifyPhoneOTP(confirmation, otpCode) {
    try {
      const result = await confirmation.confirm(otpCode);
      await this.createUserDocument(result.user, result.user.displayName || 'User');
      return { success: true, user: result.user };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Password Reset
  async resetPassword(email) {
    try {
      await sendPasswordResetEmail(auth, email);
      return { success: true };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Logout
  async logout() {
    try {
      await signOut(auth);
      this.currentUser = null;
      return { success: true };
    } catch (error) {
      return { success: false, error: this.handleError(error) };
    }
  }

  // Create user document in Firestore
  async createUserDocument(user, displayName) {
    if (!user) return;
    const userRef = doc(db, 'users', user.uid);
    const userSnap = await getDoc(userRef);

    if (!userSnap.exists()) {
      await setDoc(userRef, {
        uid: user.uid,
        email: user.email,
        displayName: displayName || user.displayName || 'User',
        phoneNumber: user.phoneNumber || null,
        photoURL: user.photoURL || null,
        role: 'customer',
        loyaltyPoints: 0,
        loyaltyTier: 'bronze',
        walletBalance: 0,
        referralCode: this.generateReferralCode(),
        referredBy: null,
        addresses: [],
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
    }
  }

  // Get user data from Firestore
  async getUserData(uid) {
    try {
      const userRef = doc(db, 'users', uid);
      const userSnap = await getDoc(userRef);
      if (userSnap.exists()) {
        return { success: true, data: userSnap.data() };
      }
      return { success: false, error: 'User not found' };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Generate unique referral code
  generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = 'TAY';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  // Handle Firebase errors
  handleError(error) {
    const errorMessages = {
      'auth/email-already-in-use': 'This email is already registered',
      'auth/invalid-email': 'Invalid email address',
      'auth/operation-not-allowed': 'This sign-in method is not enabled',
      'auth/weak-password': 'Password is too weak',
      'auth/user-disabled': 'This account has been disabled',
      'auth/user-not-found': 'No account found with this email',
      'auth/wrong-password': 'Incorrect password',
      'auth/too-many-requests': 'Too many attempts. Please try again later',
      'auth/network-request-failed': 'Network error. Check your connection',
      'auth/popup-closed-by-user': 'Sign-in popup was closed',
      'auth/cancelled-popup-request': 'Sign-in cancelled'
    };
    return errorMessages[error.code] || error.message;
  }
}

export const authService = new AuthService();
export default authService;
