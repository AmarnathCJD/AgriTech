import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  void _checkAutoLogin() async {
    // Check if user is already logged in
    final isLoggedIn = await context.read<UserProvider>().tryAutoLogin();
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _handleLogin() async {
    if (_mobileController.text.isEmpty || _mobileController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid mobile number")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call UserProvider to register/login
    final success = await context
        .read<UserProvider>()
        .loginOrRegister(_mobileController.text);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Professional Login Screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side: Branding / Image (Hidden on small screens if desired, but good for Tablet/Web)
          // For mobile, we just stack or remove. Let's assume mobile-first for farmers.
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Area
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.agriculture_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 24),

                    Text(
                      "Farmora",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      "Cultivating Success, Together.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 48),

                    // Login Form
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Login / Register",
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your mobile number to get started",
                          style: GoogleFonts.dmSans(
                              color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: "Mobile Number",
                            prefixIcon: const Icon(Icons.phone_android_rounded),
                            hintText: "9876543210",
                            prefixText: "+91 ",
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text(
                                "CONTINUE",
                                style:
                                    TextStyle(fontSize: 16, letterSpacing: 1),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                        child: Text("No OTP needed for beta testing",
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: Colors.grey[400])))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
