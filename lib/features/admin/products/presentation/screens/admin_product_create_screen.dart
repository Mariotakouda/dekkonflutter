import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/simple_filter_chip.dart';
import '../../../../../core/utils/validators.dart';
import '../../../categories/presentation/providers/admin_categories_provider.dart';
import '../../data/models/admin_product_model.dart';
import '../../data/repositories/admin_products_repository.dart';
import '../providers/admin_products_provider.dart';
import 'admin_product_detail_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class _PendingImage {
  final XFile file;
  final Uint8List bytes;
  bool isPrimary;

  _PendingImage({required this.file, required this.bytes, this.isPrimary = false});
}

class _VariantDraft {
  String name;
  double? price;
  int initialQuantity;
  bool isDefault;

  _VariantDraft({
    required this.name,
    this.price,
    this.initialQuantity = 0,
    this.isDefault = false,
  });
}

class AdminProductCreateScreen extends ConsumerStatefulWidget {
  const AdminProductCreateScreen({super.key});

  @override
  ConsumerState<AdminProductCreateScreen> createState() => _AdminProductCreateScreenState();
}

class _AdminProductCreateScreenState extends ConsumerState<AdminProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _brandController = TextEditingController();
  String? _selectedCategoryId;
  bool _isFeatured = false;
  bool _isPublishing = false;
  bool _isPickingImage = false;

  final List<_PendingImage> _images = [];
  final List<_VariantDraft> _variants = [];

  // Valeurs des attributs dynamiques de la catégorie sélectionnée, indexées par clé.
  final Map<String, dynamic> _attributeValues = {};
  final Map<String, TextEditingController> _attrTextControllers = {};
  final Map<String, bool> _attrBoolValues = {};
  final Map<String, String?> _attrSelectValues = {};
  final Map<String, List<String>> _attrMultiValues = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _costPriceController.dispose();
    _brandController.dispose();
    for (final c in _attrTextControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _attributeValues.clear();
      for (final c in _attrTextControllers.values) {
        c.dispose();
      }
      _attrTextControllers.clear();
      _attrBoolValues.clear();
      _attrSelectValues.clear();
      _attrMultiValues.clear();
    });
  }

  // --- Images ---

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

      if (file == null) {
        setState(() => _isPickingImage = false);
        return;
      }

      final Uint8List bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Le fichier sélectionné est vide.');
      }

      if (!mounted) return;

      setState(() {
        _images.add(_PendingImage(file: file, bytes: bytes, isPrimary: _images.isEmpty));
        _isPickingImage = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image : $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      final wasPrimary = _images[index].isPrimary;
      _images.removeAt(index);
      if (wasPrimary && _images.isNotEmpty) _images.first.isPrimary = true;
    });
  }

  void _setPrimary(int index) {
    setState(() {
      for (var i = 0; i < _images.length; i++) {
        _images[i].isPrimary = i == index;
      }
    });
  }

  // --- Variantes ---

  void _showVariantDraftDialog({_VariantDraft? existing, int? index}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController = TextEditingController(text: existing?.price?.toStringAsFixed(0) ?? '');
    final quantityController = TextEditingController(text: existing?.initialQuantity.toString() ?? '0');
    bool isDefault = existing?.isDefault ?? _variants.isEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nouvelle variante' : 'Modifier la variante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom (ex: Noir / M)')),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix spécifique (optionnel)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock initial'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isDefault,
                  onChanged: (v) => setDialogState(() => isDefault = v),
                  title: const Text('Variante par défaut'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            CustomButton(
              label: existing == null ? 'Ajouter' : 'Enregistrer',
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;

                final draft = _VariantDraft(
                  name: nameController.text.trim(),
                  price: priceController.text.trim().isNotEmpty ? double.tryParse(priceController.text.trim()) : null,
                  initialQuantity: int.tryParse(quantityController.text.trim()) ?? 0,
                  isDefault: isDefault,
                );

                setState(() {
                  if (isDefault) {
                    for (final v in _variants) {
                      v.isDefault = false;
                    }
                  }
                  if (index != null) {
                    _variants[index] = draft;
                  } else {
                    _variants.add(draft);
                  }
                });

                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

  // --- Publication ---

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie.')),
      );
      return;
    }

    // Vérifie que tous les attributs obligatoires de la catégorie sont renseignés.
    final categoryAttributes = ref.read(categoryAttributesProvider(_selectedCategoryId!)).value ?? [];
    for (final attribute in categoryAttributes) {
      if (!attribute.isRequired) continue;
      final value = _attributeValues[attribute.key];
      final isEmpty = value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);
      if (isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le champ "${attribute.label}" est obligatoire.')),
        );
        return;
      }
    }

    setState(() => _isPublishing = true);

    final productFields = {
      'category_id': _selectedCategoryId,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      if (_compareAtPriceController.text.trim().isNotEmpty)
        'compare_at_price': double.tryParse(_compareAtPriceController.text.trim()),
      if (_costPriceController.text.trim().isNotEmpty)
        'cost_price': double.tryParse(_costPriceController.text.trim()),
      'brand': _brandController.text.trim(),
      'is_featured': _isFeatured,
    };

    final variantMaps = _variants
        .map((v) => {
              'name': v.name,
              if (v.price != null) 'price': v.price,
              'initial_quantity': v.initialQuantity,
              'is_default': v.isDefault,
            })
        .toList();

    final pendingImages = _images
        .map((p) => PendingProductImage(file: p.file, isPrimary: p.isPrimary))
        .toList();

    final result = await ref.read(adminProductFormProvider.notifier).createFull(
          productFields: productFields,
          attributes: _attributeValues,
          variants: variantMaps,
          images: pendingImages,
        );

    setState(() => _isPublishing = false);

    if (!mounted) return;

    if (result.error != null || result.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Erreur lors de la création.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produit publié avec succès.')),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AdminProductDetailScreen(productId: result.product!.id)),
    );
  }

  // --- Champs dynamiques par catégorie ---

  Widget _buildCategoryAttributesSection() {
    if (_selectedCategoryId == null) return const SizedBox.shrink();

    final attributesAsync = ref.watch(categoryAttributesProvider(_selectedCategoryId!));

    return attributesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LoadingIndicator(),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (attributes) {
        if (attributes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Caractéristiques de la catégorie', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...attributes.map(
              (attribute) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAttributeField(attribute),
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAttributeField(CategoryAttributeModel attribute) {
    final requiredSuffix = attribute.isRequired ? ' *' : '';

    switch (attribute.type) {
      case 'boolean':
        final value = _attrBoolValues[attribute.key] ?? false;
        return CheckboxListTile(
          value: value,
          onChanged: (v) => setState(() {
            _attrBoolValues[attribute.key] = v ?? false;
            _attributeValues[attribute.key] = v ?? false;
          }),
          title: Text('${attribute.label}$requiredSuffix'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );

      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: _attrSelectValues[attribute.key],
          decoration: InputDecoration(labelText: '${attribute.label}$requiredSuffix'),
          items: attribute.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) => setState(() {
            _attrSelectValues[attribute.key] = v;
            _attributeValues[attribute.key] = v;
          }),
        );

      case 'multiselect':
        final selected = _attrMultiValues.putIfAbsent(attribute.key, () => []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${attribute.label}$requiredSuffix', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: attribute.options.map((option) {
                final isSelected = selected.contains(option);
                return SimpleFilterChip(
                  label: option,
                  selected: isSelected,
                  onTap: () => setState(() {
                    if (isSelected) {
                      selected.remove(option);
                    } else {
                      selected.add(option);
                    }
                    _attributeValues[attribute.key] = List<String>.from(selected);
                  }),
                );
              }).toList(),
            ),
          ],
        );

      case 'number':
        final controller = _attrTextControllers.putIfAbsent(attribute.key, () => TextEditingController());
        return CustomTextField(
          controller: controller,
          label: '${attribute.label}$requiredSuffix',
          keyboardType: TextInputType.number,
          onChanged: (v) => _attributeValues[attribute.key] = num.tryParse(v),
        );

      default: // text
        final controller = _attrTextControllers.putIfAbsent(attribute.key, () => TextEditingController());
        return CustomTextField(
          controller: controller,
          label: '${attribute.label}$requiredSuffix',
          onChanged: (v) => _attributeValues[attribute.key] = v,
        );
    }
  }

  // --- Variantes (section) ---

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Variantes (optionnel)', style: AppTextStyles.h4),
        const SizedBox(height: 4),
        Text(
          'Sans variante, une variante "Standard" est créée automatiquement.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (_variants.isNotEmpty)
          ..._variants.asMap().entries.map((entry) {
            final index = entry.key;
            final variant = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                          '${variant.name}${variant.isDefault ? ' · Par défaut' : ''}',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text('Stock initial: ${variant.initialQuantity}', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.edit, size: 18),
                    onPressed: () => _showVariantDraftDialog(existing: variant, index: index),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.delete, size: 18, color: AppColors.error),
                    onPressed: () => _removeVariant(index),
                  ),
                ],
              ),
            );
          }),
        OutlinedButton.icon(
          onPressed: () => _showVariantDraftDialog(),
          icon: const Icon(Symbols.add),
          label: Text(_variants.isEmpty ? 'Ajouter une variante' : 'Ajouter une autre variante'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau produit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photos', style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(
                'La première photo devient l\'image principale.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              categoriesAsync.when(
                loading: () => const LoadingIndicator(),
                error: (e, _) => const Text('Impossible de charger les catégories.'),
                data: (categories) {
                  final flatCategories = <AdminCategoryModel>[];
                  for (final parent in categories) {
                    flatCategories.addAll(parent.children.isEmpty ? [parent] : parent.children);
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: flatCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: _onCategoryChanged,
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildCategoryAttributesSection(),

              CustomTextField(
                controller: _nameController,
                label: 'Nom du produit',
                validator: (v) => Validators.required(v, field: 'Le nom'),
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: _descriptionController, label: 'Description', maxLines: 3),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: 'Prix de vente (FCFA)',
                keyboardType: TextInputType.number,
                validator: (v) => Validators.required(v, field: 'Le prix'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _compareAtPriceController,
                label: 'Prix comparatif (optionnel)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _costPriceController,
                label: "Prix d'achat (interne, optionnel)",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: _brandController, label: 'Marque (optionnel)'),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v ?? false),
                title: const Text('Produit vedette'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              _buildVariantsSection(),

              const SizedBox(height: 24),
              CustomButton(
                label: 'Publier le produit',
                isLoading: _isPublishing,
                onPressed: _isPublishing ? null : _publish,
                width: double.infinity,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final img = _images[index];
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            img.bytes,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.background,
                                alignment: Alignment.center,
                                child: const Icon(Symbols.broken_image, color: AppColors.error, size: 24),
                              );
                            },
                          ),
                        ),
                      ),
                      if (img.isPrimary)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Principale', style: TextStyle(color: Colors.white, fontSize: 9)),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                            child: const Icon(Symbols.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      if (!img.isPrimary)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _setPrimary(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Symbols.star, size: 14, color: AppColors.secondary),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_images.isNotEmpty) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isPickingImage ? null : _pickImage,
          icon: _isPickingImage
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Symbols.add_photo_alternate),
          label: Text(_images.isEmpty ? 'Ajouter une photo' : 'Ajouter une autre photo'),
        ),
      ],
    );
  }
}