// lib/utils/constants.dart
class AppConstants {
  static const String baseUrl = 'https://ebostay.com/api';

  // App Info
  static const String appName = 'EBO Stay';
  static const String currency = '₹';

  // Colors
  static const int primaryColorValue = 0xFF0B1320;
  static const int goldColorValue    = 0xFFD4AF6A;
  static const int accentColorValue  = 0xFF1A2840;
  static const int bgColorValue      = 0xFFF8F5F0;

  // SharedPref Keys
  static const String tokenKey    = 'auth_token';
  static const String customerKey = 'customer_data';
  static const String fcmTokenKey = 'fcm_token';

  // Razorpay (test key hai — live pe jaane se pehle rzp_live_ wali daalna)
  static const String razorpayKey = 'rzp_test_T1SySI9LWEnANJ';

  // Google Sign In
  static const String googleClientId = '368019213816-gro2843f7c0oc93rjp7l4c57cjnrigdd.apps.googleusercontent.com';
}
