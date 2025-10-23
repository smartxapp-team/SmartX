import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';

enum LeaveType { none, single, long }

class LeavePlannerScreen extends StatefulWidget {
  const LeavePlannerScreen({super.key});

  @override
  State<LeavePlannerScreen> createState() => _LeavePlannerScreenState();
}

class _LeavePlannerScreenState extends State<LeavePlannerScreen> {
  Future<Map<String, dynamic>>? _leavePlannerFuture;
  LeaveType _leaveType = LeaveType.none;
  DateTime? _selectedSingleDate;
  final List<DateTime> _selectedLongLeaveDates = [];
  Map<String, dynamic>? _analysisData;
  bool _isLoading = false;

  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_leavePlannerFuture == null) {
      _fetchLeavePlannerData();
    }
  }

  Future<void> _fetchLeavePlannerData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      final apiService = ApiService(
        apiUrl: authProvider.apiUrl,
        username: authProvider.username!,
        token: authProvider.token!,
      );
      if (mounted) {
        setState(() {
          _leavePlannerFuture = apiService.fetchLeavePlannerData();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _leavePlannerFuture = Future.value({'error': 'Not authenticated'});
        });
      }
    }
  }

  void _handleDateSelection(DateTime date) {
    setState(() {
      _analysisData = null;
      if (_leaveType == LeaveType.single) {
        _selectedSingleDate = (_selectedSingleDate == date) ? null : date;
      } else if (_leaveType == LeaveType.long) {
        if (_selectedLongLeaveDates.contains(date)) {
          _selectedLongLeaveDates.remove(date);
        } else {
          _selectedLongLeaveDates.add(date);
        }
        _selectedLongLeaveDates.sort();
      }
    });
  }

  void _analyzeLeave() async {
    setState(() { _isLoading = true; _analysisData = null; });

    final plannerData = await _leavePlannerFuture;
    if (plannerData == null || plannerData.containsKey('error')) {
      setState(() {
        _analysisData = {'error': 'Failed to retrieve planner data.'};
        _isLoading = false;
      });
      return;
    }

    final originalSubjects = json.decode(json.encode(plannerData['subjects'])) as Map<String, dynamic>? ?? {};
    final originalBioLog = List<Map<String, dynamic>>.from(json.decode(json.encode(plannerData['bio_log'] ?? [])));
    final timetable = plannerData['timetable'] as Map<String, dynamic>? ?? {};

    if (originalSubjects.isEmpty || timetable.isEmpty) {
      setState(() {
        _analysisData = {'error': "Timetable or Subject data is missing."};
        _isLoading = false;
      });
      return;
    }

    List<DateTime> leaveDates = [];
    if (_leaveType == LeaveType.single && _selectedSingleDate != null) {
      leaveDates.add(_selectedSingleDate!);
    } else if (_leaveType == LeaveType.long) {
      leaveDates.addAll(_selectedLongLeaveDates);
    }

    if (leaveDates.isEmpty) {
      setState(() { _isLoading = false; });
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var beforeLeaveSubjects = json.decode(json.encode(originalSubjects));
    var beforeLeaveBioLog = List<Map<String, dynamic>>.from(originalBioLog);

    final firstLeaveDate = leaveDates.first;
    for (var date = today; date.isBefore(firstLeaveDate); date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.sunday) continue;

      beforeLeaveBioLog.add({'status': 'Present'});
      final dayOfWeek = DateFormat('EEEE').format(date);
      final classesToday = timetable[dayOfWeek] as List<dynamic>? ?? [];
      for (final classInfo in classesToday) {
        final subjectName = classInfo['subject_full'];
        if (beforeLeaveSubjects.containsKey(subjectName)) {
          beforeLeaveSubjects[subjectName]['attended'] = (beforeLeaveSubjects[subjectName]['attended'] ?? 0) + 1;
          beforeLeaveSubjects[subjectName]['conducted'] = (beforeLeaveSubjects[subjectName]['conducted'] ?? 0) + 1;
        }
      }
    }

    double beforeBioPercentage = _calculateBioPercentage(beforeLeaveBioLog);
    double beforeClassPercentage = _calculateOverallAttendance(beforeLeaveSubjects);

    var afterLeaveSubjects = json.decode(json.encode(beforeLeaveSubjects));
    var afterLeaveBioLog = List<Map<String, dynamic>>.from(beforeLeaveBioLog);

    for (final leaveDate in leaveDates) {
      afterLeaveBioLog.add({'status': 'Absent'});
      final dayOfWeekOfLeave = DateFormat('EEEE').format(leaveDate);
      final classesOnLeaveDay = timetable[dayOfWeekOfLeave] as List<dynamic>? ?? [];
      for (final classInfo in classesOnLeaveDay) {
        final subjectName = classInfo['subject_full'];
        if (afterLeaveSubjects.containsKey(subjectName)) {
          afterLeaveSubjects[subjectName]['conducted'] = (afterLeaveSubjects[subjectName]['conducted'] ?? 0) + 1;
        }
      }
    }

    double afterBioPercentage = _calculateBioPercentage(afterLeaveBioLog);
    double afterClassPercentage = _calculateOverallAttendance(afterLeaveSubjects);

    List<Map<String, dynamic>> subjectImpactList = [];
    final allLeaveDayClasses = leaveDates.expand((d) {
      final dayOfWeek = DateFormat('EEEE').format(d);
      return timetable[dayOfWeek] as List<dynamic>? ?? [];
    }).map((c) => c['subject_full'] as String).toSet();

    for (final name in originalSubjects.keys) {
      if (allLeaveDayClasses.contains(name)) {
        final beforeData = beforeLeaveSubjects[name];
        final afterData = afterLeaveSubjects[name];
        final initialAtt = (beforeData['attended'] ?? 0) / (beforeData['conducted'] ?? 1) * 100;
        final projectedAtt = (afterData['attended'] ?? 0) / (afterData['conducted'] ?? 1) * 100;

        subjectImpactList.add({
          'name': name,
          'initial': initialAtt,
          'projected': projectedAtt,
        });
      }
    }

    setState(() {
      _analysisData = {
        'type': 'analysis',
        'initialBio': beforeBioPercentage,
        'projectedBio': afterBioPercentage,
        'initialClass': beforeClassPercentage,
        'projectedClass': afterClassPercentage,
        'subjects': subjectImpactList,
      };
      _isLoading = false;
    });
  }

  void _suggestSafeLeave() async {
    setState(() { _isLoading = true; _analysisData = null; });

    final plannerData = await _leavePlannerFuture;
    if (plannerData == null || plannerData.containsKey('error')) {
      setState(() {
        _analysisData = {'error': 'Failed to retrieve planner data.'};
        _isLoading = false;
      });
      return;
    }

    final originalSubjects = json.decode(json.encode(plannerData['subjects'])) as Map<String, dynamic>? ?? {};
    final timetable = plannerData['timetable'] as Map<String, dynamic>? ?? {};

    if (originalSubjects.isEmpty || timetable.isEmpty) {
      setState(() {
        _analysisData = {'error': "Timetable or Subject data is missing."};
        _isLoading = false;
      });
      return;
    }
    
    final today = DateTime.now();
    final currentOverallAttendance = _calculateOverallAttendance(originalSubjects);

    List<Map<String, dynamic>> impactDetails = [];

    final lastSemDateString = plannerData['last_sem_date'] as String?;
    DateTime lastDay = today.add(const Duration(days: 30));
    if (lastSemDateString != null && lastSemDateString != 'N/A') {
      try {
        lastDay = DateFormat('dd-MM-yyyy').parse(lastSemDateString);
      } catch (_) {}
    }

    for (var i = 1; i < 30; i++) {
      final date = today.add(Duration(days: i));
      if(date.isAfter(lastDay)) break;
      if (date.weekday == DateTime.sunday) continue;

      var tempSubjects = json.decode(json.encode(originalSubjects));
      final dayOfWeek = DateFormat('EEEE').format(date);
      final classesOnDate = timetable[dayOfWeek] as List<dynamic>? ?? [];
      
      if (classesOnDate.isEmpty) {
        impactDetails.add({'date': date, 'impact': 0.0});
        continue;
      }

      for (var classInfo in classesOnDate) {
        final subjectName = classInfo['subject_full'];
        if (tempSubjects.containsKey(subjectName)) {
          tempSubjects[subjectName]['conducted'] = (tempSubjects[subjectName]['conducted'] ?? 0) + 1;
        }
      }
      final projectedAttendance = _calculateOverallAttendance(tempSubjects);
      final impact = currentOverallAttendance - projectedAttendance;
      impactDetails.add({'date': date, 'impact': impact > 0 ? impact : 0.0 });
    }

    if (impactDetails.isEmpty) {
       setState(() {
        _analysisData = {
          'type': 'suggestion',
          'reason': 'No suitable leave day found in the next 30 days.',
          'impacts': [],
        };
        _isLoading = false;
      });
      return;
    }

    impactDetails.sort((a, b) => a['impact'].compareTo(b['impact']));

    setState(() {
      _analysisData = {
        'type': 'suggestion',
        'reason': 'The following days have the lowest impact on your overall attendance.',
        'impacts': impactDetails,
      };
      _isLoading = false;
    });
  }


  double _calculateBioPercentage(List<Map<String, dynamic>> bioLog) {
    if (bioLog.isEmpty) return 0.0;
    final presentDays = bioLog.where((log) => (log['status'] as String? ?? '').toLowerCase().startsWith('p')).length;
    return (presentDays / bioLog.length) * 100;
  }

  double _calculateOverallAttendance(Map<String, dynamic> subjects) {
    if (subjects.isEmpty) return 0.0;
    double totalAttended = 0;
    double totalConducted = 0;
    for (var data in subjects.values) {
      totalAttended += (data['attended'] ?? 0);
      totalConducted += (data['conducted'] ?? 0);
    }
    return totalConducted == 0 ? 100.0 : (totalAttended / totalConducted) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Leave Planner'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _leavePlannerFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
              return Center(child: Text('Could not load planner data.', style: theme.textTheme.titleMedium));
            }

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            DateTime firstSelectableDate = (now.hour > 12 || (now.hour == 12 && now.minute >= 30))
                ? today.add(const Duration(days: 1))
                : today;

            final lastDayString = snapshot.data!['last_sem_date'] as String?;
            DateTime lastSelectableDate = DateTime(now.year + 1);
            if (lastDayString != null && lastDayString != 'N/A') {
              try {
                lastSelectableDate = DateFormat('dd-MM-yyyy').parse(lastDayString);
              } catch (_) {}
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Single Leave'),
                        selected: _leaveType == LeaveType.single,
                        selectedColor: theme.primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            _leaveType = selected ? LeaveType.single : LeaveType.none;
                            _selectedLongLeaveDates.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Long Leave'),
                        selected: _leaveType == LeaveType.long,
                        selectedColor: theme.primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            _leaveType = selected ? LeaveType.long : LeaveType.none;
                            _selectedSingleDate = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendarView(theme, firstSelectableDate, lastSelectableDate),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_selectedSingleDate != null || _selectedLongLeaveDates.isNotEmpty) && !_isLoading
                          ? _analyzeLeave
                          : null,
                      child: const Text('Analyze Leave Impact'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: theme.primaryColor),
                      ),
                      onPressed: !_isLoading ? _suggestSafeLeave : null,
                      child: const Text('Suggest a Safe Leave'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_analysisData != null)
                    _buildAnalysisResultWidget(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalysisResultWidget() {
    final theme = Theme.of(context);
    if (_analysisData!.containsKey('error')) {
      return _buildErrorCard(theme, _analysisData!['error']);
    }

    if (_analysisData!['type'] == 'suggestion') {
      final impacts = _analysisData!['impacts'] as List<dynamic>;
      if (impacts.isEmpty) {
        return _buildErrorCard(theme, _analysisData!['reason'] ?? 'No suitable leave day found.');
      }
      return _buildSuggestionCard(theme, impacts, _analysisData!['reason']);
    }

    return _buildAnalysisCard(theme);
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Card(
      color: theme.colorScheme.errorContainer.withAlpha(100),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(error, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(ThemeData theme, List<dynamic> impacts, String reason) {
  final bestDay = impacts.first;
  final otherDays = impacts.skip(1).take(3); // Show the next 3 best options

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safe Leave Suggestions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // Best day display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.MMMEd().format(bestDay['date']), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      Text(bestDay['impact'] == 0.0 ? 'No classes this day' : 'Overall attendance drops by ${bestDay['impact'].toStringAsFixed(2)}%', style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                 Icon(Icons.check_circle, color: Colors.green.shade400, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Other Options', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Other options
          ...otherDays.map((day) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat.MMMEd().format(day['date']), style: theme.textTheme.bodyLarge),
                Text('${day['impact'].toStringAsFixed(2)}% drop', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)),
              ],
            ),
          ))
        ],
      ),
    ),
  );
}

  Widget _buildAnalysisCard(ThemeData theme) {
    final subjects = _analysisData!['subjects'] as List<Map<String, dynamic>>;
    return Column(
      children: [
        _buildImpactCard(theme,
          title: 'Biometric',
          icon: Icons.fingerprint,
          initial: _analysisData!['initialBio'],
          projected: _analysisData!['projectedBio'],
        ),
        const SizedBox(height: 16),
        _buildImpactCard(theme,
          title: 'Class Average',
          icon: Icons.school_outlined,
          initial: _analysisData!['initialClass'],
          projected: _analysisData!['projectedClass'],
        ),
        if (subjects.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          ...subjects.map((s) => _buildImpactCard(theme,
            title: s['name'],
            icon: Icons.class_outlined,
            initial: s['initial'],
            projected: s['projected'],
          )),
        ]
      ],
    );
  }

  Widget _buildImpactCard(ThemeData theme, {required String title, required IconData icon, required double initial, required double projected}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPercentageItem(theme, 'Before', initial, Colors.grey.shade400),
                const Icon(Icons.arrow_forward_rounded, size: 24, color: Colors.grey),
                _buildPercentageItem(theme, 'After', projected, projected < 75 ? theme.colorScheme.error : Colors.green.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageItem(ThemeData theme, String label, double value, Color color) {
    return Column(
      children: [
        Text('${value.toStringAsFixed(2)}%', style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400)),
      ],
    );
  }


  Widget _buildCalendarView(ThemeData theme, DateTime firstDate, DateTime lastDate) {
    bool isEnabled = _leaveType != LeaveType.none;
    return Material(
      color: theme.cardColor.withAlpha(isEnabled ? 178 : 51),
      borderRadius: BorderRadius.circular(16),
      child: AbsorbPointer(
        absorbing: !isEnabled,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildCalendarHeader(theme, firstDate, lastDate),
              const SizedBox(height: 8),
              _buildCalendarGrid(theme, firstDate, lastDate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(ThemeData theme, DateTime firstDate, DateTime lastDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (_displayedMonth.year == firstDate.year && _displayedMonth.month == firstDate.month) return;
            setState(() {
              _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
            });
          },
        ),
        Text(
          DateFormat.yMMMM().format(_displayedMonth),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            if (_displayedMonth.year == lastDate.year && _displayedMonth.month == lastDate.month) return;
            setState(() {
              _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, DateTime firstDate, DateTime lastDate) {
    final daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final weekDayOfFirstDay = firstDayOfMonth.weekday % 7;

    final List<Widget> dayWidgets = [];
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (int i = 0; i < dayLabels.length; i++) {
      dayWidgets.add(Center(
        child: Text(
          dayLabels[i],
          style: theme.textTheme.bodySmall?.copyWith(
            color: i == 0 ? Colors.red.shade300 : theme.textTheme.bodySmall?.color?.withAlpha(153),
          ),
        ),
      ));
    }

    for (int i = 0; i < weekDayOfFirstDay; i++) {
      dayWidgets.add(Container());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, i);
      final bool isSunday = date.weekday == DateTime.sunday;
      final bool isPast = date.isBefore(firstDate);
      final bool isSelectable = !isSunday && !isPast && !date.isAfter(lastDate);

      bool isSelected = false;
      if (isSelectable) {
        if (_leaveType == LeaveType.single) {
          isSelected = _selectedSingleDate != null && DateUtils.isSameDay(date, _selectedSingleDate);
        } else if (_leaveType == LeaveType.long) {
          isSelected = _selectedLongLeaveDates.any((d) => DateUtils.isSameDay(date, d));
        }
      }

      Color dayColor;
      if (isSunday) {
        dayColor = Colors.red.shade300;
      } else if (isPast) {
        dayColor = Colors.grey.shade700;
      } else if (isSelected) {
        dayColor = Colors.white;
      } else {
        dayColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
      }

      dayWidgets.add(
        GestureDetector(
          onTap: isSelectable ? () => _handleDateSelection(date) : null,
          child: Container(
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle)
                : null,
            child: Text(i.toString(), style: TextStyle(color: dayColor)),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
}
