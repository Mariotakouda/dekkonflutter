import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/addresses_model.dart';
import '../providers/addresses_provider.dart';
import 'address_form_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddressesScreen extends ConsumerWidget {
  final bool selectionMode;

  const AddressesScreen({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesState = ref.watch(addressesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes adresses'), centerTitle: true),
      body: addressesState.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger vos adresses.',
          onRetry: () => ref.invalidate(addressesNotifierProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyState(
              icon: Symbols.location_on,
              title: 'Aucune adresse enregistrée',
              subtitle: 'Ajoutez une adresse pour passer commande.',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddressFormScreen()),
                ),
                icon: const Icon(Symbols.add, size: 18),
                label: const Text('Ajouter une adresse'),
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _AddressTile(
              address: addresses[index],
              selectionMode: selectionMode,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddressFormScreen()),
        ),
        child: const Icon(Symbols.add),
      ),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  final AddressModel address;
  final bool selectionMode;

  const _AddressTile({required this.address, required this.selectionMode});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette adresse ?'),
        content: Text(
          address.isDefault
              ? 'Cette adresse est définie par défaut. Voulez-vous vraiment la supprimer ? Cette action est irréversible.'
              : 'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(addressesNotifierProvider.notifier).remove(address.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de supprimer cette adresse.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: selectionMode ? () => Navigator.of(context).pop(address) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address.recipientName, style: AppTextStyles.h4),
                      const SizedBox(height: 2),
                      Text(address.phone, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('Par défaut', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Symbols.location_on, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${address.district}, ${address.city}',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      Text(address.addressLine,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      if (address.landmarkNote != null && address.landmarkNote!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            address.landmarkNote!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!selectionMode) ...[
              const Divider(height: 24),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AddressFormScreen(existingAddress: address)),
                    ),
                    icon: const Icon(Symbols.edit, size: 18),
                    label: const Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Symbols.delete, size: 18),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
