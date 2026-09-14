import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/addresses_model.dart';
import '../providers/addresses_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final AddressModel? existingAddress;

  const AddressFormScreen({super.key, this.existingAddress});

  bool get isEditing => existingAddress != null;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _recipientController =
      TextEditingController(text: widget.existingAddress?.recipientName ?? '');
  late final _phoneController = TextEditingController(text: widget.existingAddress?.phone ?? '');
  late final _cityController = TextEditingController(text: widget.existingAddress?.city ?? '');
  late final _districtController =
      TextEditingController(text: widget.existingAddress?.district ?? '');
  late final _addressLineController =
      TextEditingController(text: widget.existingAddress?.addressLine ?? '');
  late final _landmarkController =
      TextEditingController(text: widget.existingAddress?.landmarkNote ?? '');
  late bool _isDefault = widget.existingAddress?.isDefault ?? false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressLineController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(addressesNotifierProvider.notifier);
      final landmark =
          _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim();

      if (widget.isEditing) {
        await notifier.edit(
          widget.existingAddress!.id,
          recipientName: _recipientController.text.trim(),
          phone: _phoneController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          addressLine: _addressLineController.text.trim(),
          landmarkNote: landmark,
          isDefault: _isDefault,
        );
      } else {
        await notifier.add(
          recipientName: _recipientController.text.trim(),
          phone: _phoneController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          addressLine: _addressLineController.text.trim(),
          landmarkNote: landmark,
          isDefault: _isDefault,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.isEditing ? "Modifier l'adresse" : 'Nouvelle adresse')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.ambientShadow, blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _recipientController,
                      label: 'Nom du destinataire',
                      prefixIcon: const Icon(Symbols.person, color: AppColors.outline),
                      validator: (v) => Validators.required(v, field: 'Le destinataire'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Symbols.call, color: AppColors.outline),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _cityController,
                            label: 'Ville',
                            validator: (v) => Validators.required(v, field: 'La ville'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _districtController,
                            label: 'Quartier',
                            validator: (v) => Validators.required(v, field: 'Le quartier'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addressLineController,
                      label: 'Adresse détaillée',
                      maxLines: 2,
                      prefixIcon: const Icon(Symbols.location_on, color: AppColors.outline),
                      validator: (v) => Validators.required(v, field: "L'adresse"),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _landmarkController,
                      label: 'Point de repère (optionnel)',
                      hint: "Ex : Près de l'école primaire",
                      prefixIcon: const Icon(Symbols.push_pin, color: AppColors.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CheckboxListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v ?? false),
                  title: Text('Définir comme adresse par défaut', style: AppTextStyles.bodyMedium),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: widget.isEditing ? 'Enregistrer les modifications' : 'Enregistrer',
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}