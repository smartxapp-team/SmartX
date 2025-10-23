import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';

class LabDetailsScreen extends StatefulWidget {
  final String courseCode;
  final String courseName;

  const LabDetailsScreen({super.key, required this.courseCode, required this.courseName});

  @override
  State<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

class _LabDetailsScreenState extends State<LabDetailsScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _labDetailsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      final apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!, token: authProvider.token!);
      _labDetailsFuture = apiService.fetchLabDetails(widget.courseCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.courseName)),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _labDetailsFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
              return Center(child: Text(snapshot.data?['error'] ?? 'Could not fetch lab details.'));
            }

            final deadlines = List<Map<String, dynamic>>.from(snapshot.data!['deadlines']);
            final submitted = deadlines.where((d) => d['submitted'] == true).toList();
            final notSubmitted = deadlines.where((d) => d['submitted'] == false).toList();

            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'To Be Submitted (${notSubmitted.length})'),
                    Tab(text: 'Submitted (${submitted.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDeadlineList(notSubmitted, theme, isSubmittedList: false),
                      _buildDeadlineList(submitted, theme, isSubmittedList: true),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isDeadlineOverdue(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return date.isBefore(today);
    } catch (e) {
      return false;
    }
  }

  Widget _buildDeadlineList(List<Map<String, dynamic>> items, ThemeData theme, {required bool isSubmittedList}) {
    if (items.isEmpty) {
      return Center(child: Text(isSubmittedList ? 'No labs submitted yet.' : 'All labs submitted!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOverdue = !isSubmittedList && _isDeadlineOverdue(item['due_date_str']);

        return Card(
          color: isSubmittedList 
              ? Colors.green.withOpacity(0.15) 
              : (isOverdue ? Colors.red.withOpacity(0.15) : null),
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: Icon(
              isSubmittedList 
                  ? Icons.check_circle_outline 
                  : (isOverdue ? Icons.close : Icons.pending_outlined),
              color: isSubmittedList 
                  ? Colors.green 
                  : (isOverdue ? Colors.red : theme.colorScheme.secondary),
            ),
            title: Text('${item['week']}: ${item['title']}', style: theme.textTheme.titleMedium),
            subtitle: Text('Due: ${item['due_date_str']}', style: theme.textTheme.bodyMedium),
          ),
        );
      },
    );
  }
}
