// lib/utils/constants.dart
class AppConstants {
  // ⚠️ APNA URL YAHAN DAALO
  static const String baseUrl = 'https://ebostay.com/api';

  // App Info
  static const String appName = 'EBO Stay';
  static const String currency = '₹';

  // Colors
  static const int primaryColorValue = 0xFF0B1320;   // Dark Navy
  static const int goldColorValue    = 0xFFD4AF6A;   // Warm Gold
  static const int accentColorValue  = 0xFF1A2840;
  static const int bgColorValue      = 0xFFF8F5F0;

  // SharedPref Keys
  static const String tokenKey       = 'auth_token';
  static const String customerKey    = 'customer_data';
  static const String fcmTokenKey    = 'fcm_token';

  // Razorpay
  static const String razorpayKey = 'rzp_live_XXXXXXXXXXXXX'; // Apni live key daalo

  // Google Sign In
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
}
