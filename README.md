# TPC Ops - Ticket Scanner App

Mobile application for scanning QR-coded event tickets with vendor-based access control.

## 🚀 Quick Start

### For Development
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.6:3001
```

### For Production Build
```bash
build-prod.bat
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

## 📖 Complete Documentation

**👉 See [DOCUMENTATION.md](DOCUMENTATION.md) for complete setup, architecture, and deployment guide.**

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_config.dart          # Environment configuration
│   ├── router/
│   │   └── app_router.dart          # Navigation
│   └── theme/
│       └── app_colors.dart          # Branding
├── features/
│   ├── auth/
│   │   ├── data/repositories/
│   │   │   └── auth_repository.dart # Login logic
│   │   └── presentation/screens/
│   │       └── login_screen.dart    # Login UI
│   └── scanner/
│       ├── data/repositories/
│       │   └── scanner_repository.dart # Ticket validation
│       └── presentation/screens/
│           └── scanner_screen.dart  # QR scanner UI
```

## 🔑 Key Features

- **Authentication:** Login via vendor portal API
- **QR Scanning:** Camera-based ticket scanning
- **Security:** HMAC-SHA256 signature verification
- **Vendor Isolation:** Members can only scan their vendor's tickets
- **Offline Capable:** Local session storage

## 🛠️ Tech Stack

- **Flutter/Dart** - Mobile framework
- **Supabase** - Database & serverless functions
- **Vendor Portal API** - Authentication & member management
- **PostgreSQL** - Ticket data storage

## 📦 Dependencies

Key packages:
- `supabase_flutter` - Database client
- `mobile_scanner` - QR code scanning
- `http` - API calls
- `flutter_riverpod` - State management
- `go_router` - Navigation

## 🌍 Environment Configuration

**Production:** `https://vendor.trippechalo.in`
**Development:** `http://192.168.1.6:3001`

Configured via `--dart-define` flags at build time.

## 📱 Build Commands

**Development APK:**
```bash
build-dev.bat
```

**Production APK:**
```bash
build-prod.bat
```

**Play Store Bundle:**
```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://vendor.trippechalo.in \
  --dart-define=PRODUCTION=true
```

## 🗄️ Database Setup

Run [supabase_function.sql](supabase_function.sql) in Supabase SQL Editor to create the `verify_and_use_ticket` function.

## 🎨 Customization

- **App Icon:** `assets/icon/app_icon.png`
- **Colors:** `lib/core/theme/app_colors.dart`
- **Branding:** "TPC Ops"

## 📝 Documentation

- **[DOCUMENTATION.md](DOCUMENTATION.md)** - Complete technical documentation
- **[supabase_function.sql](supabase_function.sql)** - Database function setup
- **[.env.development](.env.development)** - Dev environment config
- **[.env.production](.env.production)** - Prod environment config

## 🧪 Testing

```bash
# Test with development API
flutter run --dart-define=API_BASE_URL=http://192.168.1.6:3001

# Test with production API
flutter run --dart-define=API_BASE_URL=https://vendor.trippechalo.in
```

## 🚀 Deployment

1. Build production APK: `build-prod.bat`
2. Test on physical device
3. Upload to Play Store or distribute directly

## 📞 Support

For detailed setup, architecture, API documentation, and troubleshooting:

**👉 Read [DOCUMENTATION.md](DOCUMENTATION.md)**

---

**Version:** 1.0.0
**Platform:** Flutter (Android/iOS)
**Production URL:** https://vendor.trippechalo.in
