import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:biometric_auth/services/biometric_exception.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate({
    String reason = 'Silakan verifikasi identitas Anda',
    Iterable<AuthMessages>? authMessages,
    bool biometricOnly = false,
  }) async {
    try {
      // 1. Pre-check: apakah hardware tersedia?
      final bool available = await isBiometricAvailable();
      if (!available) {
        throw BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: 'Hardware not available',
          userMessage: 'Fitur biometrik tidak tersedia di perangkat ini.',
        );
      }

      // 2. Pre-check: apakah sudah ada biometrik terdaftar?
      final List<BiometricType> types = await getAvailableBiometrics();
      if (types.isEmpty) {
        throw BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: 'No biometrics enrolled',
          userMessage: 'Belum ada data biometrik terdaftar.',
        );
      }

      // 3. Tampilkan dialog biometrik OS
      final bool result = await _auth.authenticate(
        localizedReason: reason,
        authMessages: authMessages ?? const [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Diperlukan',
            cancelButton: 'Batal',
            biometricHint: 'Tempelkan jari atau arahkan wajah',
          ),
        ],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );

      // 4. result=false tanpa exception = user tekan Batal
      if (!result) {
        throw BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: 'User canceled authentication',
          userMessage: 'Autentikasi dibatalkan.',
        );
      }

      return true;
    } on PlatformException catch (e) {
      // Cek apakah ini error dari local_auth atau error sistem umum
      const authErrors = ['notAvailable', 'noHardware', 'notEnrolled', 'lockedOut', 'permanentlyLockedOut', 'passcodeNotSet'];
      if (authErrors.contains(e.code)) {
        throw BiometricException.fromPlatformException(e);
      }
      
      throw BiometricException(
        code: BiometricErrorCode.unknown,
        message: e.message ?? 'Unknown PlatformException',
        userMessage: 'Terjadi kesalahan sistem (${e.code}).',
      );
    }
  }
}