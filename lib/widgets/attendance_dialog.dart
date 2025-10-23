import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../screens/subject_attendance_screen.dart';

class AttendanceDialog extends StatefulWidget {
  const AttendanceDialog({super.key});

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  late Future<Map<String, dynamic>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      final apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!, token: authProvider.token!);
      _attendanceFuture = apiService.fetchAttendance();
    } else {
      _attendanceFuture = Future.value({'error': 'Not authenticated'});
    }
  }

  Tuple2<String, Color> _getStatus(double percentage) {
    if (percentage >= 75) return const Tuple2('Satisfactory', Colors.green);
    if (percentage >= 65) return const Tuple2('Condonation', Colors.blue);
    return const Tuple2('Shortage', Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1))
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _attendanceFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
                return _buildErrorState(theme, snapshot.data?['error']?.toString() ?? snapshot.error.toString());
              }

              final courses = List<Map<String, dynamic>>.from(snapshot.data!['courses']);
              final overallPercentage = (snapshot.data!['overall_percentage'] as num).toDouble();
              final totalConducted = courses.fold<int>(0, (sum, item) => sum + (item['conducted'] as int));
              final totalAttended = courses.fold<int>(0, (sum, item) => sum + (item['attended'] as int));

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subject-wise Attendance', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                '$totalAttended / $totalConducted Classes (${overallPercentage.toStringAsFixed(1)}%)',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SubjectAttendanceScreen()));
                          },
                          child: const Text('Analyze'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: courses.isEmpty
                        ? const Center(child: Text('No attendance records found.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: courses.length,
                            separatorBuilder: (context, index) => Divider(height: 1, indent: 24, endIndent: 24, color: theme.dividerColor.withOpacity(0.1)),
                            itemBuilder: (context, index) {
                              final course = courses[index];
                              final percentage = (course['percentage'] as num).toDouble();
                              final status = _getStatus(percentage);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                                dense: true,
                                title: Text(course['name'], style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Text('${course['attended']}/${course['conducted']} classes', style: theme.textTheme.bodyMedium),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(2)}%',
                                      style: TextStyle(color: status.item2, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(status.item1, style: TextStyle(color: status.item2, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  const Tuple2(this.item1, this.item2);
}
