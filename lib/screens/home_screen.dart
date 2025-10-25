import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/bio_log_dialog.dart';
import '../widgets/deadlines_dialog.dart';
import 'labs_screen.dart';
import 'subject_attendance_screen.dart';
import 'timetable_screen.dart';
import 'attendance_register_screen.dart';
import 'biometric_analyzer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late ApiService _apiService;
  late Future<Map<String, dynamic>> _timetableFuture;
  late Future<Map<String, dynamic>> _deadlineSummaryFuture;
  late Future<Map<String, dynamic>> _academicInfoFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      _apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!, token: authProvider.token!);
      _timetableFuture = _apiService.fetchTimetable();
      _deadlineSummaryFuture = _apiService.fetchAllDeadlines();
      _academicInfoFuture = _apiService.fetchAcademicInfo();
    } else {
      _timetableFuture = Future.value({'error': 'Not authenticated'});
      _deadlineSummaryFuture = Future.value({'error': 'Not authenticated'});
      _academicInfoFuture = Future.value({'error': 'Not authenticated'});
    }
  }

  String _getRomanNumeral(int number) {
    const roman = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII'};
    return roman[number] ?? number.toString();
  }

  void _showPopupDialog({required Widget child}) {
    showDialog(
      context: context,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFixedHeader(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _deadlineSummaryFuture,
              builder: (context, snapshot) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    const SizedBox(height: 24),
                    _buildAcademicSummaryCard(),
                    const SizedBox(height: 24),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      _buildDeadlinesSkeleton()
                    else
                      _buildNextDeadlines(snapshot),
                    const SizedBox(height: 24),
                    _buildFeatureCard(
                      icon: Icons.science_outlined,
                      title: 'Manage All Lab Records',
                      subtitle: 'View status of all your labs.',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const LabsScreen())),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader() {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => TimetableScreen())),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withAlpha(25),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('EEEE').format(now)}, ${DateFormat('dd MMMM').format(now)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onPrimary.withAlpha(204),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _timetableFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildTimetableSkeleton();
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
                    return const SizedBox.shrink();
                  }
                  final todaySchedule = snapshot.data!['today_schedule'] as List;
                  if (todaySchedule.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text("No classes scheduled for today.")));
                  }
                  return SizedBox(
                    height: 75,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: todaySchedule.length,
                      itemBuilder: (context, index) {
                        final period = todaySchedule[index];
                        final periodNumber = int.tryParse(period['period'].toString().split('-').last.trim()) ?? 0;
                        
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: theme.cardColor.withAlpha(102),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: theme.cardColor.withAlpha(128),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Period ${_getRomanNumeral(periodNumber)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: Text(
                                          period['subject_short'] ?? 'N/A',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicSummaryCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _academicInfoFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        final info = snapshot.data ?? {};
        final classAttendance = (info['class_attendance'] as num?)?.toDouble() ?? -1.0;
        final totalAttended = info['total_attended'] as int?;
        final totalConducted = info['total_conducted'] as int?;
        final bioAttendance = (info['bio_attendance'] as num?)?.toDouble() ?? -1.0;
        final presentDays = info['present_days'] as int?;
        final totalBioDays = info['total_bio_days'] as int?;

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SubjectAttendanceScreen())),
                child: AnimatedSummaryBox(
                  title: 'Attendance',
                  percentage: classAttendance,
                  attended: totalAttended,
                  conducted: totalConducted,
                  isLoading: isLoading,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const BiometricAnalyzerScreen())),
                child: AnimatedSummaryBox(
                  title: 'Biometric',
                  percentage: bioAttendance,
                  attended: presentDays,
                  conducted: totalBioDays,
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAllDeadlines(BuildContext context, List<Map<String, dynamic>> deadlines) {
    showDialog(
      context: context,
      builder: (context) => DeadlinesDialog(deadlines: deadlines),
    );
  }

  Widget _buildNextDeadlines(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    final theme = Theme.of(context);
    if (!snapshot.hasData || snapshot.hasError) {
      return const SizedBox.shrink();
    }
    final allDeadlines = List<Map<String, dynamic>>.from(snapshot.data!['deadlines']);
    final unsubmittedLabs = allDeadlines.where((lab) => lab['submitted'] == false).toList();

    if (unsubmittedLabs.isEmpty) {
      return const SizedBox.shrink();
    }

    unsubmittedLabs.sort((a, b) {
      try {
        final partsA = a['due_date_str'].split('-');
        final dateA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
        final partsB = b['due_date_str'].split('-');
        final dateB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureDeadlines = unsubmittedLabs.where((lab) {
      try {
        final parts = lab['due_date_str'].split('-');
        final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        return !date.isBefore(today); // Show deadlines for today and future dates
      } catch (e) {
        return false;
      }
    }).toList();

    if (futureDeadlines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => _showAllDeadlines(context, futureDeadlines),
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Unsubmitted Deadlines', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      futureDeadlines.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: futureDeadlines.take(2).map((lab) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${lab['course_name']} - ${lab['week']}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Upload by: ${lab['due_date_str']}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(179))),
                        if (futureDeadlines.indexOf(lab) < 1) const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableSkeleton() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: theme.cardColor.withAlpha(102),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.cardColor.withAlpha(128),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: 50,
                  decoration: BoxDecoration(color: theme.colorScheme.onSurface.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 70,
                  decoration: BoxDecoration(color: theme.colorScheme.onSurface.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeadlinesSkeleton() {
    final theme = Theme.of(context);

    Widget buildSkeletonLine({required double width, required double height}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withAlpha(25),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildSkeletonLine(width: 200, height: 24),
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(2, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSkeletonLine(width: MediaQuery.of(context).size.width * (0.6 - index * 0.1), height: 16),
                      const SizedBox(height: 8),
                      buildSkeletonLine(width: MediaQuery.of(context).size.width * (0.4 - index * 0.1), height: 14),
                      if (index < 1) const Divider(),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(204))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withAlpha(179), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedSummaryBox extends StatefulWidget {
  final String title;
  final double percentage;
  final int? attended;
  final int? conducted;
  final bool isLoading;

  const AnimatedSummaryBox({
    super.key,
    required this.title,
    required this.percentage,
    this.attended,
    this.conducted,
    this.isLoading = false,
  });

  @override
  _AnimatedSummaryBoxState createState() => _AnimatedSummaryBoxState();
}

class _AnimatedSummaryBoxState extends State<AnimatedSummaryBox> with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _settleController;
  late Animation<double> _loadingPercentageAnim;
  late Animation<Color?> _loadingColorAnim;
  late Animation<double> _settlePercentageAnim;
  late Animation<Color?> _settleColorAnim;
  bool _isSettling = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _settleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final theme = Theme.of(context);
      _loadingPercentageAnim = Tween<double>(begin: 0, end: 100).animate(
        CurvedAnimation(parent: _loadingController, curve: Curves.easeOut),
      );
      _loadingColorAnim = ColorTween(
        begin: _getPercentageColor(0, theme),
        end: _getPercentageColor(100, theme),
      ).animate(_loadingController);

      if (widget.isLoading) {
        _loadingController.forward(from: 0);
      }
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSummaryBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      final theme = Theme.of(context);
      _loadingController.forward().whenComplete(() {
        if (!mounted) return;
        _settlePercentageAnim = Tween<double>(begin: 100, end: widget.percentage).animate(
          CurvedAnimation(parent: _settleController, curve: Curves.easeOutQuart),
        );
        _settleColorAnim = ColorTween(
          begin: _getPercentageColor(100, theme),
          end: _getPercentageColor(widget.percentage, theme),
        ).animate(_settleController);

        setState(() {
          _isSettling = true;
        });
        _settleController.forward(from: 0);
      });
    }
  }

  Color _getPercentageColor(double percentage, ThemeData theme) {
    final color1 = theme.colorScheme.error;
    final color2 = Colors.orange.shade400;
    final color3 = Colors.green.shade400;

    if (percentage <= 65) return Color.lerp(color1, color2, percentage / 65)!;
    if (percentage <= 75) return Color.lerp(color2, color3, (percentage - 65) / 10)!;
    return color3;
  }
  
  String _getHelperText() {
    final attended = widget.attended;
    final conducted = widget.conducted;
    final isClass = widget.title == 'Attendance';
    final unit = isClass ? 'classes' : 'days';
    const threshold = 75.0;

    if (attended == null || conducted == null || conducted == 0) {
      return 'N/A';
    }

    if (widget.percentage >= threshold) {
      final bunksAllowed = ((100 * attended - threshold * conducted) / threshold).floor();
      return bunksAllowed > 0 ? 'You can miss the next $bunksAllowed $unit' : 'Don\'t miss the next class!';
    } else {
      final classesToAttend = ((threshold * conducted - 100 * attended) / (100 - threshold)).ceil();
      return classesToAttend > 0 ? 'Attend the next $classesToAttend $unit' : 'You are on the threshold.';
    }
  }

  Widget _buildSkeletonText() {
    final theme = Theme.of(context);
    return Container(
      height: theme.textTheme.bodySmall!.fontSize!,
      width: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_loadingController, _settleController]),
                  builder: (context, child) {
                    final isFinished = !widget.isLoading && !_settleController.isAnimating;
                    
                    double displayPercentage;
                    Color displayColor;

                    if (isFinished) {
                      displayPercentage = widget.percentage;
                      displayColor = _getPercentageColor(widget.percentage, theme);
                    } else if (_isSettling) {
                      displayPercentage = _settlePercentageAnim.value;
                      displayColor = _settleColorAnim.value!;
                    } else {
                      displayPercentage = _loadingPercentageAnim.value;
                      displayColor = _loadingColorAnim.value!;
                    }

                    return SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: displayPercentage / 100,
                            strokeWidth: 7,
                            backgroundColor: theme.colorScheme.onSurface.withAlpha(25),
                            valueColor: AlwaysStoppedAnimation(displayColor),
                          ),
                          Center(
                            child: Text(
                              '${displayPercentage.toStringAsFixed(2)}%',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(widget.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                if (widget.isLoading)
                  _buildSkeletonText()
                else
                  Text(
                    _getHelperText(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  )
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _loadingController.dispose();
    _settleController.dispose();
    super.dispose();
  }
}
