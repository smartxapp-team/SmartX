import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService(apiUrl: authProvider.apiUrl, username: authProvider.username!);

      await apiService.sendBroadcastNotification(
        _titleController.text,
        _bodyController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent successfully!'), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Send Broadcast', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Send a push notification to all registered users.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Holiday Announcement'),
              validator: (value) => value == null || value.isEmpty ? 'Title cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Message', hintText: 'Enter your notification body...'),
              maxLines: 5,
              validator: (value) => value == null || value.isEmpty ? 'Message cannot be empty' : null,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendBroadcast,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Broadcast'),
                  ),
          ],
        ),
      ),
    );
  }
}
