import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile(ApiService apiService) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.fetchProfile();
      _profile = Profile.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
