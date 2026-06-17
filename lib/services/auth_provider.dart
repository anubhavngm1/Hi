// lib/services/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  Customer? _customer;
  bool _loading = false;

  Customer? get customer => _customer;
  bool get isLoggedIn => _customer != null;
  bool get loading => _loading;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.customerKey);
    if (data != null) {
      _customer = Customer.fromJson(jsonDecode(data));
      ApiService().setToken(_customer!.token);
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      final customer = await ApiService().login(email, password);
      await _saveCustomer(customer);
      return null;
    } catch (e) {
      _loading = false; notifyListeners();
      return e.toString();
    }
  }

  Future<String?> register(String name, String email, String password, String? phone) async {
    _loading = true; notifyListeners();
    try {
      final customer = await ApiService().register(name, email, password, phone);
      await _saveCustomer(customer);
      return null;
    } catch (e) {
      _loading = false; notifyListeners();
      return e.toString();
    }
  }

  Future<String?> googleLogin() async {
    _loading = true; notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _loading = false; notifyListeners();
        return 'Google sign in cancelled';
      }
      final customer = await ApiService().googleLogin(
        account.id, account.email, account.displayName ?? '',
      );
      await _saveCustomer(customer);
      return null;
    } catch (e) {
      _loading = false; notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.customerKey);
    ApiService().clearToken();
    _customer = null;
    notifyListeners();
  }

  Future<void> _saveCustomer(Customer customer) async {
    _customer = customer;
    ApiService().setToken(customer.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.customerKey, jsonEncode(customer.toJson()));
    _loading = false;
    notifyListeners();
  }
}
