import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';
import 'leave_planner_screen.dart';

class AttendanceStatus {
  final String text;
  final Color color;
  AttendanceStatus(this.text, this.color);
}

class SubjectAttendanceScreen extends StatefulWidget {
  const SubjectAttendanceScreen({super.key});

  @override
  State<SubjectAttendanceScreen> createState() =>
      _SubjectAttendanceScreenState();
}

class _SubjectAttendanceScreenState extends State<SubjectAttendanceScreen> {
  Future<Map<String, dynamic>>? _attendanceFuture;
  bool _isBunkMode = false;
  bool _isLeaveMode = false;
  double _threshold = 75.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      final apiService = ApiService(
        apiUrl: authProvider.apiUrl,
        username: authProvider.username!,
        token: authProvider.token!,
      );
      setState(() {
        _attendanceFuture = apiService.fetchAttendance();
      });
    } else {
      setState(() {
        _attendanceFuture = Future.value({'error': 'Not authenticated'});
      });
    }
  }

  AttendanceStatus _getAttendanceStatus(double percentage) {
    if (percentage >= 75) {
      return AttendanceStatus('Satisfactory', const Color(0xFF4CAF50)); // Green
    } else if (percentage >= 65) {
      return AttendanceStatus('Condonation', const Color(0xFF2196F3)); // Blue
    } else {
      return AttendanceStatus('Shortage', const Color(0xFFF44336)); // Red
    }
  }

  String _calculateBunkMessage(int attended, int conducted, {bool isOverall = false}) {
    if (_threshold == 100) {
      return isOverall
          ? 'Aiming for 100%? Someone\'s a teacher\'s pet! 🧑‍🏫'
          : 'Perfection! ✨';
    }

    double currentPercentage = conducted > 0 ? (attended / conducted * 100) : 0;

    if (currentPercentage >= _threshold) {
      final bunksAllowed = ((100 * attended - _threshold * conducted) / _threshold).floor();
      if (isOverall) return 'You can miss the next $bunksAllowed classes overall.';
      return bunksAllowed > 0 ? 'You can miss the next $bunksAllowed classes. ✅' : 'Don\'t miss the next class! ⚠️';
    } else {
      final classesToAttend = ((_threshold * conducted - 100 * attended) / (100 - _threshold)).ceil();
      if (isOverall) return 'You must attend the next $classesToAttend classes to reach the threshold.';
      return classesToAttend > 0 ? 'Attend the next $classesToAttend classes. 📚' : 'You are on the threshold. ⚠️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        const ThemedBackground(child: SizedBox.expand()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Subject Attendance Analyzer'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _attendanceFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
                  return _buildErrorWidget(snapshot.data?['error']?.toString() ?? snapshot.error.toString());
                }

                final courses = List<Map<String, dynamic>>.from(snapshot.data!['courses']);
                final overallPercentage = (snapshot.data!['overall_percentage'] as num).toDouble();
                final totalAttended = courses.fold<int>(0, (prev, course) => prev + (course['attended'] as int));
                final totalConducted = courses.fold<int>(0, (prev, course) => prev + (course['conducted'] as int));

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _isBunkMode,
                                  onChanged: (val) => setState(() {
                                    _isBunkMode = val!;
                                    if (val) _isLeaveMode = false;
                                  }),
                                ),
                                const Text('Bunk Calculator'),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => const LeavePlannerScreen()),
                                );
                              },
                              icon: const Text('Leave Planner'),
                              label: const Icon(Icons.arrow_forward, size: 16.0),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildOverallHeader(overallPercentage, totalAttended, totalConducted, theme),
                    ),
                    if (_isLeaveMode)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Single Day button pressed')),
                                  );
                                },
                                child: const Text('Single Day'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Long Leave button pressed')),
                                  );
                                },
                                child: const Text('Long Leave'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = courses[index];
                          return _buildCourseItem(theme, course);
                        },
                        childCount: courses.length,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _fetchAttendance,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, {required String emoji, required String title, required String value, required Color color}) {
    return Card(
      color: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallHeader(double percentage, int attended, int conducted, ThemeData theme) {
    final status = _getAttendanceStatus(percentage);
    final absent = conducted - attended;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_isBunkMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          setState(() {
                            _threshold = (_threshold - 1).clamp(50.0, 100.0);
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Set Attendance Threshold: ${_threshold.toInt()}%',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          setState(() {
                            _threshold = (_threshold + 1).clamp(50.0, 100.0);
                          });
                        },
                      ),
                    ],
                  ),
                  Slider(
                    value: _threshold,
                    min: 50,
                    max: 100,
                    divisions: 50,
                    label: '${_threshold.toInt()}%',
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.colorScheme.primary.withOpacity(0.3),
                    onChanged: (value) {
                      setState(() {
                        _threshold = value.roundToDouble();
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 10,
                            backgroundColor: status.color.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(status.color),
                          ),
                          Center(
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Overall Attendance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoCard(theme, emoji: '📚', title: 'Total', value: conducted.toString(), color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    _buildInfoCard(theme, emoji: '✅', title: 'Present', value: attended.toString(), color: Colors.green.shade400),
                    const SizedBox(height: 8),
                    _buildInfoCard(theme, emoji: '❌', title: 'Absent', value: absent.toString(), color: Colors.red.shade400),
                  ],
                ),
              ),
            ],
          ),
          if (_isBunkMode)
            Padding(
              padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
              child: Text(
                _calculateBunkMessage(attended, conducted, isOverall: true),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(ThemeData theme, Map<String, dynamic> course) {
    final percentage = (course['percentage'] as num).toDouble();
    final attended = course['attended'] as int;
    final conducted = course['conducted'] as int;
    final missed = conducted - attended;
    final status = _getAttendanceStatus(percentage);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The color mask on the right
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 1.0, // Adjust the width of the mask
                heightFactor: 1.0, // <-- FIX: Ensure it fills the height
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        status.color.withOpacity(0.05),
                        status.color.withOpacity(0.2),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Subject Name and Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        course['name'],
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: status.color,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Bottom Row: Attended, Conducted, Missed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountColumn(theme, count: attended, label: 'Attended'),
                    _buildCountColumn(theme, count: conducted, label: 'Conducted'),
                    _buildCountColumn(theme, count: missed, label: 'Missed'),
                  ],
                ),
                if (_isBunkMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: status.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _calculateBunkMessage(attended, conducted),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountColumn(ThemeData theme, {required int count, required String label}) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }
}
