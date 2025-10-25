import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/attendance_register_provider.dart';
import '../services/api_service.dart';
import '../widgets/themed_background.dart';
import 'home_screen.dart';
import 'lab_screen.dart';
import 'notifications_screen.dart';
import 'attendance_register_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLocked = true;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    LabScreen(),
    NotificationsScreen(),
    AttendanceRegisterScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _authenticateToUnlock();
  }

  Future<void> _authenticateToUnlock() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.authenticateOnDemand();

    if (mounted) {
      if (success) {
        setState(() {
          _isLocked = false;
        });
        // Fetch data after successful authentication
        final apiService = ApiService(
          apiUrl: authProvider.apiUrl,
          username: authProvider.username!,
          token: authProvider.token!,
        );
        Provider.of<AttendanceRegisterProvider>(context, listen: false)
            .fetchAttendanceData(apiService);
      } else {
        await authProvider.logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ThemedBackground(
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
        ),
        if (_isLocked)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint, size: 60, color: Colors.white70),
                  const SizedBox(height: 20),
                  Text(
                    'Authentication Required',
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _authenticateToUnlock,
                    child: const Text('Unlock'),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const ProfileScreen())),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person_outline, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(authProvider.username ?? 'Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.logout, color: theme.colorScheme.onBackground),
          tooltip: 'Logout',
          onPressed: () {
            authProvider.logout();
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => const LoginScreen()), (route) => false);
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
            offset: const Offset(0, 5),
          )
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
                _buildNavItem(theme, icon: Icons.home_rounded, label: 'Home', index: 0),
                _buildNavItem(theme, icon: Icons.science_outlined, label: 'Labs', index: 1),
                _buildNavItem(theme, icon: Icons.notifications_outlined, label: 'Notify', index: 2, hasBadge: true),
                _buildNavItem(theme, icon: Icons.app_registration, label: 'Register', index: 3),
                _buildNavItem(theme, icon: Icons.settings_outlined, label: 'Settings', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(ThemeData theme, {required IconData icon, required String label, required int index, bool hasBadge = false}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: isSelected ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0) : const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.7), size: 24),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      label,
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (hasBadge)
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  if (notificationProvider.unreadCount == 0) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        notificationProvider.unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
