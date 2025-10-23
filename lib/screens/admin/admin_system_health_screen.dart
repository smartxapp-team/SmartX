import 'package:flutter/material.dart';

class AdminSystemHealthScreen extends StatelessWidget {
  const AdminSystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 60),
          SizedBox(height: 16),
          Text('System Health', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}
