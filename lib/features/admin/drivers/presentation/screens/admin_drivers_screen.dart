import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../deliveries/data/models/admin_delivery_model.dart';
import '../providers/admin_drivers_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  static const _statusLabels = {'AVAILABLE': 'Disponible', 'BUSY': 'Occupé', 'INACTIVE': 'Inactif'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversState = ref.watch(adminDriversListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Livreurs')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateDriverDialog(context, ref),
        child: const Icon(Symbols.person_add_alt, color: Colors.white),
      ),
      body: driversState.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger les livreurs.',
          onRetry: () => ref.invalidate(adminDriversListProvider),
        ),
        data: (drivers) {
          if (drivers.isEmpty) {
            return const EmptyState(icon: Symbols.motorcycle, title: 'Aucun livreur');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _DriverTile(driver: drivers[index]),
          );
        },
      ),
    );
  }

  void _showCreateDriverDialog(BuildContext context, WidgetRef ref) {
    String? selectedEmployeeId;
    final vehicleTypeController = TextEditingController();
    final vehicleNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final employeesAsync = dialogRef.watch(adminEligibleEmployeesProvider);

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Nouveau livreur'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    employeesAsync.when(
                      loading: () => const LoadingIndicator(),
                      error: (e, _) => const Text('Impossible de charger les employés.'),
                      data: (employees) {
                        if (employees.isEmpty) {
                          return const Text('Aucun employé disponible. Créez-en un d\'abord.');
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: selectedEmployeeId,
                          decoration: const InputDecoration(labelText: 'Employé'),
                          items: employees
                              .map((emp) => DropdownMenuItem(value: emp.id, child: Text(emp.fullName)))
                              .toList(),
                          onChanged: (v) => setState(() => selectedEmployeeId = v),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: vehicleTypeController,
                      decoration: const InputDecoration(labelText: 'Type de véhicule (ex: Moto)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: vehicleNumberController,
                      decoration: const InputDecoration(labelText: 'Immatriculation'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
                CustomButton(
                  label: 'Créer',
                  onPressed: () async {
                    if (selectedEmployeeId == null) return;

                    final error = await dialogRef.read(adminDriversListProvider.notifier).create(
                          employeeId: selectedEmployeeId!,
                          vehicleType: vehicleTypeController.text.trim(),
                          vehicleNumber: vehicleNumberController.text.trim(),
                        );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? 'Livreur créé.')),
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

class _DriverTile extends ConsumerWidget {
  final AdminDriverModel driver;

  const _DriverTile({required this.driver});

  Color _statusColor(String status) => switch (status) {
        'AVAILABLE' => AppColors.primary,
        'BUSY' => AppColors.secondary,
        _ => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _statusColor(driver.status).withValues(alpha: 0.12),
            child: Icon(Symbols.motorcycle, color: _statusColor(driver.status)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${driver.vehicleType ?? 'Véhicule non renseigné'}${driver.vehicleNumber != null ? ' · ${driver.vehicleNumber}' : ''}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: driver.status,
            underline: const SizedBox.shrink(),
            items: AdminDriversScreen._statusLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: AppTextStyles.bodySmall)))
                .toList(),
            onChanged: (status) async {
              if (status == null) return;
              final error = await ref.read(adminDriversListProvider.notifier).updateStatus(driver.id, status);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Statut mis à jour.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}