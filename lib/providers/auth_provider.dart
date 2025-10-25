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
  final String _apiUrl = AppConfig.apiUrl;
  bool _isLoggedIn = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? get token => _token;
  String? get username => _username;
  String get apiUrl => _apiUrl;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _tryAutoLogin();
  }

  // This now only attempts to log in with stored creds, without biometrics.
  Future<void> _tryAutoLogin() async {
    final credentials = await _secureStorage.readAll();
    if (credentials.containsKey('username') && credentials.containsKey('password')) {
      await login(credentials['username']!, credentials['password']!);
    } else {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // New method to be called from the UI to show the biometric prompt.
  Future<bool> authenticateOnDemand() async {
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
        _isLoggedIn = true;

        await _secureStorage.write(key: 'username', value: user);
        await _secureStorage.write(key: 'password', value: password);

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

  Future<void> logout() async {
    _token = null;
    _username = null;
    _isLoggedIn = false;
    await _secureStorage.deleteAll();
    notifyListeners();
  }
}
