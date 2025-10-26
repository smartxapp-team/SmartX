import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<Map<String, dynamic>>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        final apiService = ApiService(
          apiUrl: authProvider.apiUrl,
          username: authProvider.username!,
          token: authProvider.token!,
        );
        setState(() {
          _dataFuture = Future.wait([apiService.fetchProfile(), apiService.fetchResults()]);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _dataFuture == null) {
            return _buildLoadingSkeleton(theme);
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.any((d) => d.containsKey('error'))) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data}'));
          }

          final profileData = snapshot.data![0];
          final resultsData = snapshot.data![1];

          return Stack(
            children: [
              const ThemedBackground(child: SizedBox.expand()),
              SafeArea(
                child: Column(
                  children: [
                    _buildPremiumProfileHeader(profileData, theme),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildTabs(profileData, resultsData, theme),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Stack(
      children: [
        const ThemedBackground(child: SizedBox.expand()),
        SafeArea(
          child: Shimmer.fromColors(
            baseColor: theme.colorScheme.surface.withOpacity(0.1),
            highlightColor: theme.colorScheme.surface.withOpacity(0.2),
            child: Column(
              children: [
                 Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 120, 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumProfileHeader(Map<String, dynamic> profileData, ThemeData theme) {
    final fullName = (profileData['full_name'] ?? 'N/A').toUpperCase();
    final rollNo = profileData['roll_no'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120,
        borderRadius: 16,
        blur: 10,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.2),
              theme.colorScheme.surface.withOpacity(0.1),
            ],
            stops: const [0.1, 1]),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.5),
            theme.colorScheme.surface.withOpacity(0.5),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profileData['profile_pic_url'] ?? ''),
                onBackgroundImageError: (_, __) {},
                child: (profileData['profile_pic_url'] == null || profileData['profile_pic_url'].isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fullName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rollNo,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(Map<String, dynamic> profileData, Map<String, dynamic> resultsData, ThemeData theme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.surface.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: theme.colorScheme.onPrimary,
                  unselectedLabelColor: theme.colorScheme.onSurface,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Academics'),
                  ],
                ),
              ), 
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.surface.withOpacity(0.3)),
                    ),
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(profileData, theme),
                        _buildAcademicsTab(theme, resultsData),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Map<String, dynamic> profileData, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildDetailItem(theme, Icons.school_outlined, 'Branch', profileData['branch'] ?? 'N/A'),
        _buildDetailItem(theme, Icons.group_outlined, 'Section', profileData['section'] ?? 'N/A'),
        _buildDetailItem(theme, Icons.calendar_today_outlined, 'Year/Sem', profileData['year_sem'] ?? 'N/A'),
        _buildDetailItem(theme, Icons.date_range_outlined, 'Batch', profileData['batch'] ?? 'N/A'),
        _buildDetailItem(theme, Icons.email_outlined, 'Email', profileData['email'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildDetailItem(ThemeData theme, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.8), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGpaColor(double? gpa) {
    if (gpa == null) return Colors.grey;
    if (gpa >= 8.5) return Colors.green;
    if (gpa >= 7.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildAcademicsTab(ThemeData theme, Map<String, dynamic> resultsData) {
    final sgpaList = (resultsData['semesters'] as List? ?? []).map((sem) => sem['sgpa'] as String? ?? 'N/A').toList();
    final cgpaString = resultsData['cgpa']?.toString() ?? 'N/A';
    final double? cgpa = (cgpaString == 'N/A') ? null : double.tryParse(cgpaString);

    final List<FlSpot> spots = [];
    for (var i = 0; i < sgpaList.length; i++) {
      final sgpa = double.tryParse(sgpaList[i]);
      if (sgpa != null && sgpa > 0) {
        spots.add(FlSpot(i.toDouble() + 1, sgpa));
      }
    }

    final bool dataExists = spots.isNotEmpty;

    final lineBarData = LineChartBarData(
        spots: spots,
        isCurved: true,
        gradient: const LinearGradient(
          colors: [Color(0xFF23B6E6), Color(0xFF02D39A)],
        ),
        barWidth: 5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 8, color: Colors.white, strokeWidth: 3, strokeColor: const Color(0xFF02D39A)),
        ),
        belowBarData: BarAreaData(show: false),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildCgpaIndicator(theme, cgpa),
          const SizedBox(height: 32),
          Text('SGPA History', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: dataExists
                ? LineChart(
                    LineChartData(
                      minX: 1,
                      maxX: spots.length.toDouble(),
                      minY: 6.5,
                      maxY: 10,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(color: theme.colorScheme.surface.withOpacity(0.1), strokeWidth: 1),
                        getDrawingVerticalLine: (value) => FlLine(color: theme.colorScheme.surface.withOpacity(0.1), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 0.5,
                            getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() > spots.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('S${value.toInt()}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [lineBarData],
                      showingTooltipIndicators: spots.map((spot) {
                        return ShowingTooltipIndicators([
                          LineBarSpot(lineBarData, 0, spot),
                        ]);
                      }).toList(),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              return LineTooltipItem(
                                barSpot.y.toStringAsFixed(2),
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'Academic results are not available yet.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCgpaIndicator(ThemeData theme, double? cgpa) {
    final color = _getGpaColor(cgpa);
    return SizedBox(
      height: 150,
      width: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: (cgpa ?? 0.0) / 10.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) => CircularProgressIndicator(
              value: value,
              strokeWidth: 12,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cgpa?.toStringAsFixed(2) ?? 'N/A',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
                Text('CGPA', style: theme.textTheme.bodyMedium)
              ],
            ),
          )
        ],
      ),
    );
  }
}
