import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'lab_details_screen.dart';

class LabSubjectsScreen extends StatefulWidget {
  const LabSubjectsScreen({super.key});

  @override
  State<LabSubjectsScreen> createState() => _LabSubjectsScreenState();
}

class _LabSubjectsScreenState extends State<LabSubjectsScreen> {
  late Future<Map<String, dynamic>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      final apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!);
      _coursesFuture = apiService.fetchLabCourses();
    } else {
      _coursesFuture = Future.value({"error": "Not logged in."});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Courses')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _coursesFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.containsKey('error')) {
            return Center(child: Text(snapshot.data?['error'] ?? 'Could not fetch lab courses.'));
          }

          final courses = List<Map<String, dynamic>>.from(snapshot.data!['courses']);
          if (courses.isEmpty) {
            return const Center(child: Text('No lab courses found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: courses.length,
            itemBuilder: (ctx, index) {
              final course = courses[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: const Icon(Icons.biotech_outlined, size: 28),
                  title: Text(course['name'] ?? 'Unknown Course'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => LabDetailsScreen(
                          courseCode: course['code'],
                          courseName: course['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
