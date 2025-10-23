import 'dart:ui';
import 'package:flutter/material.dart';

class DeadlinesDialog extends StatelessWidget {
  final List<Map<String, dynamic>> deadlines;

  const DeadlinesDialog({super.key, required this.deadlines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Increased height
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    children: [
                      Text('Unsubmitted Deadlines', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '${deadlines.length} tasks remaining',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: deadlines.isEmpty
                      ? const Center(child: Text('No unsubmitted deadlines found.'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: deadlines.length,
                          separatorBuilder: (context, index) => Divider(height: 1, indent: 24, endIndent: 24, color: theme.dividerColor.withOpacity(0.1)),
                          itemBuilder: (context, index) {
                            final lab = deadlines[index];
                            final isOverdue = _isDeadlineOverdue(lab['due_date_str']);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                              dense: true,
                              title: Text(
                                '${lab['course_name']} - ${lab['week']}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isOverdue ? theme.colorScheme.error : null,
                                ),
                              ),
                              subtitle: Text(
                                'Upload by: ${lab['due_date_str']}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isOverdue ? theme.colorScheme.error.withOpacity(0.8) : theme.colorScheme.onSurface.withAlpha(179),
                                ),
                              ),
                              trailing: isOverdue
                                  ? Icon(Icons.close, color: theme.colorScheme.error)
                                  : null,
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
            ),
          ),
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
}
