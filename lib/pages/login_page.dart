import 'package:flutter/material.dart';
import '../services/biometric_exception.dart';
import '../services/biometric_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _AuthMethod { face, fingerprint, password }

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final BiometricService _service = BiometricService();
  _AuthMethod? _activeMethod;
  bool _isLoading = false;
  String? _errorMessage;
  BiometricErrorCode? _errorCode;
  List<_AuthMethod> _availableMethods = [];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final types = await _service.getAvailableBiometrics();
    
    final List<_AuthMethod> methods = [];
    if (types.contains(BiometricType.face) || types.contains(BiometricType.weak)) {
      methods.add(_AuthMethod.face);
    }
    if (types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong)) {
      methods.add(_AuthMethod.fingerprint);
    }
    methods.add(_AuthMethod.password);

    setState(() {
      _availableMethods = methods;
      // Default ke biometrik pertama jika ada
      if (methods.isNotEmpty && methods.first != _AuthMethod.password) {
        _activeMethod = methods.first;
      } else {
        _activeMethod = _AuthMethod.password;
      }
    });
  }

  Future<void> _handleBiometricAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _pulseController.repeat(reverse: false);
    try {
      String hint = 'Tempelkan jari atau arahkan wajah';
      if (_activeMethod == _AuthMethod.face) {
        hint = 'Arahkan wajah ke kamera';
      } else if (_activeMethod == _AuthMethod.fingerprint) {
        hint = 'Sentuh sensor sidik jari';
      }

      final success = await _service.authenticate(
        biometricOnly: true,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Diperlukan',
            cancelButton: 'Batal',
            biometricHint: hint,
          ),
        ],
      );
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on BiometricException catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  void _handleError(BiometricException e) {
    setState(() {
      _errorMessage = e.userMessage;
      _errorCode = e.code;
      if (e.requiresFallback) {
        _activeMethod = _AuthMethod.password;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade800, Colors.teal.shade900],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.white70),
            const SizedBox(height: 40),
            if (_activeMethod != _AuthMethod.password) ...[
              GestureDetector(
                onTap: _isLoading ? null : _handleBiometricAuth,
                child: ScaleTransition(
                  scale: _isLoading ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Icon(
                      _activeMethod == _AuthMethod.face ? Icons.face : Icons.fingerprint,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isLoading ? 'Memverifikasi...' : 'Ketuk untuk Masuk',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    TextField(
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.password, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangle_circular(12),
                      ),
                      child: const Text('MASUK'),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.orangeAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),
            if (_availableMethods.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _availableMethods.map((method) {
                  return IconButton(
                    icon: Icon(
                      method == _AuthMethod.password
                          ? Icons.keyboard
                          : (method == _AuthMethod.face ? Icons.face : Icons.fingerprint),
                    ),
                    color: _activeMethod == method ? Colors.tealAccent : Colors.white54,
                    onPressed: () {
                      setState(() => _activeMethod = method);
                      if (method != _AuthMethod.password && !_isLoading) {
                        _handleBiometricAuth();
                      }
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Helper for rounded corners because I made a typo in my thought process probably
  RoundedRectangleBorder RoundedRectangle_circular(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}