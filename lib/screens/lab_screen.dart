import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';
import 'lab_details_screen.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  late Future<Map<String, dynamic>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      final apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!, token: authProvider.token!);
      _coursesFuture = apiService.fetchLabCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('Lab Courses')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _coursesFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
            }
            if (!snapshot.hasData || snapshot.data!.containsKey('error')) {
              return Center(child: Text(snapshot.data?['error'] ?? 'Could not fetch lab courses.'));
            }

            final courses = List<Map<String, dynamic>>.from(snapshot.data!['courses']);
            if (courses.isEmpty) {
              return const Center(child: Text('No lab courses found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    leading: const Icon(Icons.biotech_outlined),
                    title: Text(course['name'], style: Theme.of(context).textTheme.titleMedium),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LabDetailsScreen(
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
      ),
    );
  }
}
