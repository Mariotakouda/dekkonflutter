import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../products/data/models/admin_product_model.dart';
import '../providers/admin_categories_provider.dart';
import 'admin_category_attributes_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(adminCategoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showFormDialog(context, ref),
        child: const Icon(Symbols.add, color: Colors.white),
      ),
      body: categoriesState.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les catégories.',
          onRetry: () => ref.invalidate(adminCategoriesListProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(icon: Symbols.category, title: 'Aucune catégorie');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) => _CategoryGroup(category: categories[index]),
          );
        },
      ),
    );
  }

  static void _showFormDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminCategoryModel? existing,
    String? parentIdFixed,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    final imageUrlController = TextEditingController(text: existing?.imageUrl ?? '');
    String? parentId = existing?.parentId ?? parentIdFixed;
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final categoriesAsync = dialogRef.watch(adminCategoriesListProvider);

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(existing == null ? 'Nouvelle catégorie' : 'Modifier la catégorie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: 'URL image (optionnel)'),
                    ),
                    if (existing == null && parentIdFixed == null) ...[
                      const SizedBox(height: 12),
                      categoriesAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (categories) => DropdownButtonFormField<String>(
                          initialValue: parentId,
                          decoration: const InputDecoration(labelText: 'Catégorie parente (optionnel)'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Aucune (racine)')),
                            ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setState(() => parentId = v),
                        ),
                      ),
                    ],
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) => setState(() => isActive = v),
                        title: const Text('Active'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
                CustomButton(
                  label: existing == null ? 'Créer' : 'Enregistrer',
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final notifier = dialogRef.read(adminCategoriesListProvider.notifier);
                    final error = existing == null
                        ? await notifier.create(
                            name: nameController.text.trim(),
                            parentId: parentId,
                            description: descriptionController.text.trim(),
                            imageUrl: imageUrlController.text.trim(),
                          )
                        : await notifier.updateCategory(
                            existing.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            imageUrl: imageUrlController.text.trim(),
                            isActive: isActive,
                          );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? 'Catégorie enregistrée.')),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryGroup extends ConsumerWidget {
  final AdminCategoryModel category;

  const _CategoryGroup({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Symbols.folder, color: AppColors.secondary, size: 20),
        ),
        title: Text(category.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${category.productsCount ?? 0} produit(s)', style: AppTextStyles.caption),
                trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Symbols.tune, size: 18),
              tooltip: 'Attributs de la catégorie',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminCategoryAttributesScreen(categoryId: category.id, categoryName: category.name),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Symbols.edit, size: 18),
              onPressed: () => AdminCategoriesScreen._showFormDialog(context, ref, existing: category),
            ),
            IconButton(
              icon: const Icon(Symbols.add, size: 18, color: AppColors.primary),
              tooltip: 'Ajouter une sous-catégorie',
              onPressed: () => AdminCategoriesScreen._showFormDialog(context, ref, parentIdFixed: category.id),
            ),
            IconButton(
              icon: const Icon(Symbols.delete, color: AppColors.error, size: 18),
              onPressed: () async {
                final error = await ref.read(adminCategoriesListProvider.notifier).delete(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Catégorie supprimée.')),
                  );
                }
              },
            ),
          ],
        ),
        children: category.children
            .map((child) => ListTile(
                  title: Text(child.name),
                  subtitle: Text('${child.productsCount ?? 0} produit(s)'),
                                    trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Symbols.tune, size: 18),
                        tooltip: 'Attributs de la catégorie',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminCategoryAttributesScreen(categoryId: child.id, categoryName: child.name),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Symbols.edit, size: 18),
                        onPressed: () => AdminCategoriesScreen._showFormDialog(context, ref, existing: child),
                      ),
                      IconButton(
                        icon: const Icon(Symbols.delete, size: 18, color: AppColors.error),
                        onPressed: () async {
                          final error = await ref.read(adminCategoriesListProvider.notifier).delete(child.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error ?? 'Catégorie supprimée.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}