import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class BioLogDialog extends StatefulWidget {
  const BioLogDialog({super.key});

  @override
  State<BioLogDialog> createState() => _BioLogDialogState();
}

class _BioLogDialogState extends State<BioLogDialog> {
  late Future<Map<String, dynamic>> _bioLogFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.username != null) {
      final apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!, token: authProvider.token!);
      _bioLogFuture = apiService.fetchBioData();
    } else {
      _bioLogFuture = Future.value({'error': 'Not authenticated'});
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    if (status.toLowerCase() == 'present') return Colors.green.shade400;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1))
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _bioLogFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
                return _buildErrorState(theme, snapshot.data?['error']?.toString() ?? snapshot.error.toString());
              }

              final bioLog = List<Map<String, dynamic>>.from(snapshot.data!['bio_log']);
              final presentDays = bioLog.where((item) => item['status'].toString().toLowerCase() == 'present').length;
              final totalDays = bioLog.length;
              final average = totalDays > 0 ? (presentDays / totalDays * 100).toStringAsFixed(1) : '0.0';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Biometric Log', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              '$presentDays / $totalDays Days ($average%)',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: bioLog.isEmpty
                        ? const Center(child: Text('No records found.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: bioLog.length,
                            separatorBuilder: (context, index) => Divider(height: 1, indent: 24, endIndent: 24, color: theme.dividerColor.withOpacity(0.1)),
                            itemBuilder: (context, index) {
                              final item = bioLog[index];
                              final status = item['status'] ?? 'N/A';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                                dense: true,
                                leading: Text('${item["s_no"]}.', style: theme.textTheme.bodyMedium),
                                title: Text(item['date'] ?? 'N/A', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                                trailing: Text(
                                  status,
                                  style: TextStyle(color: _getStatusColor(status, theme), fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
