import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/categories_model.dart';
import '../../data/repositories/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(dioProvider));
});

/// FutureProvider simple — la liste des catégories change rarement,
/// pas besoin d'un state management complexe ici.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  return repository.getCategories();
});