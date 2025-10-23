import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';

class BioScreen extends StatefulWidget {
  const BioScreen({super.key});

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen> {
  late Future<Map<String, dynamic>> _bioFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      final apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!);
      _bioFuture = apiService.fetchBioData();
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    if (status.toLowerCase() == 'present') return Colors.green.shade400;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('Biometric Log')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _bioFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
            }
            if (!snapshot.hasData || snapshot.data!.containsKey('error')) {
              return Center(child: Text(snapshot.data?['error'] ?? 'Could not fetch biometric data.'));
            }

            final bioLog = List<Map<String, dynamic>>.from(snapshot.data!['bio_log']);
            if (bioLog.isEmpty) {
              return const Center(child: Text('No biometric records found.'));
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(theme.colorScheme.primary.withOpacity(0.2)),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('In Time')),
                  DataColumn(label: Text('Out Time')),
                ],
                rows: bioLog.map((log) {
                  final status = log['status'] ?? 'N/A';
                  return DataRow(
                    cells: [
                      DataCell(Text(log['date'] ?? 'N/A')),
                      DataCell(Text(status, style: TextStyle(color: _getStatusColor(status, theme), fontWeight: FontWeight.bold))),
                      DataCell(Text(log['in_time'] ?? '--')),
                      DataCell(Text(log['out_time'] ?? '--')),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
