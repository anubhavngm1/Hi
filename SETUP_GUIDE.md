# EBO Stay Flutter App - Setup Guide

## 📁 Folder Structure
```
ebostay_flutter/    → Flutter app code
ebostay_api/        → PHP API files (upload to server)
```

---

## 🚀 Step 1: PHP API Server pe Upload Karo

1. `ebostay_api/api/` folder ko apne server pe upload karo:
   ```
   public_html/api/          ← ye folder create karo
   ```

2. `ebostay_api/config/config.php` mein apni keys daalo:
   ```php
   define('RAZORPAY_KEY_ID',     'rzp_live_...');
   define('RAZORPAY_KEY_SECRET', 'your_secret');
   define('FCM_SERVER_KEY',      'your_fcm_key');
   ```

3. `database_migration_app.sql` ko phpMyAdmin se run karo

4. Test karo browser mein:
   ```
   https://ebostay.com/api/packages.php
   https://ebostay.com/api/hotels.php
   https://ebostay.com/api/activities.php
   ```

---

## 🔥 Step 2: Firebase Setup

1. [console.firebase.google.com](https://console.firebase.google.com) pe jao
2. New Project → "EBO Stay"
3. **Android App add karo:**
   - Package name: `com.ebostay.app`
   - `google-services.json` download karo → `android/app/` mein rakh do
4. **Cloud Messaging enable karo:**
   - Project Settings → Cloud Messaging → Server Key copy karo
   - `config.php` mein `FCM_SERVER_KEY` mein paste karo
5. **VAPID Key (Web Push - optional):**
   - Project Settings → Cloud Messaging → Web Push certificates

---

## 📱 Step 3: Flutter App Setup

### Flutter Install (agar nahi hai):
```bash
# Flutter SDK download: https://flutter.dev/docs/get-started/install
flutter doctor    # check dependencies
```

### App Configure Karo:

**`lib/utils/constants.dart`** mein:
```dart
static const String baseUrl = 'https://ebostay.com/api';
static const String razorpayKey = 'rzp_live_XXXXX';  // apni live key
```

### Dependencies Install + Run:
```bash
cd ebostay_flutter
flutter pub get
flutter run                  # device connected hona chahiye
flutter build apk --release  # APK banane ke liye
```

---

## 🔑 Step 4: Google Sign-In Setup

1. [console.cloud.google.com](https://console.cloud.google.com) → apna project
2. APIs & Services → Credentials → OAuth 2.0 Client ID
3. Android ke liye: SHA-1 fingerprint add karo
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Client ID ko `constants.dart` mein `googleClientId` mein daalo

---

## 📲 Step 5: Admin FCM Token Save Karna

Admin ko notifications aayein, uske liye:
1. Admin apne phone pe ek test app install kare ya website pe token save kare
2. Ya directly phpMyAdmin se:
   ```sql
   UPDATE site_settings SET value = 'ADMIN_FCM_TOKEN_HERE'
   WHERE key_name = 'admin_fcm_token';
   ```

---

## 🔔 Notifications Flow

| Event | Customer Ko | Admin Ko |
|-------|-------------|----------|
| Tour booking confirm | ✅ "Booking Confirmed!" | ✅ "New Booking!" |
| Hotel booking confirm | ✅ "Hotel Confirmed!" | ✅ "New Hotel Booking!" |
| Activity booking confirm | ✅ "Activity Confirmed!" | ✅ "New Activity!" |

---

## 🧪 API Test (Postman/Browser)

```
GET  https://ebostay.com/api/packages.php
GET  https://ebostay.com/api/hotels.php?city=Goa
GET  https://ebostay.com/api/activities.php?category=Water+Sports

POST https://ebostay.com/api/auth/login.php
     Body: {"email":"test@test.com","password":"123456"}

POST https://ebostay.com/api/auth/register.php
     Body: {"name":"Test","email":"t@t.com","password":"123456","phone":"9876543210"}
```

---

## 📦 Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Play Store pe upload ke liye:
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## ✅ Checklist

- [ ] API files server pe upload
- [ ] `config.php` mein Razorpay keys daali
- [ ] `database_migration_app.sql` run kiya
- [ ] Firebase project create kiya
- [ ] `google-services.json` add kiya
- [ ] FCM Server Key `config.php` mein daali
- [ ] `constants.dart` mein `baseUrl` aur `razorpayKey` set kiye
- [ ] `flutter pub get` run kiya
- [ ] App test kiya device pe
- [ ] APK build kiya
