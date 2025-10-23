import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    if (!canAuthenticate) {
      // If no biometrics or device lock is set up, we won't auto-login for security.
      return false;
    }

    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock SmartX',
        options: const AuthenticationOptions(
          // biometricOnly: false allows PIN/Pattern as a fallback.
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }
}
