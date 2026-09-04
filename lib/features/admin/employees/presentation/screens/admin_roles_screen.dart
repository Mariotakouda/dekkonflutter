import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../data/models/admin_employee_model.dart';
import '../providers/admin_employees_provider.dart';

class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(adminRolesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rôles & Permissions')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateRoleDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: rolesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les rôles.',
          onRetry: () => ref.invalidate(adminRolesProvider),
        ),
        data: (roles) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: roles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final role = roles[index];
              return Container(
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
                      color: (role.isSystem ? AppColors.textSecondary : const Color(0xFF5E35B1))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      role.isSystem ? Icons.shield_outlined : Icons.badge_outlined,
                      color: role.isSystem ? AppColors.textSecondary : const Color(0xFF5E35B1),
                      size: 20,
                    ),
                  ),
                  title: Text(role.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${role.usersCount ?? 0} utilisateur(s)${role.isSystem ? ' · Système' : ''}',
                    style: AppTextStyles.caption,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: role.permissions
                            .map((p) => Chip(
                                  label: Text(p.code, style: AppTextStyles.caption),
                                  backgroundColor: AppColors.surfaceContainerLow,
                                  shape: const StadiumBorder(),
                                  side: BorderSide.none,
                                ))
                            .toList(),
                      ),
                    ),
                    if (!role.isSystem)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _showEditRoleDialog(context, ref, role),
                              child: const Text('Modifier'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _showEditPermissionsDialog(context, ref, role),
                              child: const Text('Permissions'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                final error = await ref.read(adminRoleFormProvider.notifier).delete(role.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error ?? 'Rôle supprimé.')),
                                  );
                                }
                              },
                              child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateRoleDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final Set<String> selectedPermissions = {};

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final permissionsAsync = dialogRef.watch(adminPermissionsProvider);

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Nouveau rôle'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code (ex: WAREHOUSE_MANAGER)'),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 12),
                      permissionsAsync.when(
                        loading: () => const LoadingIndicator(),
                        error: (e, _) => const Text('Erreur de chargement.'),
                        data: (permissions) => Column(
                          children: permissions
                              .map((p) => CheckboxListTile(
                                    dense: true,
                                    value: selectedPermissions.contains(p.id),
                                    title: Text(p.name, style: AppTextStyles.bodySmall),
                                    onChanged: (checked) => setState(() {
                                      if (checked == true) {
                                        selectedPermissions.add(p.id);
                                      } else {
                                        selectedPermissions.remove(p.id);
                                      }
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
                CustomButton(
                  label: 'Créer',
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || codeController.text.trim().isEmpty) return;

                    final error = await dialogRef.read(adminRoleFormProvider.notifier).create(
                          name: nameController.text.trim(),
                          code: codeController.text.trim().toUpperCase(),
                          permissionIds: selectedPermissions.toList(),
                        );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? 'Rôle créé.')),
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

  void _showEditRoleDialog(BuildContext context, WidgetRef ref, AdminRoleModel role) {
    final nameController = TextEditingController(text: role.name);
    final descriptionController = TextEditingController(text: role.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          Consumer(
            builder: (context, dialogRef, _) => CustomButton(
              label: 'Enregistrer',
              onPressed: () async {
                final error = await dialogRef.read(adminRoleFormProvider.notifier).update(
                      role.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Rôle mis à jour.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPermissionsDialog(BuildContext context, WidgetRef ref, AdminRoleModel role) {
    final Set<String> selectedPermissions = role.permissions.map((p) => p.id).toSet();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final permissionsAsync = dialogRef.watch(adminPermissionsProvider);

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text('Permissions — ${role.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: permissionsAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => const Text('Erreur de chargement.'),
                  data: (permissions) => SingleChildScrollView(
                    child: Column(
                      children: permissions
                          .map((p) => CheckboxListTile(
                                dense: true,
                                value: selectedPermissions.contains(p.id),
                                title: Text(p.name, style: AppTextStyles.bodySmall),
                                onChanged: (checked) => setState(() {
                                  if (checked == true) {
                                    selectedPermissions.add(p.id);
                                  } else {
                                    selectedPermissions.remove(p.id);
                                  }
                                }),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
                CustomButton(
                  label: 'Enregistrer',
                  onPressed: () async {
                    final error = await dialogRef
                        .read(adminRoleFormProvider.notifier)
                        .syncPermissions(role.id, selectedPermissions.toList());

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? 'Permissions mises à jour.')),
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