# 🔥 Firebase Setup Guide for GyaanBuddy App

## **Prerequisites**
1. Firebase Console account: [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Flutter project with Firebase dependencies installed

## **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `gyaanbuddy-app` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Choose analytics account or create new one
6. Click "Create project"

## **Step 2: Add Android App**

1. In Firebase project, click Android icon (🤖)
2. Enter Android package name: `com.example.gyaanbuddy`
3. Enter app nickname: `GyaanBuddy Android`
4. Click "Register app"
5. Download `google-services.json` file
6. Place it in `android/app/` directory

## **Step 3: Add iOS App**

1. In Firebase project, click iOS icon (🍎)
2. Enter iOS bundle ID: `com.example.gyaanbuddy`
3. Enter app nickname: `GyaanBuddy iOS`
4. Click "Register app"
5. Download `GoogleService-Info.plist` file
6. Place it in `ios/Runner/` directory

## **Step 4: Configure Android**

### **Update android/build.gradle:**
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### **Update android/app/build.gradle:**
```gradle
// Add at the bottom
apply plugin: 'com.google.gms.google-services'
```

## **Step 5: Configure iOS**

### **Update ios/Podfile:**
```ruby
# Add this line at the top
platform :ios, '12.0'
```

### **Update ios/Runner/Info.plist:**
```xml
<!-- Add Firebase configuration -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>REVERSED_CLIENT_ID_FROM_GOOGLESERVICE_INFO_PLIST</string>
        </array>
    </dict>
</array>
```

## **Step 6: Enable Firebase Services**

### **Authentication:**
1. Go to Authentication > Sign-in method
2. Enable Email/Password
3. Enable Google Sign-in (optional)
4. Add your domain to authorized domains

### **Firestore Database:**
1. Go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select location closest to your users
5. Click "Done"

### **Storage:**
1. Go to Storage
2. Click "Get started"
3. Choose "Start in test mode" (for development)
4. Select location
5. Click "Done"

## **Step 7: Test Firebase Connection**

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run the app
4. Check console for Firebase initialization messages

## **Step 8: Security Rules (Production)**

### **Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read public data
    match /public/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

### **Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## **Troubleshooting**

### **Common Issues:**
1. **Build errors**: Make sure `google-services.json` is in correct location
2. **iOS build fails**: Check minimum iOS version in Podfile
3. **Firebase not initializing**: Check internet connection and Firebase project settings

### **Debug Commands:**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## **Next Steps**

After Firebase is configured:
1. Implement user authentication
2. Set up Firestore data models
3. Create Firebase service classes
4. Integrate with existing BLoC pattern

## **Support**

- Firebase Documentation: [https://firebase.flutter.dev/](https://firebase.flutter.dev/)
- Flutter Firebase Plugin: [https://pub.dev/packages/firebase_core](https://pub.dev/packages/firebase_core)
