import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AdminAuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? adminName;
  final String? errorMessage;

  const AdminAuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.adminName,
    this.errorMessage,
  });

  AdminAuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? adminName,
    String? errorMessage,
  }) {
    return AdminAuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      adminName: adminName ?? this.adminName,
      errorMessage: errorMessage,
    );
  }
}

class AdminAuthNotifier extends Notifier<AdminAuthState> {
  @override
  AdminAuthState build() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _verifyAdminAndSetState(user.id);
    }
    return const AdminAuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await supabase.auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Login failed.');
        return;
      }
      await _verifyAdminAndSetState(user.id);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Try again.');
    }
  }

  Future<void> _verifyAdminAndSetState(String userId) async {
    try {
      final profile = await supabase.from('profiles').select('full_name, role').eq('id', userId).maybeSingle();
      if (profile == null || profile['role'] != 'admin') {
        await supabase.auth.signOut();
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          errorMessage: 'This account does not have admin access.',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        adminName: profile['full_name'] as String? ?? 'Admin',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not verify admin access.');
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    state = const AdminAuthState();
  }
}

final adminAuthProvider = NotifierProvider<AdminAuthNotifier, AdminAuthState>(AdminAuthNotifier.new);