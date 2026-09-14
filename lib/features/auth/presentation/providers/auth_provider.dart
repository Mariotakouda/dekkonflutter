import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/secure_storage.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create(
    onUnauthorized: () => ref.read(authNotifierProvider.notifier).forceLogout(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

/// Permissions effectives de l'employé actuellement connecté (rôle +
/// permissions directes). Vide si l'utilisateur n'est pas un employé
/// ou n'est pas connecté. À utiliser pour afficher/masquer les écrans
/// et actions admin selon les droits réels de l'employé.
final employeePermissionsProvider = Provider<EmployeePermissions>((ref) {
  final employee = ref.watch(authNotifierProvider).user?.employee;
  return employee?.permissions ?? const EmployeePermissions({});
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  // `clearUser: true` force le passage à null : avec `user ?? this.user`,
  // il était impossible de remettre `user` à null (ex: forceLogout), ce qui
  // laissait l'ancien utilisateur "fantôme" en mémoire après déconnexion.
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.initial();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final result = await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      await SecureStorage.saveToken(result.token);
      state = state.copyWith(status: AuthStatus.authenticated, user: result.user);
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final result = await _repository.login(email: email, password: password);

      await SecureStorage.saveToken(result.token);
      state = state.copyWith(status: AuthStatus.authenticated, user: result.user);
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    }
  }

  Future<void> loadCurrentUser() async {
    final hasToken = await SecureStorage.hasToken();
    if (!hasToken) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _repository.me();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AppException {
      await SecureStorage.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Même si l'appel réseau échoue, on déconnecte localement.
    }
    await forceLogout();
  }

  Future<void> forceLogout() async {
    await SecureStorage.deleteToken();
    state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);