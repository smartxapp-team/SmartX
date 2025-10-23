import 'package:flutter/material.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 60),
          SizedBox(height: 16),
          Text('Generate Reports', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}
