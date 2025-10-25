import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';

class AttendanceStatus {
  final String text;
  final Color color;
  AttendanceStatus(this.text, this.color);
}

class BiometricAnalyzerScreen extends StatefulWidget {
  const BiometricAnalyzerScreen({super.key});

  @override
  State<BiometricAnalyzerScreen> createState() =>
      _BiometricAnalyzerScreenState();
}

class _BiometricAnalyzerScreenState extends State<BiometricAnalyzerScreen> {
  Future<Map<String, dynamic>>? _biometricFuture;
  bool _isBunkMode = false;
  double _threshold = 75.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchBiometricData();
  }

  Future<void> _fetchBiometricData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      final apiService = ApiService(
        apiUrl: authProvider.apiUrl,
        username: authProvider.username!,
        token: authProvider.token!,
      );
      setState(() {
        _biometricFuture = apiService.fetchBioData();
      });
    } else {
      setState(() {
        _biometricFuture = Future.value({'error': 'Not authenticated'});
      });
    }
  }

  AttendanceStatus _getAttendanceStatus(double percentage) {
    if (percentage >= 75) {
      return AttendanceStatus('Satisfactory', Colors.green.shade400);
    } else if (percentage >= 65) {
      return AttendanceStatus('Condonation', Colors.blue.shade400);
    } else {
      return AttendanceStatus('Shortage', Colors.red.shade400);
    }
  }

  String _calculateBunkMessage(int present, int total) {
    if (_threshold == 100) {
      return 'Perfection! ✨';
    }

    double currentPercentage = total > 0 ? (present / total * 100) : 0;

    if (currentPercentage >= _threshold) {
      final bunksAllowed = ((100 * present - _threshold * total) / _threshold).floor();
      return bunksAllowed > 0 ? 'You can miss the next $bunksAllowed days. ✅' : 'Don\'t miss the next day! ⚠️';
    } else {
      final daysToAttend = ((_threshold * total - 100 * present) / (100 - _threshold)).ceil();
      return daysToAttend > 0 ? 'Attend the next $daysToAttend days. 📚' : 'You are on the threshold. ⚠️';
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
            title: const Text('Biometric Analyzer'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _biometricFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
                  return _buildErrorWidget(snapshot.data?['error']?.toString() ?? snapshot.error.toString());
                }

                final bioLog = List<Map<String, dynamic>>.from(snapshot.data!['bio_log']);
                final presentDays = bioLog.where((log) => (log['status'] as String? ?? '').trim().toLowerCase().startsWith('p')).length;
                final totalDays = bioLog.length;
                final overallPercentage = totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _isBunkMode,
                                  onChanged: (val) => setState(() {
                                    _isBunkMode = val!;
                                  }),
                                ),
                                const Text('Bunk Calculator'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildOverallHeader(overallPercentage, presentDays, totalDays, theme),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final log = bioLog[index];
                          return _buildLogItem(theme, log, index + 1);
                        },
                        childCount: bioLog.length,
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
            onPressed: _fetchBiometricData,
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

  Widget _buildOverallHeader(double percentage, int present, int total, ThemeData theme) {
    final status = _getAttendanceStatus(percentage);
    final absent = total - present;

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
                    _buildInfoCard(theme, emoji: '📅', title: 'Total Days', value: total.toString(), color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    _buildInfoCard(theme, emoji: '✅', title: 'Present', value: present.toString(), color: Colors.green.shade400),
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
                _calculateBunkMessage(present, total),
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

  Widget _buildLogItem(ThemeData theme, Map<String, dynamic> log, int sno) {
    final statusText = (log['status'] as String? ?? '').trim().toLowerCase().startsWith('p') ? 'Present' : 'Absent';
    final color = statusText == 'Present' ? Colors.green.shade400 : Colors.red.shade400;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor.withOpacity(0.5),
      ),
      child: Row(
        children: [
          Text('$sno.', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Text(log['date'], style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(statusText, style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
