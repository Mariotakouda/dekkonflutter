import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../products/data/models/admin_product_model.dart';
import '../providers/admin_categories_provider.dart';

class AdminCategoryAttributesScreen extends ConsumerWidget {
  final String categoryId;
  final String categoryName;

  const AdminCategoryAttributesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  static const _types = ['text', 'number', 'boolean', 'select', 'multiselect'];

  static String _typeLabel(String type) {
    switch (type) {
      case 'number':
        return 'Nombre';
      case 'boolean':
        return 'Oui / Non';
      case 'select':
        return 'Choix unique';
      case 'multiselect':
        return 'Choix multiple';
      default:
        return 'Texte';
    }
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, {CategoryAttributeModel? existing}) {
    final keyController = TextEditingController(text: existing?.key ?? '');
    final labelController = TextEditingController(text: existing?.label ?? '');
    final optionsController = TextEditingController(text: existing?.options.join(', ') ?? '');
    String type = existing?.type ?? 'text';
    bool isRequired = existing?.isRequired ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Nouvel attribut' : "Modifier l'attribut"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: keyController,
                  enabled: existing == null,
                  decoration: const InputDecoration(labelText: 'Clé technique (ex: ram, pointure)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Libellé affiché (ex: RAM)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t)))).toList(),
                  onChanged: (v) => setState(() => type = v ?? 'text'),
                ),
                if (type == 'select' || type == 'multiselect') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: optionsController,
                    decoration: const InputDecoration(
                      labelText: 'Options (séparées par des virgules)',
                      hintText: 'Ex: 4Go, 8Go, 16Go',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isRequired,
                  onChanged: (v) => setState(() => isRequired = v),
                  title: const Text('Obligatoire à la création du produit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            Consumer(
              builder: (context, dialogRef, _) => CustomButton(
                label: existing == null ? 'Créer' : 'Enregistrer',
                onPressed: () async {
                  if (keyController.text.trim().isEmpty || labelController.text.trim().isEmpty) return;

                  final options = optionsController.text
                      .split(',')
                      .map((o) => o.trim())
                      .where((o) => o.isNotEmpty)
                      .toList();

                  final data = {
                    'key': keyController.text.trim(),
                    'label': labelController.text.trim(),
                    'type': type,
                    if (type == 'select' || type == 'multiselect') 'options': options,
                    'is_required': isRequired,
                  };

                  final notifier = dialogRef.read(adminCategoryAttributesProvider.notifier);
                  final error = existing == null
                      ? await notifier.create(categoryId, data)
                      : await notifier.update(categoryId, existing.id, data);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Attribut enregistré.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attributesAsync = ref.watch(categoryAttributesProvider(categoryId));

    return Scaffold(
      appBar: AppBar(title: Text('Attributs · $categoryName')),
      body: attributesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les attributs.',
          onRetry: () => ref.invalidate(categoryAttributesProvider(categoryId)),
        ),
        data: (attributes) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ces champs seront demandés automatiquement à la création d\'un produit de cette catégorie.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Ajouter un attribut',
                  icon: Icons.add,
                  onPressed: () => _showFormDialog(context, ref),
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: attributes.isEmpty
                      ? const Center(child: Text('Aucun attribut défini pour cette catégorie.'))
                      : ListView.separated(
                          itemCount: attributes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final attribute = attributes[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: AppTheme.ambientShadow,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          attribute.label,
                                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${attribute.key} · ${_typeLabel(attribute.type)}'
                                          '${attribute.isRequired ? ' · obligatoire' : ''}',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => _showFormDialog(context, ref, existing: attribute),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    onPressed: () async {
                                      final error = await ref
                                          .read(adminCategoryAttributesProvider.notifier)
                                          .delete(categoryId, attribute.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(error ?? 'Attribut supprimé.')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}