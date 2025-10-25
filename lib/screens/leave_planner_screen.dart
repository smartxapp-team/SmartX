import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';

enum LeaveType { none, single, long, choice }

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
  final Map<DateTime, int> _choiceDates = {};
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
      } else if (_leaveType == LeaveType.choice) {
        _handleChoiceDateSelection(date);
      }
    });
  }

  void _handleChoiceDateSelection(DateTime date) {
    setState(() {
      if (_choiceDates.containsKey(date)) {
        if (_choiceDates[date] == 1) {
          _choiceDates[date] = 2; // Double click -> Absent (red)
        } else {
          _choiceDates.remove(date); // Triple click -> Deselect
        }
      } else {
        _choiceDates[date] = 1; // Single click -> Present (green)
      }
    });
  }

  void _analyzeLeave() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime firstSelectableDate = (now.hour >= 13) ? today.add(const Duration(days: 1)) : today;

    if (_leaveType == LeaveType.choice) {
      final dates = _choiceDates.keys.toList();
      if (dates.isNotEmpty) {
        dates.sort();
        final lastSelected = dates.last;
        for (var d = firstSelectableDate; d.isBefore(lastSelected); d = d.add(const Duration(days: 1))) {
          if (d.weekday != DateTime.sunday && !_choiceDates.containsKey(d)) {
            _showGapErrorPopup();
            return;
          }
        }
      }
    }

    setState(() { _isLoading = true; _analysisData = null; });
    try {
      final plannerData = await _leavePlannerFuture;
      if (plannerData == null || plannerData.containsKey('error')) {
        if (mounted) setState(() { _analysisData = {'error': 'Failed to retrieve planner data.'}; });
        return;
      }

      final originalSubjects = json.decode(json.encode(plannerData['subjects'])) as Map<String, dynamic>? ?? {};
      final originalBioLog = List<Map<String, dynamic>>.from(json.decode(json.encode(plannerData['bio_log'] ?? [])));
      final timetable = plannerData['timetable'] as Map<String, dynamic>? ?? {};

      if (originalSubjects.isEmpty || timetable.isEmpty) {
        if (mounted) setState(() { _analysisData = {'error': "Timetable or Subject data is missing."}; });
        return;
      }

      final double initialBioPercentage = _calculateBioPercentage(originalBioLog);
      final double initialClassPercentage = _calculateOverallAttendance(originalSubjects);
      final Map<String, double> initialSubjectPercentages = Map.from(originalSubjects).map((key, value) {
        return MapEntry(key, (value['conducted'] > 0) ? (value['attended'] / value['conducted'] * 100) : 100.0);
      });

      var simulatedSubjects = json.decode(json.encode(originalSubjects));
      var simulatedBioLog = List<Map<String, dynamic>>.from(originalBioLog);

      List<Map<String, dynamic>> dailyBreakdown = [];
      DateTime? lastDateForAnalysis;
      DateTime? firstDateForAnalysis;

      if (_leaveType == LeaveType.choice) {
        final choiceDatesSorted = _choiceDates.keys.toList()..sort();
        if (choiceDatesSorted.isEmpty) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        firstDateForAnalysis = firstSelectableDate;
        lastDateForAnalysis = choiceDatesSorted.last;
      } else {
        List<DateTime> leaveDates = [];
        if (_leaveType == LeaveType.single && _selectedSingleDate != null) {
          leaveDates.add(_selectedSingleDate!);
        } else if (_leaveType == LeaveType.long) {
          leaveDates.addAll(_selectedLongLeaveDates);
        }

        if (leaveDates.isEmpty) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        leaveDates.sort();
        firstDateForAnalysis = today;
        lastDateForAnalysis = leaveDates.last;
      }
      
      for (var date = firstDateForAnalysis; !date.isAfter(lastDateForAnalysis); date = date.add(const Duration(days: 1))) {
        if (date.weekday == DateTime.sunday) continue;
        
        bool isLeaveDay = false;
        String status = 'Present';

        if (_leaveType == LeaveType.choice) {
          if (_choiceDates.containsKey(date)) {
            isLeaveDay = _choiceDates[date] == 2;
            status = isLeaveDay ? 'Absent' : 'Present';
          } else {
            // This case should be prevented by the validation logic, but as a fallback
            continue;
          }
        } else {
           List<DateTime> leaveDates = [];
           if (_leaveType == LeaveType.single && _selectedSingleDate != null) {
             leaveDates.add(_selectedSingleDate!);
           } else if (_leaveType == LeaveType.long) {
             leaveDates.addAll(_selectedLongLeaveDates);
           }
          isLeaveDay = leaveDates.any((d) => DateUtils.isSameDay(d, date)) || date.isAfter(today);
          status = isLeaveDay ? 'Absent' : 'Present';
        }
        
        simulatedBioLog.add({'status': status});

        final dayOfWeek = DateFormat('EEEE').format(date);
        final classesToday = timetable[dayOfWeek] as List<dynamic>? ?? [];
        final Map<String, double> subjectsForBreakdown = {};

        for (final classInfo in classesToday) {
          final subjectName = classInfo['subject_full'];
          if (simulatedSubjects.containsKey(subjectName)) {
            simulatedSubjects[subjectName]['conducted'] = (simulatedSubjects[subjectName]['conducted'] ?? 0) + 1;
            if (!isLeaveDay) {
              simulatedSubjects[subjectName]['attended'] = (simulatedSubjects[subjectName]['attended'] ?? 0) + 1;
            }
            final value = simulatedSubjects[subjectName];
            subjectsForBreakdown[subjectName] = (value['conducted'] > 0) ? (value['attended'] / value['conducted'] * 100) : 100.0;
          }
        }

        dailyBreakdown.add({
          'date': date,
          'status': status,
          'bio_percent': _calculateBioPercentage(simulatedBioLog),
          'class_percent': _calculateOverallAttendance(simulatedSubjects),
          'subjects': subjectsForBreakdown
        });
      }

      final finalSubjectPercentages = Map.from(simulatedSubjects).map((key, value) {
        return MapEntry(key, (value['conducted'] > 0) ? (value['attended'] / value['conducted'] * 100) : 100.0);
      });

      if (mounted) {
        setState(() {
          _analysisData = {
            'type': 'analysis',
            'initialBio': initialBioPercentage,
            'initialClass': initialClassPercentage,
            'initialSubjects': initialSubjectPercentages,
            'finalBio': _calculateBioPercentage(simulatedBioLog),
            'finalClass': _calculateOverallAttendance(simulatedSubjects),
            'finalSubjects': finalSubjectPercentages,
            'daily_breakdown': dailyBreakdown,
            'last_date': lastDateForAnalysis ?? DateTime.now()
          };
        });
      }
    } catch (e, s) {
      print('Error during leave analysis: $e');
      print(s);
      if (mounted) {
        setState(() {
          _analysisData = {'error': 'An unexpected error occurred during analysis.'};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _calculateBioPercentage(List<Map<String, dynamic>> bioLog) {
    if (bioLog.isEmpty) return 100.0;
    final presentDays = bioLog.where((log) => (log['status'] as String? ?? '').toLowerCase().startsWith('p')).length;
    return (presentDays / bioLog.length) * 100;
  }

  double _calculateOverallAttendance(Map<String, dynamic> subjects) {
    if (subjects.isEmpty) return 100.0;
    double totalAttended = 0;
    double totalConducted = 0;
    for (var data in subjects.values) {
      totalAttended += (data['attended'] ?? 0);
      totalConducted += (data['conducted'] ?? 0);
    }
    return totalConducted == 0 ? 100.0 : (totalAttended / totalConducted) * 100;
  }
  
  void _showSelectOptionPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select an Option'),
        content: const Text('Please select a leave type before choosing dates.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showChoiceInfoPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choice Selection'),
        content: const Text('1 click for Present (green)\n2 clicks for Absent (red)\n3 clicks to deselect.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
  
  void _showGapErrorPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Date Gap Detected'),
        content: const Text('Please select a status for all previous days starting from the first available date.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
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

            final plannerData = snapshot.data!;
            final initialBio = _calculateBioPercentage(List<Map<String, dynamic>>.from(plannerData['bio_log'] ?? []));
            final initialClass = _calculateOverallAttendance(Map<String, dynamic>.from(plannerData['subjects'] ?? {}));

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            DateTime firstSelectableDate = (now.hour >= 13) ? today.add(const Duration(days: 1)) : today;

            final lastDayString = plannerData['last_sem_date'] as String?;
            DateTime lastSelectableDate = DateTime(now.year, now.month + 2);
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
                  _buildCurrentStats(theme, lastSelectableDate, initialBio, initialClass),
                  const SizedBox(height: 16),
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
                             _choiceDates.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Long Leave'),
                        selected: _leaveType == LeaveType.long,
                        selectedColor: theme.primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            _leaveType = selected ? LeaveType.long : LeaveType.none;
                            _selectedSingleDate = null;
                            _choiceDates.clear();
                          });
                        },
                      ),
                       const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Choice'),
                        selected: _leaveType == LeaveType.choice,
                        selectedColor: theme.primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            _leaveType = selected ? LeaveType.choice : LeaveType.none;
                            _selectedSingleDate = null;
                            _selectedLongLeaveDates.clear();
                            if (selected) {
                              _showChoiceInfoPopup();
                            }
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
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: (_selectedSingleDate != null || _selectedLongLeaveDates.isNotEmpty || _choiceDates.isNotEmpty) && !_isLoading ? _analyzeLeave : null,
                      child: const Text('Analyze Leave Impact'),
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

   Widget _buildCurrentStats(ThemeData theme, DateTime lastSemDate, double bio, double classAvg) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('End of Sem:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(DateFormat('d MMM, yyyy').format(lastSemDate), style: theme.textTheme.bodyMedium),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniPercentageItem('Bio Avg', bio),
              _buildMiniPercentageItem('Class Avg', classAvg),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultWidget() {
    final theme = Theme.of(context);
    if (_analysisData!.containsKey('error')) {
      return _buildErrorCard(theme, _analysisData!['error']);
    }

    if (_analysisData!['type'] == 'analysis') {
      final dailyBreakdown = _analysisData!['daily_breakdown'] as List<dynamic>;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dailyBreakdown.isNotEmpty)
            ...[
              const Text('Day-by-Day Simulation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...dailyBreakdown.map((dayData) => _buildDailyImpactCard(dayData)),
              const SizedBox(height: 16),
            ],
          const Text('Final Projected Impact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildFinalSummaryCard(_analysisData!),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDailyImpactCard(Map<String, dynamic> dayData) {
    final theme = Theme.of(context);
    final isAbsent = dayData['status'] == 'Absent';
    final cardColor = isAbsent ? Colors.red.withAlpha(38) : Colors.green.withAlpha(38);
    final statusText = isAbsent ? 'Leave Day (Assumed Absent)' : 'Assumed Present';
    final subjects = dayData['subjects'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, EEEE').format(dayData['date']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(statusText, style: TextStyle(fontSize: 12, color: isAbsent ? Colors.red.shade700 : Colors.green.shade800, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniPercentageItem('Biometric', dayData['bio_percent'] as double),
              _buildMiniPercentageItem('Class Avg', dayData['class_percent'] as double),
            ],
          ),
        ),
        children: subjects.isEmpty ? [Padding(padding: const EdgeInsets.all(16.0), child: Text("No Classes Today", style: theme.textTheme.bodyMedium))] : [
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: subjects.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(entry.key, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                      Text('${(entry.value as double).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSummaryCard(Map<String, dynamic> analysisData) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('After ${DateFormat('MMM d').format(analysisData['last_date'])}, your final projected attendance will be:', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniPercentageItem('Biometric', analysisData['finalBio'] as double, before: analysisData['initialBio'] as double, color: theme.colorScheme.onPrimaryContainer, isFinal: true),
                _buildMiniPercentageItem('Class Avg', analysisData['finalClass'] as double, before: analysisData['initialClass'] as double, color: theme.colorScheme.onPrimaryContainer, isFinal: true),
              ],
            ),
            const Divider(height: 24, thickness: 0.5, indent: 20, endIndent: 20),
            ..._buildSubjectBreakdown(analysisData, theme)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubjectBreakdown(Map<String, dynamic> analysisData, ThemeData theme) {
    final initialSubjects = Map<String, double>.from(analysisData['initialSubjects']);
    final finalSubjects = Map<String, double>.from(analysisData['finalSubjects']);
    List<Widget> subjectWidgets = [];

    for (var subjectName in initialSubjects.keys) {
      final initialPercent = initialSubjects[subjectName]!;
      final finalPercent = finalSubjects[subjectName]!;
      final diff = finalPercent - initialPercent;

      IconData? arrowIcon;
      Color? arrowColor;
      if (diff > 0.01) { arrowIcon = Icons.arrow_upward; arrowColor = Colors.green.shade400; }
      else if (diff < -0.01) { arrowIcon = Icons.arrow_downward; arrowColor = Colors.red.shade400; }

      subjectWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(subjectName, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer))),
              Expanded(flex: 2, child: Text('${initialPercent.toStringAsFixed(1)}% → ${finalPercent.toStringAsFixed(1)}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer))),
              SizedBox(
                width: 30,
                child: arrowIcon != null ? Icon(arrowIcon, color: arrowColor, size: 16) : const SizedBox(),
              )
            ],
          ),
        )
      );
    }
    return subjectWidgets;
  }


  Widget _buildMiniPercentageItem(String label, double value, {double? before, Color? color, bool isFinal = false}) {
    final theme = Theme.of(context);
    final valueStyle = isFinal ? theme.textTheme.headlineMedium : theme.textTheme.titleLarge;
    final diff = before != null ? value - before : null;
    
    IconData? arrow;
    Color? arrowColor;
    if (diff != null) {
      if (diff > 0.01) { arrow = Icons.arrow_upward; arrowColor = Colors.green.shade300; }
      else if (diff < -0.01) { arrow = Icons.arrow_downward; arrowColor = Colors.red.shade300; }
    }

    return Column(
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${value.toStringAsFixed(2)}%', style: valueStyle?.copyWith(color: color, fontWeight: FontWeight.bold)),
            if(arrow != null) ...[
              const SizedBox(width: 4),
              Icon(arrow, color: arrowColor, size: isFinal ? 24: 20)
            ]
          ],
        )
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Card(
      color: theme.colorScheme.errorContainer.withAlpha(100),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer), const SizedBox(width: 12), Expanded(child: Text(error, style: TextStyle(color: theme.colorScheme.onErrorContainer)))]),
      ),
    );
  }


  Widget _buildCalendarView(ThemeData theme, DateTime firstDate, DateTime lastDate) {
    bool isEnabled = _leaveType != LeaveType.none;
    return Material(
      color: theme.cardColor.withAlpha(isEnabled ? 178 : 51),
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () {
          if (_leaveType == LeaveType.none) {
            _showSelectOptionPopup();
          }
        },
        child: AbsorbPointer(
        absorbing: !isEnabled,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [_buildCalendarHeader(theme, firstDate, lastDate), const SizedBox(height: 8), _buildCalendarGrid(theme, firstDate, lastDate)]),
        ),
      ),
    ));
  }

  Widget _buildCalendarHeader(ThemeData theme, DateTime firstDate, DateTime lastDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { if (_displayedMonth.year == firstDate.year && _displayedMonth.month == firstDate.month) return; setState(() { _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1); }); }),
        Text(DateFormat.yMMMM().format(_displayedMonth), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { if (_displayedMonth.year == lastDate.year && _displayedMonth.month == lastDate.month) return; setState(() { _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1); }); }),
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
      dayWidgets.add(Center(child: Text(dayLabels[i], style: theme.textTheme.bodySmall?.copyWith(color: i == 0 ? Colors.red.shade300 : theme.textTheme.bodySmall?.color?.withAlpha(153)))));
    }

    for (int i = 0; i < weekDayOfFirstDay; i++) { dayWidgets.add(Container()); }

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, i);
      final bool isSunday = date.weekday == DateTime.sunday;
      final bool isPast = date.isBefore(firstDate);
      final bool isAfterSem = date.isAfter(lastDate);
      final bool isSelectable = !isSunday && !isPast && !isAfterSem;

      bool isSelected = false;
      Color? selectionColor;

      if (isSelectable) {
        if (_leaveType == LeaveType.single) {
          isSelected = _selectedSingleDate != null && DateUtils.isSameDay(date, _selectedSingleDate);
          if (isSelected) selectionColor = theme.primaryColor;
        } else if (_leaveType == LeaveType.long) {
          isSelected = _selectedLongLeaveDates.any((d) => DateUtils.isSameDay(date, d));
          if (isSelected) selectionColor = theme.primaryColor;
        } else if (_leaveType == LeaveType.choice) {
          if (_choiceDates.containsKey(date)) {
            isSelected = true;
            selectionColor = _choiceDates[date] == 1 ? Colors.green : Colors.red;
          }
        }
      }

      Color dayColor;
      if (isSunday) { dayColor = Colors.red.shade300; }
      else if (isPast) { dayColor = Colors.grey.shade700; }
      else if (isAfterSem) { dayColor = (theme.textTheme.bodyLarge?.color ?? Colors.white).withAlpha(100); }
      else if (isSelected) { dayColor = Colors.white; }
      else { dayColor = theme.textTheme.bodyLarge?.color ?? Colors.white; }

      dayWidgets.add(
        GestureDetector(
          onTap: isSelectable ? () => _handleDateSelection(date) : null,
          child: Container(
            alignment: Alignment.center,
            decoration: isSelected ? BoxDecoration(color: selectionColor, shape: BoxShape.circle) : null,
            child: Text(i.toString(), style: TextStyle(color: dayColor)),
          ),
        ),
      );
    }

    return GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: dayWidgets);
  }
}
