import 'package:flutter/material.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 60),
          SizedBox(height: 16),
          Text('Admin Overview', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}
