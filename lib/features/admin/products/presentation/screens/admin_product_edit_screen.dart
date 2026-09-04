import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/utils/validators.dart';
import '../../data/models/admin_product_model.dart';
import '../providers/admin_products_provider.dart';

class AdminProductEditScreen extends ConsumerStatefulWidget {
  final String productId;

  const AdminProductEditScreen({super.key, required this.productId});

  @override
  ConsumerState<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends ConsumerState<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _brandController = TextEditingController();
  String? _selectedCategoryId;
  bool _isFeatured = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _costPriceController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _populate(AdminProductModel product) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = product.name;
    _skuController.text = product.sku;
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price.toStringAsFixed(0);
    _compareAtPriceController.text = product.compareAtPrice?.toStringAsFixed(0) ?? '';
    _costPriceController.text = product.costPrice?.toStringAsFixed(0) ?? '';
    _brandController.text = product.brand ?? '';
    _selectedCategoryId = product.category?['id'] as String?;
    _isFeatured = product.isFeatured;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie.')),
      );
      return;
    }

    final data = {
      'category_id': _selectedCategoryId,
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      if (_compareAtPriceController.text.trim().isNotEmpty)
        'compare_at_price': double.tryParse(_compareAtPriceController.text.trim()),
      if (_costPriceController.text.trim().isNotEmpty)
        'cost_price': double.tryParse(_costPriceController.text.trim()),
      'brand': _brandController.text.trim(),
      'is_featured': _isFeatured,
    };

    final error = await ref.read(adminProductFormProvider.notifier).update(widget.productId, data);

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final isSubmitting = ref.watch(adminProductFormProvider);
    final productAsync = ref.watch(adminProductDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le produit')),
      body: productAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => const Center(child: Text('Erreur de chargement.')),
        data: (product) {
          _populate(product);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nom du produit',
                    validator: (v) => Validators.required(v, field: 'Le nom'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _skuController,
                    label: 'SKU',
                    validator: (v) => Validators.required(v, field: 'Le SKU'),
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
                    label: "Prix d'achat (interne)",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(controller: _brandController, label: 'Marque'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v ?? false),
                    title: const Text('Produit vedette'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Enregistrer',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}