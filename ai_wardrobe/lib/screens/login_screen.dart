import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import 'splash_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailLower = email.toLowerCase().trim();
    return RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(emailLower);
  }

  void _sendOtp() {
    if (_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _otpSent = true;
        _errorMessage = null;
      });
      // Show simulated OTP in a snackbar for easy testing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AtelierTheme.accent),
              const SizedBox(width: 12),
              Text(
                'Demo OTP Code sent! Enter "123456" to verify.',
                style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AtelierTheme.accent,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Please enter a valid Gmail address (ending in @gmail.com)';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'OTP must be a 6-digit code';
      });
      return;
    }

    final success = await ref.read(authProvider.notifier).login(email, otp);
    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid OTP code. Please enter 123456';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Text(
                    'AI WARDROBE',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      color: AtelierTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'YOUR PERSONAL STYLING WORKSPACE',
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: AtelierTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Auth Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AtelierTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AtelierTheme.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otpSent ? 'ENTER OTP CODE' : 'GMAIL AUTHENTICATION',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AtelierTheme.accent,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        if (!_otpSent) ...[
                          // Email Input
                          Text(
                            'GMAIL / EMAIL',
                            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AtelierTheme.secondaryText),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'name@gmail.com',
                              hintStyle: GoogleFonts.inter(color: AtelierTheme.secondaryText.withOpacity(0.5)),
                              filled: true,
                              fillColor: AtelierTheme.surfaceAccent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ] else ...[
                          // OTP Input
                          Text(
                            'OTP CODE',
                            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AtelierTheme.secondaryText),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 8.0),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '******',
                              hintStyle: GoogleFonts.inter(color: AtelierTheme.secondaryText.withOpacity(0.5)),
                              filled: true,
                              fillColor: AtelierTheme.surfaceAccent,
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(fontSize: 12, color: AtelierTheme.warning),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authState.isLoading
                                ? null
                                : (_otpSent ? _verifyOtp : _sendOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AtelierTheme.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: authState.isLoading
                                ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                                : Text(
                                    _otpSent ? 'VERIFY OTP' : 'SEND OTP CODE',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ),
                        
                        if (_otpSent) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _otpSent = false;
                                  _otpController.clear();
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                'Change Email',
                                style: GoogleFonts.inter(color: AtelierTheme.secondaryText),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
