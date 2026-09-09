import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
      : _repo = repository ?? AuthRepository() {
    _status = _repo.currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    _sub = _repo.authStateChanges.listen(_onAuthChange);
  }

  final AuthRepository _repo;
  late final StreamSubscription<AuthState> _sub;

  AuthStatus _status = AuthStatus.unknown;
  bool _loading = false;
  String? _error;
  bool _recoveryMode = false;

  AuthStatus get status => _status;
  bool get isLoading => _loading;
  String? get error => _error;
  User? get user => _repo.currentUser;

  /// True setelah user membuka link reset password dari email — UI harus
  /// menampilkan layar "buat password baru", bukan Home.
  bool get recoveryMode => _recoveryMode;

  void _onAuthChange(AuthState state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      _recoveryMode = true;
    }
    _status = state.session != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  void exitRecoveryMode() {
    _recoveryMode = false;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }

  /// Return true jika sukses.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _repo.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Gagal registrasi: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _repo.login(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Gagal login: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(email);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Gagal mengirim link reset: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
  }

  /// Ganti password user yang sedang login. Return true jika sukses.
  Future<bool> changePassword(String newPassword) async {
    _setLoading(true);
    try {
      await _repo.changePassword(newPassword);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Gagal mengganti password: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
