import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../providers/theme_provider.dart';
import 'profile_screen.dart'; // Import the profile screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
            title: Text('View Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodyMedium?.color),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
            title: Text('Themes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodyMedium?.color),
            onTap: () => _showThemePicker(context),
          ),
        ),
      ],
    );
  }

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            title: const Text('Select Theme', textAlign: TextAlign.center),
            content: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: themeDisplayNames.keys.map((key) {
                    return RadioListTile<String>(
                      title: Text(themeDisplayNames[key]!),
                      value: key,
                      groupValue: themeProvider.themeKey,
                      onChanged: (String? value) {
                        if (value != null) {
                          themeProvider.setTheme(value);
                          // Close the picker dialog
                          Navigator.of(context).pop();
                          // Show the confirmation popup
                          _showThemeSelectedPopup(context, themeDisplayNames[value]!);
                        }
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showThemeSelectedPopup(BuildContext context, String themeName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (BuildContext context) {
        // A new BackdropFilter for the confirmation dialog
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 60),
                const SizedBox(height: 16),
                Text(
                  '$themeName Applied',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Automatically dismiss the dialog after a short period
    Future.delayed(const Duration(seconds: 2), () {
      if(Navigator.of(context).canPop()){
        Navigator.of(context).pop();
      }
    });
  }
}
