import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final backgroundPath = AppTheme.getBackgroundPath(themeProvider.themeKey, platformBrightness);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundPath),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
