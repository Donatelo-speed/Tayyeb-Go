# Firebase Console Configuration Guide

## Overview
These settings MUST be configured in the Firebase Console (https://console.firebase.google.com).
They cannot be set via code — they are project-level configurations.

---

## 1. Enable Apple Sign-In (iOS)

### Steps:
1. Go to **Firebase Console** → **Authentication** → **Sign-in method**
2. Click **Apple** → Toggle **Enable**
3. Enter your **Apple Developer Team ID**:
   - Go to https://developer.apple.com/account
   - Copy your Team ID (found in Membership details)
4. Enter your **Service ID** (e.g., `com.tayyebgo.app`)
5. Enter your **Key ID** (from Apple Developer → Keys)
6. Upload your **Apple Sign-In private key** (.p8 file)
7. Click **Save**

### Required Apple Developer Setup:
- Create an App ID with "Sign in with Apple" capability
- Create a Services ID for web sign-in
- Generate a Sign in with Apple key (.p8 file)

---

## 2. Enable Email/Password Authentication

### Steps:
1. Go to **Firebase Console** → **Authentication** → **Sign-in method**
2. Click **Email/Password** → Toggle **Enable**
3. (Optional) Toggle **Email link (passwordless sign-in)** if desired
4. Click **Save**

### Already configured in code:
- `AuthProvider.login()` — email/password login
- `AuthProvider.signUp()` — email/password registration
- Password reset via `AuthProvider.resetPassword()`

---

## 3. Enable Phone Authentication (SMS)

### Steps:
1. Go to **Firebase Console** → **Authentication** → **Sign-in method**
2. Click **Phone** → Toggle **Enable**
3. Set **Phone numbers for testing** (optional, for development)
4. Configure **SMS rate limiting** (recommended: 10 SMS per hour per user)
5. Click **Save`

### Required for SMS:
- Enable billing on your Firebase project (phone auth requires Blaze plan)
- Phone auth uses Firebase's built-in SMS service
- For production, consider configuring a custom SMS provider (Twilio, etc.)

### Already configured in code:
- `AuthProvider.sendOtp()` — sends SMS verification code
- `AuthProvider.verifyOtpCode()` — verifies the code
- `AuthProvider.loginWithPhone()` — phone-based login

---

## 4. Enable Google Sign-In

### Steps:
1. Go to **Firebase Console** → **Authentication** → **Sign-in method**
2. Click **Google** → Toggle **Enable**
3. Enter your **Support email** (your email address)
4. Click **Save**

### Required for Web:
- Go to **Project Settings** → **General** → **Web API Key**
- Add Firebase config to your web app's `index.html` (already done)

### Required for Android:
- Download `google-services.json` and place in `android/app/`
- Add Google Services classpath to `android/build.gradle`

### Required for iOS:
- Download `GoogleService-Info.plist` and add to `ios/Runner/`
- Add Google Services pod to `ios/Podfile`

### Already configured in code:
- `AuthProvider.loginWithGoogle()` — Google sign-in flow

---

## 5. Cloud Functions Deployment

### New functions added:
- `onUserCreated` — Welcome notification when user signs up
- `onOrderStatusNotify` — Order status update notifications (push + in-app)
- `onDriverAssigned` — Driver assignment notifications

### Deploy:
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Existing functions (already deployed):
- `onNotificationCreated` — FCM push notifications
- `registerFcmToken` — FCM token registration
- `cleanupNotifications` — Daily cleanup of old notifications
- `onDispatchCreated` / `onDispatchAccepted` — Driver dispatch
- `createStripePaymentIntent` — Stripe payments
- `processPayouts` — Driver payouts
- `validatePromo` — Promo code validation

---

## 6. Google Maps API Key

### Steps:
1. Go to **Google Cloud Console** → **APIs & Services** → **Credentials**
2. Create an **API Key** (or use existing)
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API (for web)
   - Geocoding API
   - Directions API
   - Distance Matrix API

### Android Configuration:
1. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### iOS Configuration:
1. Add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### Web Configuration:
1. Add to `web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
```

### Already configured in code:
- `DriverLocationService` — Real-time driver location tracking
- `ETAService` — Estimated time of arrival calculations
- `RouteOptimizationService` — Delivery route optimization

---

## 7. Firestore Security Rules

### Current rules are comprehensive (697 lines).
Key security patterns:
- Users can only read/write their own documents
- Drivers can only update their own location and delivery status
- Partners can only manage their own restaurant data
- Admins have elevated read access
- All writes validate required fields

### Deploy:
```bash
firebase deploy --only firestore:rules
```

---

## 8. Storage Rules

### Current rules:
- Users can upload profile photos (10MB max)
- Partners can upload restaurant/menu images (5MB max)
- Admins can manage all files

### Deploy:
```bash
firebase deploy --only storage
```

---

## 9. Enable Push Notifications

### Already configured:
- FCM token registration via `registerFcmToken` Cloud Function
- Push notifications sent via `onNotificationCreated` trigger
- Notification cleanup via `cleanupNotifications` scheduler

### Android Setup:
- `google-services.json` must be in `android/app/`
- FCM is configured automatically

### iOS Setup:
- Apple Push Notification service (APNs) key must be uploaded to Firebase
- Go to **Project Settings** → **Cloud Messaging** → **Apple app configuration**
- Upload your APNs authentication key (.p8 file)

---

## 10. Environment Configuration

### Dev environment:
- Replace `firebase_options_dev.dart` placeholder values with actual dev project config
- Or use `flutterfire configure` to auto-generate

### Staging environment:
- Replace `firebase_options_staging.dart` placeholder values with actual staging project config

### Production environment:
- Already configured in `firebase_options_prod.dart`

### Generate config automatically:
```bash
flutterfire configure --project=tayyebgo
```

---

## Quick Reference

| Feature | Status | Action Required |
|---------|--------|-----------------|
| Email/Password Auth | ✅ Code ready | Enable in Firebase Console |
| Phone Auth (SMS) | ✅ Code ready | Enable in Firebase Console + Enable billing |
| Google Sign-In | ✅ Code ready | Enable in Firebase Console |
| Apple Sign-In | ✅ Code ready | Enable in Firebase Console + Apple Developer setup |
| Push Notifications | ✅ Fully configured | Upload APNs key for iOS |
| Welcome Emails | ✅ Cloud Function added | Deploy with `firebase deploy --only functions` |
| Order Notifications | ✅ Cloud Function added | Deploy with `firebase deploy --only functions` |
| Google Maps | ⚠️ API key needed | Create API key + add to platform configs |
| Stripe Payments | ✅ Fully configured | Already working |
| Firestore Rules | ✅ Comprehensive | Already deployed |
