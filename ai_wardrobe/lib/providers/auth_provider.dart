import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoggedIn;
  final String? email;
  final bool isLoading;

  AuthState({
    required this.isLoggedIn,
    this.email,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? email,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoggedIn: false, isLoading: true)) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final email = prefs.getString('user_email');
      state = AuthState(isLoggedIn: isLoggedIn, email: email, isLoading: false);
    } catch (_) {
      state = AuthState(isLoggedIn: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String otp) async {
    state = state.copyWith(isLoading: true);
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Validate demo OTP code (e.g. 123456)
    if (otp == '123456') {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', email);
        state = AuthState(isLoggedIn: true, email: email, isLoading: false);
        return true;
      } catch (_) {}
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('user_email');
    } catch (_) {}
    state = AuthState(isLoggedIn: false, email: null, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
