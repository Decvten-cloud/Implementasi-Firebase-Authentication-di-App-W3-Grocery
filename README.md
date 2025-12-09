# flutter_application_12

A new Flutter project.

## Firebase Setup

This project uses **Firebase Authentication** for user login and vendor/driver authentication. Before running the app, complete the following setup steps:

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Register your app:
   - **Android**: Package name: `com.example.flutter_application_12`
   - **iOS**: Bundle ID: `com.example.flutterApplication12`

### 2. Android Setup
- **Already Configured**: `google-services.json` is present in `android/app/`
- **Verify**: Ensure your `google-services.json` is downloaded from the Firebase Console
- **SHA-1 for Google Sign-In** (if using Google Sign-In):
  1. Get your app's SHA-1 fingerprint:
     ```bash
     ./gradlew signingReport
     ```
  2. Add the SHA-1 to your Firebase project settings (Android app configuration)

### 3. iOS Setup
- Download `GoogleService-Info.plist` from Firebase Console
- Add it to the iOS Runner project:
  1. Open `ios/Runner.xcworkspace` in Xcode
  2. Right-click "Runner" → "Add Files to Runner"
  3. Select `GoogleService-Info.plist`

### 4. Enable Authentication Methods
In Firebase Console → Authentication → Sign-in method:
- Enable **Email/Password** authentication
- (Optional) Enable **Google Sign-In** after adding SHA-1

### 5. Run the App
```bash
flutter pub get
flutter run
```

### Features
- **Email/Password Login**: Users can sign up and log in via Firebase Auth
- **Vendor/Driver Login**: Role-based login with Firebase fallback to simulated APIs
- **Password Reset**: Users can request password reset emails
- **Main App Access**: After successful authentication, users access the grocery app

### Troubleshooting
- **reCAPTCHA Configuration Error**: This occurs in development if the app isn't fully set up in Firebase Console. Ensure all steps above are completed.
- **Network Errors**: Check that `google-services.json` is properly configured
- **iOS Build Errors**: Ensure `GoogleService-Info.plist` is added to the Xcode project

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
