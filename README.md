# TPC Ops - Premium Ticket Scanning Application

A modern, polished Flutter application for ticket scanning operations with Clean Architecture and Riverpod state management.

## Features

✅ **Authentication System**
- Mock authentication (ready for backend integration)
- Persistent login state
- Smooth splash screen animation

✅ **QR Code Scanner**
- Real-time QR code scanning with mobile_scanner
- Three scan states: Valid, Already Scanned, Invalid
- Haptic and sound feedback
- Animated result cards

✅ **Dashboard**
- Real-time statistics
- Today's scan summary
- Recent scans list
- Greeting based on time of day

✅ **Scan History**
- Complete scan history with stats
- Pull-to-refresh functionality
- Search and filter capabilities
- Detailed scan information

✅ **Profile Management**
- User profile display
- App settings (Sound, Haptic, Dark Mode)
- Logout with confirmation

## Tech Stack

- **Flutter** - Latest version
- **Riverpod** - State management
- **go_router** - Navigation
- **mobile_scanner** - QR code scanning
- **freezed** - Immutable models
- **shared_preferences** - Local storage
- **Google Fonts** - Typography

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run code generation** (if needed)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Test Credentials

```
Email: admin@tpc.com
Password: admin123
```

## App Screens

1. **Splash Screen** - Animated logo with auto-navigation
2. **Login Screen** - Email/password authentication
3. **Home Screen** - Dashboard with stats and recent scans
4. **Scanner Screen** - QR code scanner with feedback
5. **Scan History** - Complete history with filters
6. **Profile Screen** - User settings and preferences

## Mock Data System

The app includes a robust mock data system:

- 200 mock tickets with randomized data
- Random scan validation (70% valid, 20% duplicate, 10% invalid)
- Time-stamped scan history
- Real-time statistics

## Build Commands

### Development
```bash
flutter run
```

### Release (Android)
```bash
flutter build apk --release
```

### Release (iOS)
```bash
flutter build ios --release
```

## Camera Permissions

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
```

## License

© 2025 TPC Ops. All rights reserved.

---

**Version:** 1.0.0
