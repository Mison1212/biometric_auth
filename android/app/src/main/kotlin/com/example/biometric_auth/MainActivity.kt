package com.example.biometric_auth

import io.flutter.embedding.android.FlutterFragmentActivity

// WAJIB extends FlutterFragmentActivity (bukan FlutterActivity) agar
// local_auth dapat menampilkan BiometricPrompt sebagai Fragment dialog.
class MainActivity : FlutterFragmentActivity()
