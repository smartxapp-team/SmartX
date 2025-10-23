import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';

class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _timetableFuture;
  late ApiService _apiService;
  List<String> _days = [];
  int _initialIndex = 0;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      _apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!, token: authProvider.token!);
      _timetableFuture = _fetchTimetableData();
    } else {
      _timetableFuture = Future.value({'error': 'Not authenticated'});
    }
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchTimetableData() async {
    final data = await _apiService.fetchTimetable();
    if (mounted && data.containsKey('timetable')) {
      final timetable = data['timetable'] as Map<String, dynamic>;
      final orderedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      _days = timetable.keys.toList()..sort((a, b) => orderedDays.indexOf(a).compareTo(orderedDays.indexOf(b)));

      final today = DateFormat('EEEE').format(DateTime.now());
      final newIndex = _days.contains(today) ? _days.indexOf(today) : 0;

      setState(() {
        _initialIndex = newIndex;
        _tabController = TabController(length: _days.length, vsync: this, initialIndex: _initialIndex);
      });
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Full Timetable'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _timetableFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
              String errorMessage = 'Failed to load timetable.';
              if (snapshot.hasError) {
                errorMessage = 'Error: ${snapshot.error}';
              } else if (snapshot.hasData && snapshot.data!.containsKey('error')) {
                errorMessage = 'Backend Error: ${snapshot.data!['error']}';
              }
              return Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(errorMessage, textAlign: TextAlign.center),
              ));
            }

            final timetable = snapshot.data!['timetable'] as Map<String, dynamic>;

            if (_days.isEmpty) {
              return const Center(child: Text('No timetable data available.'));
            }

            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _days.map((day) => Tab(text: day)).toList(),
                  labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: theme.textTheme.titleMedium,
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _days.map((day) {
                      final periods = List<Map<String, dynamic>>.from(timetable[day] ?? []);
                      if (periods.isEmpty) {
                        return const Center(child: Text('No classes for this day.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        itemCount: periods.length,
                        itemBuilder: (context, index) {
                          final period = periods[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            margin: const EdgeInsets.symmetric(vertical: 10.0),
                            color: theme.cardColor.withOpacity(0.5),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      period['period'] ?? 'N/A',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          period['subject_full'] ?? 'N/A',
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.3),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Room: ${period['room'] ?? 'N/A'}',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
