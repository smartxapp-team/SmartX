import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/themed_background.dart';
import 'admin/admin_overview_screen.dart';
import 'admin/admin_users_screen.dart';
import 'admin/admin_broadcast_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'settings_screen.dart'; // Import the unified settings screen
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Updated list of pages for the admin dashboard
  static const List<Widget> _widgetOptions = <Widget>[
    AdminOverviewScreen(),
    AdminUsersScreen(),
    AdminBroadcastScreen(),
    AdminReportsScreen(),
    SettingsScreen(), // Use the same settings screen as students
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: _buildHeader(context, theme),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: _buildBottomNavBar(theme),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.shield_outlined,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(authProvider.username ?? 'Admin',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          icon: Icon(Icons.logout, color: theme.colorScheme.onBackground),
          tooltip: 'Logout',
          onPressed: () {
            authProvider.logout();
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                (route) => false);
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(theme,
                    icon: Icons.dashboard_customize_outlined,
                    label: 'Overview',
                    index: 0),
                _buildNavItem(theme,
                    icon: Icons.people_alt_outlined, label: 'Users', index: 1),
                _buildNavItem(theme,
                    icon: Icons.campaign_outlined,
                    label: 'Broadcast',
                    index: 2),
                _buildNavItem(theme,
                    icon: Icons.analytics_outlined,
                    label: 'Reports',
                    index: 3),
                _buildNavItem(theme,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    index: 4), // Updated Nav Item
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(ThemeData theme,
      {required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
            : const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 24),
            if (isSelected)
              Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(label,
                      style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
          ],
        ),
      ),
    );
  }
}