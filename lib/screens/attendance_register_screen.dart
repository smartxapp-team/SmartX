import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/attendance_register_provider.dart';
import '../widgets/themed_background.dart';

class AttendanceRegisterScreen extends StatefulWidget {
  const AttendanceRegisterScreen({super.key});

  @override
  State<AttendanceRegisterScreen> createState() => _AttendanceRegisterScreenState();
}

class _AttendanceRegisterScreenState extends State<AttendanceRegisterScreen> {
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  final ScrollController _subjectsScrollController = ScrollController();
  final ScrollController _registerScrollController = ScrollController();

  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;

  @override
  void initState() {
    super.initState();
    _headerScrollController.addListener(_syncHeaderToBody);
    _bodyScrollController.addListener(_syncBodyToHeader);
    _subjectsScrollController.addListener(_syncSubjectsToRegister);
    _registerScrollController.addListener(_syncRegisterToSubjects);
  }

  void _syncHeaderToBody() {
    if (_isSyncingHorizontal) return;
    _isSyncingHorizontal = true;
    if (_bodyScrollController.hasClients) {
      _bodyScrollController.jumpTo(_headerScrollController.offset);
    }
    _isSyncingHorizontal = false;
  }

  void _syncBodyToHeader() {
    if (_isSyncingHorizontal) return;
    _isSyncingHorizontal = true;
    if (_headerScrollController.hasClients) {
      _headerScrollController.jumpTo(_bodyScrollController.offset);
    }
    _isSyncingHorizontal = false;
  }

  void _syncSubjectsToRegister() {
    if (_isSyncingVertical) return;
    _isSyncingVertical = true;
    if (_registerScrollController.hasClients) {
      _registerScrollController.jumpTo(_subjectsScrollController.offset);
    }
    _isSyncingVertical = false;
  }

  void _syncRegisterToSubjects() {
    if (_isSyncingVertical) return;
    _isSyncingVertical = true;
    if (_subjectsScrollController.hasClients) {
      _subjectsScrollController.jumpTo(_registerScrollController.offset);
    }
    _isSyncingVertical = false;
  }

  @override
  void dispose() {
    _headerScrollController.removeListener(_syncHeaderToBody);
    _bodyScrollController.removeListener(_syncBodyToHeader);
    _subjectsScrollController.removeListener(_syncSubjectsToRegister);
    _registerScrollController.removeListener(_syncRegisterToSubjects);
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _subjectsScrollController.dispose();
    _registerScrollController.dispose();
    super.dispose();
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
    return date;
  }

  String _getShortCourseName(String courseName) {
    final RegExp acronymInParentheses = RegExp(r'\(([^)]+)\)');
    final Match? acronymMatch = acronymInParentheses.firstMatch(courseName);
    if (acronymMatch != null) return acronymMatch.group(1)!;
    bool isLab = courseName.toLowerCase().contains('laboratory');
    String baseName = isLab
        ? courseName.replaceAll(RegExp(r'\s+laboratory', caseSensitive: false), '')
        : courseName;
    List<String> ignoreWords = ['and', 'of', 'in', 'for', 'to', 'a', 'an'];
    List<String> words = baseName
        .split(' ')
        .where((word) =>
            word.isNotEmpty && !ignoreWords.contains(word.toLowerCase()))
        .toList();
    String shortName = words.map((e) => e[0].toUpperCase()).join();
    if (isLab) shortName += ' Lab';
    return shortName;
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Attendance Register'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Consumer<AttendanceRegisterProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null || provider.attendanceData == null) {
              return Center(
                  child: Text(provider.error ?? 'Failed to load data.'));
            }

            final data = provider.attendanceData!;
            final List<String> subjects = List<String>.from(data['subjects']);
            final List<String> dates = List<String>.from(data['dates']);
            final Map<String, dynamic> register = data['register'];
            const double subjectColumnWidth = 100.0;
            const double dateColumnWidth = 60.0;
            const double headerHeight = 100.0;

