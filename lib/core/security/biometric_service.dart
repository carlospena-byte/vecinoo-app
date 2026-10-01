import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key: whether the resident turned on biometric unlock.
const biometricEnabledPrefsKey = 'biometric_enabled';

/// The device's biometric prompt. Behind an interface so flows can be
/// tested without the platform plugin.
abstract interface class BiometricAuthenticator {
  /// True when the device has biometrics (or a device passcode) enrolled.
  Future<bool> isAvailable();

  /// Shows the system prompt; true only when the user passed it.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}

final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => LocalAuthBiometricAuthenticator(),
);

/// Why turning biometrics on did not finish.
enum BiometricEnableResult { enabled, unavailable, cancelled }

/// Whether biometric unlock is on. Turning it on requires passing the
/// system prompt once, so a resident can't lock themselves out with a
/// biometric the device doesn't have.
class BiometricEnabledController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(biometricEnabledPrefsKey) ?? false;
  }

  Future<BiometricEnableResult> enable(String reason) async {
    final authenticator = ref.read(biometricAuthenticatorProvider);
    if (!await authenticator.isAvailable()) {
      return BiometricEnableResult.unavailable;
    }
    if (!await authenticator.authenticate(reason)) {
      return BiometricEnableResult.cancelled;
    }
    await _store(true);
    return BiometricEnableResult.enabled;
  }

  Future<void> disable() => _store(false);

  Future<void> _store(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(biometricEnabledPrefsKey, value);
    state = AsyncData(value);
  }
}

final biometricEnabledProvider =
    AsyncNotifierProvider<BiometricEnabledController, bool>(
      BiometricEnabledController.new,
    );
