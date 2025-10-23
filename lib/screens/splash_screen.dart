import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart'; // Corrected import

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _textController;
  late Animation<double> _textOpacityAnimation;

  double _logoPositionX = 0;
  bool _showText = false;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runAnimationSequence();
    _initiateLoginFlow();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
  }

  Future<void> _runAnimationSequence() async {
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _logoPositionX = -60;
      _showText = true;
    });
    _textController.forward();
  }

  void _initiateLoginFlow() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    void authListener() {
      if (mounted && !_navigationStarted) {
        _navigationStarted = true;
        _navigate(authProvider.isLoggedIn);
        authProvider.removeListener(authListener);
      }
    }

    authProvider.addListener(authListener);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_navigationStarted) {
        _navigationStarted = true;
        authProvider.removeListener(authListener);
        _navigate(authProvider.isLoggedIn);
      }
    });
  }

  void _navigate(bool isLoggedIn) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isLoggedIn ? const DashboardScreen() : const LoginScreen(), // Corrected navigation
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOutCubic,
            transform: Matrix4.translationValues(_logoPositionX, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_showText) _buildSmartText(),
                SizedBox(width: _showText ? 4 : 0),
                _buildXLogo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Image.asset('assets/x_logo.png', width: 80),
      ),
    );
  }

  Widget _buildSmartText() {
    return FadeTransition(
      opacity: _textOpacityAnimation,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.blue, Colors.lightBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'Smart',
          style: GoogleFonts.dancingScript(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.white, 
          ),
        ),
      ),
    );
  }
}
