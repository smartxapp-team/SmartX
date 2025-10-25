import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AttendanceRegisterProvider with ChangeNotifier {
  Map<String, dynamic>? _attendanceData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get attendanceData => _attendanceData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAttendanceData(ApiService apiService) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch both sets of data concurrently
      final results = await Future.wait([
        apiService.fetchAttendanceRegister(),
        apiService.fetchAttendance(),
      ]);

      final registerData = results[0];
      final attendanceData = results[1];

      // Extract the ordered list of course names from the attendance data
      final orderedCourses = List<Map<String, dynamic>>.from(attendanceData['courses']);
      final orderedSubjects = orderedCourses.map((c) => c['name'] as String).toList();
      
      // Get the list of subjects from the register data
      final registerSubjects = List<String>.from(registerData['subjects']);

      // Create a new sorted list based on the order from attendance data
      final sortedSubjects = <String>[];
      for (var subjectName in orderedSubjects) {
        if (registerSubjects.contains(subjectName)) {
          sortedSubjects.add(subjectName);
        }
      }

      // Add any subjects that might be in the register but not in the main attendance list
      for (var subjectName in registerSubjects) {
        if (!sortedSubjects.contains(subjectName)) {
          sortedSubjects.add(subjectName);
        }
      }

      // Replace the subjects in the register data with the newly sorted list
      registerData['subjects'] = sortedSubjects;

      _attendanceData = registerData;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _attendanceData = null; // Clear data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
