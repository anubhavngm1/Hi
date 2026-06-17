// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> _get(String endpoint) async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: _headers,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Map<String, dynamic> _parse(http.Response res) {
    final data = jsonDecode(res.body);
    // Existing site uses {success: true, data: {...}} format
    if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
      return data['data'] ?? data;
    }
    throw ApiException(data['message'] ?? 'Something went wrong');
  }

  // ─── AUTH ─────────────────────────────────────────────
  Future<Customer> login(String email, String password) async {
    final data = await _post('auth/login.php', {
      'email': email, 'password': password,
    });
    return Customer.fromJson(data['customer']);
  }

  Future<Customer> register(String name, String email, String password, String? phone) async {
    final data = await _post('auth/register.php', {
      'name': name, 'email': email,
      'password': password, 'phone': phone ?? '',
    });
    return Customer.fromJson(data['customer']);
  }

  Future<Customer> googleLogin(String googleId, String email, String name) async {
    final data = await _post('auth/google-login.php', {
      'google_id': googleId, 'email': email, 'name': name,
    });
    return Customer.fromJson(data['customer']);
  }

  Future<void> saveFcmToken(String fcmToken) async {
    await _post('auth/save-fcm-token.php', {'fcm_token': fcmToken});
  }

  // ─── PACKAGES ─────────────────────────────────────────
  Future<List<Package>> getPackages({String? destination}) async {
    final query = destination != null ? 'packages.php?destination=$destination' : 'packages.php';
    final data  = await _get(query);
    final list  = data['packages'] ?? data['data']?['packages'] ?? [];
    return (list as List).map((e) => Package.fromJson(e)).toList();
  }

  Future<Package> getPackageDetail(int id) async {
    final data = await _get('packages.php?id=$id');
    return Package.fromJson(data['package'] ?? data);
  }

  // ─── HOTELS ───────────────────────────────────────────
  Future<List<Hotel>> getHotels({String? city}) async {
    final query = city != null ? 'hotels.php?city=$city' : 'hotels.php';
    final data  = await _get(query);
    final list  = data['hotels'] ?? data['data']?['hotels'] ?? [];
    return (list as List).map((e) => Hotel.fromJson(e)).toList();
  }

  Future<Hotel> getHotelDetail(int id) async {
    final data = await _get('hotels.php?id=$id');
    return Hotel.fromJson(data['hotel'] ?? data);
  }

  Future<List<HotelRoom>> getHotelRooms(int hotelId) async {
    final data = await _get('hotels.php?action=rooms&hotel_id=$hotelId');
    final list = data['rooms'] ?? data['data']?['rooms'] ?? [];
    return (list as List).map((e) => HotelRoom.fromJson(e)).toList();
  }

  // ─── ACTIVITIES ───────────────────────────────────────
  Future<List<Activity>> getActivities({String? category}) async {
    final query = category != null ? 'activities.php?category=$category' : 'activities.php';
    final data  = await _get(query);
    final list  = data['activities'] ?? data['data']?['activities'] ?? [];
    return (list as List).map((e) => Activity.fromJson(e)).toList();
  }

  // ─── BOOKINGS ─────────────────────────────────────────
  Future<Map<String, dynamic>> createPackageOrder(Map<String, dynamic> body) async {
    return await _post('bookings/create-order.php', body);
  }

  Future<Map<String, dynamic>> verifyPackagePayment(Map<String, dynamic> body) async {
    return await _post('bookings/verify-payment.php', body);
  }

  Future<Map<String, dynamic>> createHotelOrder(Map<String, dynamic> body) async {
    return await _post('bookings/create-hotel-order.php', body);
  }

  Future<Map<String, dynamic>> verifyHotelPayment(Map<String, dynamic> body) async {
    return await _post('bookings/verify-hotel-payment.php', body);
  }

  Future<Map<String, dynamic>> createActivityOrder(Map<String, dynamic> body) async {
    return await _post('bookings/create-activity-order.php', body);
  }

  Future<Map<String, dynamic>> verifyActivityPayment(Map<String, dynamic> body) async {
    return await _post('bookings/verify-activity-payment.php', body);
  }

  Future<List<Booking>> getMyBookings() async {
    final data = await _get('my-bookings.php');
    final list = data['package_bookings'] ?? data['bookings'] ?? [];
    return (list as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<List<HotelBooking>> getMyHotelBookings() async {
    final data = await _get('bookings/my-hotel-bookings.php');
    final list = data['bookings'] ?? [];
    return (list as List).map((e) => HotelBooking.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> checkCoupon(String code, double amount) async {
    return await _post('coupons/check.php', {'code': code, 'amount': amount});
  }

  Future<List<Map<String, dynamic>>> getDestinations() async {
    final data = await _get('destinations.php');
    final list = data['destinations'] ?? data['data']?['destinations'] ?? [];
    return List<Map<String, dynamic>>.from(list);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
