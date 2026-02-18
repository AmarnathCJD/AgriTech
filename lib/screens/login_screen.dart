import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../services/mock_backend.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController =
      TextEditingController(); // Only shown after sending OTP
  bool _otpSent = false;
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    if (!_otpSent) {
      // Simulate sending OTP
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
    } else {
      // Verify OTP
      final success = await MockBackend().login(
        _mobileController.text,
        _otpController.text,
      );
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Pattern (Subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network(
                'https://images.unsplash.com/photo-1625246333195-9818e0f20417?q=80&w=1000&auto=format&fit=crop', // Abstract field texture
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(color: Colors.grey[200]), // Fallback
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Branding Area
                  Icon(
                    Icons.agriculture_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 24),

                  Text(
                    "Farmora",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    "Smart Farming for a Better Future",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 48),

                  // Login Form
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Text(
                            _otpSent ? "Verify OTP" : "Welcome Farmer",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            enabled: !_otpSent,
                            decoration: const InputDecoration(
                              labelText: "Mobile Number",
                              prefixIcon: Icon(Icons.phone_android_rounded),
                              hintText: "+91 98765 43210",
                            ),
                          ),
                          if (_otpSent) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Enter OTP",
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _otpSent ? "Verify & Login" : "Send OTP",
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
