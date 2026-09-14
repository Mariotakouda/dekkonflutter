import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/utils/validators.dart';
import '../providers/admin_employees_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminEmployeeFormScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const AdminEmployeeFormScreen({super.key, this.employeeId});

  @override
  ConsumerState<AdminEmployeeFormScreen> createState() => _AdminEmployeeFormScreenState();
}

class _AdminEmployeeFormScreenState extends ConsumerState<AdminEmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _positionController = TextEditingController();
  String? _selectedRoleId;
  bool _isActive = true;
  bool _initialized = false;

  bool get _isEditing => widget.employeeId != null;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _populate(dynamic employee) {
    if (_initialized) return;
    _initialized = true;
    _firstNameController.text = employee.firstName;
    _lastNameController.text = employee.lastName;
    _emailController.text = employee.user?['email'] as String? ?? '';
    _phoneController.text = employee.user?['phone'] as String? ?? '';
    _positionController.text = employee.position ?? '';
    _selectedRoleId = (employee.user?['role'] as Map<String, dynamic>?)?['id'] as String?;
    _isActive = employee.status == 'ACTIVE';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      final data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'position': _positionController.text.trim(),
        if (_selectedRoleId != null) 'role_id': _selectedRoleId,
        'status': _isActive ? 'ACTIVE' : 'INACTIVE',
      };

      final error = await ref.read(adminEmployeeFormProvider.notifier).update(widget.employeeId!, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Employé mis à jour.')),
      );
    } else {
      if (_selectedRoleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un rôle.')),
        );
        return;
      }

      final error = await ref.read(adminEmployeeFormProvider.notifier).create({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'role_id': _selectedRoleId,
        'position': _positionController.text.trim(),
      });

      if (!mounted) return;

      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver cet employé ?'),
        content: const Text('L\'employé ne pourra plus se connecter.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Désactiver')),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await ref.read(adminEmployeeFormProvider.notifier).deactivate(widget.employeeId!);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Employé désactivé.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(adminRolesProvider);
    final isSubmitting = ref.watch(adminEmployeeFormProvider);
    final employeeAsync = _isEditing ? ref.watch(adminEmployeeDetailProvider(widget.employeeId!)) : null;

    if (employeeAsync != null) {
      employeeAsync.whenData(_populate);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Modifier l'employé" : 'Nouvel employé'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Symbols.person_off), onPressed: _deactivate),
        ],
      ),
      body: (employeeAsync != null && employeeAsync.isLoading)
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _firstNameController,
                      label: 'Prénom',
                      validator: (v) => Validators.required(v, field: 'Le prénom'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _lastNameController,
                      label: 'Nom',
                      validator: (v) => Validators.required(v, field: 'Le nom'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Mot de passe temporaire',
                        obscureText: true,
                        validator: Validators.password,
                      ),
                    ],
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _positionController,
                      label: 'Poste (optionnel)',
                    ),
                    const SizedBox(height: 16),
                    rolesAsync.when(
                      loading: () => const LoadingIndicator(),
                      error: (e, _) => const Text('Impossible de charger les rôles.'),
                      data: (roles) => DropdownButtonFormField<String>(
                        initialValue: _selectedRoleId,
                        decoration: const InputDecoration(labelText: 'Rôle'),
                        items: roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                        onChanged: (v) => setState(() => _selectedRoleId = v),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text('Compte actif'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 24),
                    CustomButton(
                      label: _isEditing ? 'Enregistrer' : "Créer l'employé",
                      isLoading: isSubmitting,
                      onPressed: isSubmitting ? null : _submit,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}