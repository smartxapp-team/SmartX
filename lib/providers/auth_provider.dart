import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';

import '../config/app_config.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _username;
  String? _fullName;
  String? _profilePictureUrl;
  final String _apiUrl = AppConfig.apiUrl;
  bool _isLoggedIn = false;
  bool _biometricEnabled = false; // New field
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? get token => _token;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get profilePictureUrl => _profilePictureUrl;
  String get apiUrl => _apiUrl;
  bool get isLoggedIn => _isLoggedIn;
  bool get biometricEnabled => _biometricEnabled; // New getter

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final credentials = await _secureStorage.readAll();
    if (credentials.containsKey('username') && credentials.containsKey('password')) {
      _username = credentials['username'];
      _fullName = credentials['fullName'];
      _profilePictureUrl = credentials['profilePictureUrl'];
      _biometricEnabled = (await _secureStorage.read(key: 'biometric_enabled') == 'true'); // Read biometric state

      final success = await login(credentials['username']!, credentials['password']!); 
      if (success) {
        _isLoggedIn = true;
      } else if (_fullName != null && _username != null) {
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    } else {
      _isLoggedIn = false;
    }
    notifyListeners();
  }

  Future<bool> authenticateOnDemand() async {
    if (!_biometricEnabled) { // Check if biometric is enabled
      return true; // If not enabled, bypass biometric auth
    }
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to view your data',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } on PlatformException {
      return false; // Error (e.g., no biometrics, user cancels)
    }
  }

  Future<bool> login(String user, String password) async {
    try {
      final loginUrl = Uri.parse(_apiUrl).resolve('api/login');
      final body = {'username': user, 'password': password};

      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _username = user;
        _fullName = data['fullName'];
        _profilePictureUrl = data['profilePictureUrl'];
        _isLoggedIn = true;

        await _secureStorage.write(key: 'username', value: user);
        await _secureStorage.write(key: 'password', value: password);
        if (_fullName != null) {
          await _secureStorage.write(key: 'fullName', value: _fullName!);
        }
        if (_profilePictureUrl != null) {
          await _secureStorage.write(key: 'profilePictureUrl', value: _profilePictureUrl!);
        }
        // Store biometric_enabled state on successful login too, in case it was toggled before login
        await _secureStorage.write(key: 'biometric_enabled', value: _biometricEnabled.toString());

        notifyListeners();
        return true;
      } else {
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enable) async {
    _biometricEnabled = enable;
    await _secureStorage.write(key: 'biometric_enabled', value: enable.toString());
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    _fullName = null;
    _profilePictureUrl = null;
    _isLoggedIn = false;
    _biometricEnabled = false; // Clear biometric state on logout
    await _secureStorage.deleteAll();
    notifyListeners();
  }
}
