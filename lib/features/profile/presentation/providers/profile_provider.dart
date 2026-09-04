import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

class ProfileUpdateNotifier extends Notifier<bool> {
  @override
  bool build() => false; // isSubmitting

  /// Retourne `null` en cas de succès, ou un message d'erreur exploitable
  /// par l'UI en cas d'échec (ex: email déjà utilisé).
  Future<String?> update({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    state = true;
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

      // Resynchronise l'état global auth avec les nouvelles infos.
      await ref.read(authNotifierProvider.notifier).loadCurrentUser();

      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final profileUpdateProvider = NotifierProvider<ProfileUpdateNotifier, bool>(
  ProfileUpdateNotifier.new,
);