            return LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight - headerHeight;
                final double calculatedCellHeight = availableHeight / subjects.length;
                const double minimumCellHeight = 48.0;
                final double actualCellHeight = calculatedCellHeight < minimumCellHeight ? minimumCellHeight : calculatedCellHeight;

                return Column(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: Row(
                        children: [
                          Card(
                            margin: const EdgeInsets.fromLTRB(4, 4, 2, 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: SizedBox(
                              width: subjectColumnWidth - 6,
                              height: headerHeight,
                              child: const Center(child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _headerScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Row(
                                children: dates.map((date) {
                                  return Card(
                                    margin: const EdgeInsets.all(4.0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: SizedBox(
                                      width: dateColumnWidth - 8,
                                      height: headerHeight,
                                      child: Center(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(_formatDate(date), style: const TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: subjectColumnWidth,
                            child: ListView.builder(
                              controller: _subjectsScrollController,
                              physics: const ClampingScrollPhysics(),
                              itemCount: subjects.length,
                              itemExtent: actualCellHeight,
                              itemBuilder: (context, index) {
                                return Card(
                                  margin: const EdgeInsets.fromLTRB(4, 2, 2, 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: SizedBox(
                                    height: actualCellHeight - 4,
                                    child: Center(child: Text(_getShortCourseName(subjects[index]), textAlign: TextAlign.center)),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _bodyScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                width: dates.length * dateColumnWidth,
                                child: ListView.builder(
                                  controller: _registerScrollController,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: subjects.length,
                                  itemExtent: actualCellHeight,
                                  itemBuilder: (context, subjectIndex) {
                                    final subject = subjects[subjectIndex];
                                    return Row(
                                      children: dates.map((date) {
                                        final dynamic rawStatus = register[subject][dates.indexOf(date)];
                                        String displayStatus;
                                        int? count;

                                        if (rawStatus is List) {
                                          int presentCount = 0;
                                          int absentCount = 0;
                                          for (var statusEntry in rawStatus) {
                                            if (statusEntry == 'PRESENT') {
                                              presentCount++;
                                            } else if (statusEntry == 'ABSENT') {
                                              absentCount++;
                                            }
                                          }

                                          if (presentCount > 0 && absentCount == 0) {
                                            displayStatus = 'PRESENT';
                                            count = presentCount;
                                          } else if (absentCount > 0 && presentCount == 0) {
                                            displayStatus = 'ABSENT';
                                            count = absentCount;
                                          } else {
                                            displayStatus = '-';
                                            count = null;
                                          }
                                        } else if (rawStatus is String) {
                                          RegExp regExp = RegExp(r'^(PRESENT|ABSENT)\\s\\((\\d+)\\)$');
                                          Match? match = regExp.firstMatch(rawStatus);

                                          if (match != null) {
                                            displayStatus = match.group(1)!;
                                            count = int.parse(match.group(2)!);
                                          } else {
                                            displayStatus = rawStatus;
                                            count = null;
                                          }
                                        } else {
                                          displayStatus = '-';
                                          count = null;
                                        }

                                        Widget statusWidget;
                                        if (displayStatus == 'PRESENT') {
                                          statusWidget = const Icon(Icons.check, color: Colors.green, size: 20);
                                        } else if (displayStatus == 'ABSENT') {
                                          statusWidget = const Icon(Icons.close, color: Colors.red, size: 20);
                                        } else {
                                          statusWidget = const Text('-', style: TextStyle(color: Colors.grey, fontSize: 18));
                                        }

                                        return Card(
                                          margin: const EdgeInsets.all(2.0),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          child: SizedBox(
                                            width: dateColumnWidth - 4,
                                            height: actualCellHeight - 4,
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  statusWidget,
                                                  if (count != null && count > 1)
                                                    Text(
                                                      ' ($count)',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
