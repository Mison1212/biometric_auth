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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // PERBAIKAN 1: Gunakan .instance karena constructor-nya private
  final BiometricService _service = BiometricService.instance;

  _AuthMethod? _activeMethod;
  bool _isLoading = false;
  String? _errorMessage;
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
    try {
      final types = await LocalAuthentication().getAvailableBiometrics();
      final List<_AuthMethod> methods = [];

      if (types.contains(BiometricType.face) ||
          types.contains(BiometricType.weak)) {
        methods.add(_AuthMethod.face);
      }
      if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong)) {
        methods.add(_AuthMethod.fingerprint);
      }
      methods.add(_AuthMethod.password);

      if (mounted) {
        setState(() {
          _availableMethods = methods;
          if (methods.isNotEmpty && methods.first != _AuthMethod.password) {
            _activeMethod = methods.first;
          } else {
            _activeMethod = _AuthMethod.password;
          }
        });
      }
    } catch (e) {
      // Handle error inisialisasi jika diperlukan
    }
  }

  Future<void> _handleBiometricAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _pulseController.repeat(reverse: true); // Gunakan reverse agar smooth

    // ... inside _handleBiometricAuth ...
    try {
      // Pastikan memanggil sesuai parameter yang ada di BiometricService
      final success = await _service.authenticate(
        localizedReason: 'Gunakan biometrik untuk masuk ke aplikasi',
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on BiometricException catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  void _handleError(BiometricException e) {
    setState(() {
      _errorMessage = e.userMessage;

      // Jika terkunci permanen atau hardware tidak ada, pindah ke metode Password
      if (e.code == BiometricErrorCode.biometricLockout ||
          e.code == BiometricErrorCode.noBiometricHardware) {
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

            // Area Utama (Biometrik atau Password)
            if (_activeMethod != _AuthMethod.password) ...[
              GestureDetector(
                onTap: _isLoading ? null : _handleBiometricAuth,
                child: ScaleTransition(
                  scale: _isLoading
                      ? _pulseAnim
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Icon(
                      _activeMethod == _AuthMethod.face
                          ? Icons.face
                          : Icons.fingerprint,
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
                        prefixIcon: const Icon(
                          Icons.password,
                          color: Colors.white70,
                        ),
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
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 50),
                        // PERBAIKAN 2: Gunakan RoundedRectangleBorder standar
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('MASUK'),
                    ),
                  ],
                ),
              ),
            ],

            // Pesan Error
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 40),

            // Selector Metode Login
            if (_availableMethods.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _availableMethods.map((method) {
                  final bool isActive = _activeMethod == method;
                  return IconButton(
                    icon: Icon(
                      method == _AuthMethod.password
                          ? Icons.keyboard
                          : (method == _AuthMethod.face
                                ? Icons.face
                                : Icons.fingerprint),
                    ),
                    color: isActive ? Colors.tealAccent : Colors.white54,
                    iconSize: isActive ? 32 : 24,
                    onPressed: () {
                      setState(() {
                        _activeMethod = method;
                        _errorMessage = null; // Reset error saat ganti metode
                      });
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
}
