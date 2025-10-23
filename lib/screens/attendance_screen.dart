import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Future<Map<String, dynamic>>? _attendanceFuture;
  double _overallPercentage = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    )..addListener(() {
        setState(() {});
      });
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      final apiService = ApiService(
          apiUrl: authProvider.apiUrl, username: authProvider.username!, token: authProvider.token!);
      _attendanceFuture = apiService.fetchAttendance();
      await _controller.animateTo(1.0);
      try {
        final data = await _attendanceFuture;
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (data != null && data.containsKey('overall_percentage')) {
              _overallPercentage =
                  (data['overall_percentage'] as num).toDouble();
              _controller.duration = const Duration(milliseconds: 800);
              _animation = Tween<double>(begin: 1, end: _overallPercentage / 100)
                  .animate(
                CurvedAnimation(
                    parent: _controller, curve: Curves.easeOutQuad),
              );
              _controller.forward(from: 0);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getPercentageColor(double percentage, ThemeData theme) {
    if (percentage >= 75) return Colors.green.shade400;
    if (percentage >= 65) return Colors.orange.shade400;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animatedPercentage = _animation.value * 100;
    return FutureBuilder<Map<String, dynamic>>(
      future: _attendanceFuture,
      builder: (ctx, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
        }
        if (snapshot.hasData && snapshot.data!.containsKey('error')) {
          return Center(
              child: Text(snapshot.data?['error'] ?? 'Could not fetch attendance data.'));
        }
        final courses = _isLoading || !snapshot.hasData
            ? []
            : List<Map<String, dynamic>>.from(snapshot.data!['courses']);
        if (!_isLoading && courses.isEmpty) {
          return const Center(child: Text('No attendance records found.'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
          children: [
            _buildOverallProgress(theme, animatedPercentage),
            const SizedBox(height: 24),
            Text(
              "Course-wise Attendance",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              _buildShimmerList()
            else
              ...courses.map((course) => _buildCourseItem(course, theme)),
          ],
        );
      },
    );
  }

  Widget _buildOverallProgress(ThemeData theme, double percentage) {
    final displayPercentage = _isLoading ? (percentage).clamp(0, 100) : _overallPercentage;
    final color = _getPercentageColor(displayPercentage.toDouble(), theme);

    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 8,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${displayPercentage.toInt()}%',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Overall Attendance",
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _isLoading
              ? "Calculating..."
              : "You are doing great, keep it up!",
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course, ThemeData theme) {
    final percentage = (course['percentage'] as num).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 6,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getPercentageColor(percentage, theme)),
                  ),
                  Center(
                    child: Text(
                      '${percentage.toInt()}%',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['name'],
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Conducted: ${course['conducted']}  |  Attended: ${course['attended']}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(5, (_) => _buildShimmerItem()),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
