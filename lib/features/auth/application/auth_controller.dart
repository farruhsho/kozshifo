import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/session_events.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState(this.status, [this.user]);

  final AuthStatus status;
  final AuthUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // The network layer bumps this tick when the refresh token is rejected:
    // the session is dead, so drop to the login screen.
    ref.listen(sessionExpiredTickProvider, (_, _) {
      if (state.isAuthenticated) {
        state = const AuthState(AuthStatus.unauthenticated);
      }
    });
    // Restore any persisted session on startup.
    Future.microtask(_restore);
    return const AuthState(AuthStatus.unknown);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    try {
      final user = await _repo.currentUser();
      state = AuthState(AuthStatus.authenticated, user);
    } on ApiException catch (e) {
      // Only a definitive rejection wipes the stored session; if the backend
      // is merely unreachable at startup, the 30-day refresh token must
      // survive for the next attempt.
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _repo.logout();
      }
      state = const AuthState(AuthStatus.unauthenticated);
    } catch (_) {
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

  /// Throws [ApiException] on failure (handled by the login screen).
  Future<void> login(String email, String password) async {
    await _repo.login(email, password);
    final user = await _repo.currentUser();
    state = AuthState(AuthStatus.authenticated, user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}
