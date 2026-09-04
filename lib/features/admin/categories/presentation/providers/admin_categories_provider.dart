import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/data/models/admin_product_model.dart';
import '../../data/repositories/admin_categories_repository.dart';

final adminCategoriesRepositoryProvider = Provider<AdminCategoriesRepository>((ref) {
  return AdminCategoriesRepository(ref.watch(dioProvider));
});

class AdminCategoriesListNotifier extends AsyncNotifier<List<AdminCategoryModel>> {
  AdminCategoriesRepository get _repository => ref.read(adminCategoriesRepositoryProvider);

  @override
  Future<List<AdminCategoryModel>> build() async {
    return _repository.getCategories();
  }

  Future<String?> create({
    required String name,
    String? parentId,
    String? description,
    String? imageUrl,
  }) async {
    try {
      await _repository.createCategory(name: name, parentId: parentId, description: description, imageUrl: imageUrl);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateCategory(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      await _repository.updateCategory(id, name: name, description: description, imageUrl: imageUrl, isActive: isActive);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repository.deleteCategory(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final adminCategoriesListProvider = AsyncNotifierProvider<AdminCategoriesListNotifier, List<AdminCategoryModel>>(
  AdminCategoriesListNotifier.new,
);

/// Schéma d'attributs d'une catégorie (ex: RAM/Stockage pour "Électronique").
final categoryAttributesProvider =
    FutureProvider.autoDispose.family<List<CategoryAttributeModel>, String>((ref, categoryId) async {
  final repository = ref.watch(adminCategoriesRepositoryProvider);
  return repository.getCategoryAttributes(categoryId);
});

class AdminCategoryAttributesNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AdminCategoriesRepository get _repository => ref.read(adminCategoriesRepositoryProvider);

  Future<String?> create(String categoryId, Map<String, dynamic> data) async {
    state = true;
    try {
      await _repository.createCategoryAttribute(categoryId, data);
      ref.invalidate(categoryAttributesProvider(categoryId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> update(String categoryId, String attributeId, Map<String, dynamic> data) async {
    state = true;
    try {
      await _repository.updateCategoryAttribute(categoryId, attributeId, data);
      ref.invalidate(categoryAttributesProvider(categoryId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }

  Future<String?> delete(String categoryId, String attributeId) async {
    state = true;
    try {
      await _repository.deleteCategoryAttribute(categoryId, attributeId);
      ref.invalidate(categoryAttributesProvider(categoryId));
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final adminCategoryAttributesProvider = NotifierProvider<AdminCategoryAttributesNotifier, bool>(
  AdminCategoryAttributesNotifier.new,
);