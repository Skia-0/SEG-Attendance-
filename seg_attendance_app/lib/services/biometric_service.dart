import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Returns null on success, error message on failure
  Future<String?> authenticate({required String reason}) async {
    try {
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return result ? null : 'Authentication cancelled';
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return 'Biometrics not available on this device';
        case auth_error.notEnrolled:
          return 'No fingerprints enrolled. '
              'Please add one in phone Settings first';
        case auth_error.lockedOut:
          return 'Too many attempts. Try again later';
        case auth_error.permanentlyLockedOut:
          return 'Biometrics locked. Use PIN/password to unlock';
        case auth_error.passcodeNotSet:
          return 'Please set a screen lock in phone Settings';
        default:
          return 'Biometric error: ${e.message ?? e.code}';
      }
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }
}