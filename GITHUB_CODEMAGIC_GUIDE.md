# 🚀 EBO Stay App - GitHub + Codemagic Setup

## Step 1: GitHub Repo Banao

1. [github.com](https://github.com) pe login karo
2. **New Repository** click karo
3. Name: `ebostay-app`
4. Private rakho ✅
5. **Create repository** click karo

---

## Step 2: Files Upload Karo

GitHub pe repo banane ke baad **"uploading an existing file"** click karo:

1. ZIP extract karo apne PC pe
2. **Saari files drag & drop** karo GitHub pe
   - `lib/` folder
   - `android/` folder
   - `pubspec.yaml`
   - `codemagic.yaml`
   - `.gitignore`
3. **Commit changes** click karo

---

## Step 3: Firebase google-services.json Add Karo

1. [console.firebase.google.com](https://console.firebase.google.com)
2. New Project → **EBO Stay**
3. Android app add karo:
   - Package: `com.ebostay.app`
   - App nickname: EBO Stay
4. **google-services.json** download karo
5. GitHub pe `android/app/google-services.json` replace karo (placeholder file hai wahan)

---

## Step 4: Codemagic Connect Karo

1. [codemagic.io](https://codemagic.io) pe **GitHub se login** karo
2. **Add application** → GitHub repo select karo `ebostay-app`
3. Framework: **Flutter**
4. **Finish: Add application**

---

## Step 5: Build Start Karo

1. Codemagic dashboard pe apna app dikhega
2. **Start new build** click karo
3. Workflow: **android-release** select karo
4. **Start build** 🚀

**10-15 minute mein APK ready!**

---

## Step 6: APK Download Karo

Build complete hone ke baad:
- Codemagic dashboard pe **Artifacts** section mein `app-release.apk` milega
- Download karo → phone pe install karo ✅

---

## ⚠️ Constants Update Karna Mat Bhoolo

`lib/utils/constants.dart` mein apni values daalo:

```dart
static const String baseUrl      = 'https://ebostay.com/api';
static const String razorpayKey  = 'rzp_live_XXXXX';  // apni live key
```

Ye change karne ke baad GitHub pe commit karo → Codemagic automatically rebuild karega.

---

## 📱 Phone Pe Install

```
Settings → Security → Unknown Sources → ON
```
Phir APK install karo.

Play Store pe publish karne ke liye Codemagic mein signing setup karo (baad mein).
