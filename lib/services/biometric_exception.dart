import 'package:flutter/services.dart';

enum BiometricErrorCode {
  noBiometricHardware,  // Tidak ada sensor biometrik di perangkat
  notEnrolled,          // Sensor ada, tapi belum ada data sidik jari/wajah terdaftar
  temporaryLockout,     // Terkunci sementara (terlalu banyak percobaan gagal)
  biometricLockout,     // Terkunci permanen (butuh buka kunci perangkat dengan PIN dulu)
  userCanceled,         // User menekan tombol Batal
  systemCanceled,       // Sistem membatalkan (mis. ada telepon masuk)
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;    // kategori error
  final String message;             // pesan teknis (untuk debugging/log)
  final String userMessage;         // pesan untuk ditampilkan ke user

  BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  // Constructor dari PlatformException (konversi error OS → custom model)
  factory BiometricException.fromPlatformException(PlatformException e) {
    switch (e.code) {
      case 'notAvailable':
      case 'noHardware':
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.message ?? 'No hardware',
          userMessage: 'Fitur biometrik tidak tersedia atau tidak didukung di perangkat ini.',
        );

      case 'notEnrolled':
        return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: e.message ?? 'Not enrolled',
          userMessage: 'Belum ada data biometrik terdaftar. Silakan atur di Keamanan Perangkat.',
        );

      case 'lockedOut':
        return BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: e.message ?? 'Locked out',
          userMessage: 'Terlalu banyak percobaan gagal. Silakan tunggu sebentar.',
        );

      case 'permanentlyLockedOut':
        return BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: e.message ?? 'Permanently locked out',
          userMessage: 'Biometrik terkunci. Masukkan PIN/Password perangkat untuk mengaktifkan kembali.',
        );

      case 'passcodeNotSet':
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.message ?? 'Passcode not set',
          userMessage: 'Keamanan perangkat (PIN/Password) belum diatur.',
        );

      default:
        if (e.message?.contains('canceled') ?? false) {
          return BiometricException(
            code: BiometricErrorCode.userCanceled,
            message: e.message ?? 'Canceled',
            userMessage: 'Autentikasi dibatalkan.',
          );
        }
        
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.message ?? 'Unknown error',
          userMessage: 'Terjadi kesalahan saat memproses biometrik (${e.code}).',
        );
    }
  }

  // ─── Computed getters — keputusan UI ───────────────────────────────────

  bool get isRetryable => 
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  bool get requiresFallback => 
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;
}