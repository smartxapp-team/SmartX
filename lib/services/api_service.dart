import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String apiUrl;
  final String username;
  final String token;

  ApiService({required this.apiUrl, required this.username, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> fetchHomeData() async {
    final results = await Future.wait([
      fetchDashboardData(),
      fetchAcademicInfo(),
    ]);
    final dashboardData = results[0];
    final academicData = results[1];

    return {
      ...dashboardData,
      ...academicData,
    };
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final url = Uri.parse('$apiUrl/api/dashboard/$username');
    final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  Future<Map<String, dynamic>> fetchTimetable() async {
    final response = await http.get(Uri.parse('$apiUrl/api/timetable/$username'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load timetable');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> fetchAttendance() async {
    final response = await http.get(Uri.parse('$apiUrl/api/attendance/$username'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load attendance');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> fetchAttendanceRegister() async {
    final response = await http.get(Uri.parse('$apiUrl/api/attendance_register/$username'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load attendance register');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> fetchLeavePlannerData() async {
    final results = await Future.wait([
      fetchAttendance(),
      fetchTimetable(),
      fetchBioData(),
    ]);

    final attendanceData = results[0];
    final timetableData = results[1];
    final bioData = results[2];

    if (attendanceData.containsKey('error') || timetableData.containsKey('error') || bioData.containsKey('error')) {
      return {'error': 'Failed to load all required planner data'};
    }

    final subjects = { for (var course in attendanceData['courses']) course['name'] : course };

    return {
      'subjects': subjects,
      'timetable': timetableData['timetable'],
      'last_sem_date': attendanceData['last_sem_date'],
      'bio_log': bioData['bio_log'],
    };
  }

  Future<Map<String, dynamic>> fetchBioData() async {
    final response = await http.get(Uri.parse('$apiUrl/api/bio/$username'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load biometric data');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> fetchAllDeadlines() async {
    final data = await fetchDashboardData();
    return {'deadlines': data['deadline_summary_data']?['unsubmitted_labs'] ?? []};
  }

  Future<Map<String, dynamic>> fetchLabCourses() async {
    final response = await http.get(Uri.parse('$apiUrl/api/labs/courses/$username'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load lab courses');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> fetchLabDetails(String courseCode) async {
    final response = await http.get(Uri.parse('$apiUrl/api/labs/details/$username/$courseCode'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load lab details');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> fetchAcademicInfo() async {
    final attendanceFuture = fetchAttendance();
    final bioFuture = fetchBioData();

    final results = await Future.wait([attendanceFuture, bioFuture]);

    final attendanceData = results[0];
    final bioData = results[1];

    final classAttendance = (attendanceData['overall_percentage'] as num?)?.toDouble() ?? 0.0;
    
    final courses = List<Map<String, dynamic>>.from(attendanceData['courses'] ?? []);
    final totalAttended = courses.fold<int>(0, (prev, course) => prev + (course['attended'] as int? ?? 0));
    final totalConducted = courses.fold<int>(0, (prev, course) => prev + (course['conducted'] as int? ?? 0));

    final bioLog = List<Map<String, dynamic>>.from(bioData['bio_log'] ?? []);
    final presentDays = bioLog.where((item) => (item['status'] as String? ?? '').trim().toLowerCase().startsWith('p')).length;
    final totalDays = bioLog.length;
    final bioAttendance = totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;

    return {
      'class_attendance': classAttendance,
      'total_attended': totalAttended,
      'total_conducted': totalConducted,
      'bio_attendance': bioAttendance,
      'present_days': presentDays,
      'total_bio_days': totalDays,
    };
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await http.get(Uri.parse('$apiUrl/api/profile/$username'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load profile');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> fetchResults() async {
    final response = await http.get(Uri.parse('$apiUrl/api/results/$username'), headers: _headers).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to load results');
    return json.decode(response.body);
  }
}
