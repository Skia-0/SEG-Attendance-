import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateLearner() async {
    bool available = await isBiometricsAvailable();
    if (!available) {
      throw Exception("Biometrics are not supported or set up on this device.");
    }

    try {
      return await _auth.authenticate(
        localizedReason: 'Please scan your fingerprint to verify attendance',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      throw Exception("Biometric authentication failed: ${e.message}");
    }
  }
}
