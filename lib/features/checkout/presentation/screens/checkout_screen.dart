import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../addresses/data/models/addresses_model.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../addresses/presentation/screens/addresses_screen.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/checkout_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  PaymentMethodOption _selectedPayment = PaymentMethodOption.cashOnDelivery;
  final _promoController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(builder: (_) => const AddressesScreen(selectionMode: true)),
    );
    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  Future<void> _submit() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une adresse de livraison.')),
      );
      return;
    }

    final success = await ref.read(checkoutNotifierProvider.notifier).submitOrder(
          addressId: _selectedAddress!.id,
          paymentMethod: _selectedPayment,
          promotionCode: _promoController.text.trim(),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    final checkoutState = ref.read(checkoutNotifierProvider);

    if (success && checkoutState.placedOrder != null) {
      final order = checkoutState.placedOrder!;

      if (_selectedPayment != PaymentMethodOption.cashOnDelivery) {
        final paymentData = await ref.read(checkoutNotifierProvider.notifier).initiatePayment(order.id);

        if (paymentData != null && paymentData['payment_url'] != null) {
          final url = Uri.parse(paymentData['payment_url'] as String);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      }

      if (mounted) {
        context.go('/orders/${order.id}');
        ref.read(checkoutNotifierProvider.notifier).reset();
      }
    } else if (checkoutState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(checkoutState.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final addressesState = ref.watch(addressesNotifierProvider);
    final checkoutState = ref.watch(checkoutNotifierProvider);

    // Pré-sélectionne l'adresse par défaut au premier chargement.
    addressesState.whenData((addresses) {
      if (_selectedAddress == null && addresses.isNotEmpty) {
        final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedAddress = defaultAddress);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Finaliser la commande')),
      body: cartState.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(message: 'Impossible de charger le panier.'),
        data: (cart) {
          if (cart == null || cart.isEmpty) {
            return const Center(child: Text('Votre panier est vide.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adresse de livraison', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                _AddressCard(address: _selectedAddress, onTap: _pickAddress),
                const SizedBox(height: 24),

                Text('Méthode de paiement', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                ...PaymentMethodOption.values.map((method) => _PaymentOption(
                      method: method,
                      selected: _selectedPayment == method,
                      onTap: () => setState(() => _selectedPayment = method),
                    )),
                const SizedBox(height: 24),

                Text('Code promo (optionnel)', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                TextField(
                  controller: _promoController,
                  decoration: const InputDecoration(hintText: 'Entrez un code'),
                ),
                const SizedBox(height: 24),

                Text('Note pour la livraison (optionnel)', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Instructions particulières...'),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Sous-total', value: Formatters.price(cart.subtotal)),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Total',
                        value: Formatters.price(cart.subtotal),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  label: 'Confirmer la commande',
                  onPressed: checkoutState.isSubmitting ? null : _submit,
                  isLoading: checkoutState.isSubmitting,
                  width: double.infinity,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel? address;
  final VoidCallback onTap;

  const _AddressCard({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: address == null
            ? Row(
                children: const [
                  Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Sélectionner une adresse'),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address!.recipientName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text(address!.fullLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                ],
              ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(10),
            color: selected ? AppColors.primary.withValues(alpha: 0.05) : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(method.label, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final style = isBold ? AppTextStyles.priceMedium : AppTextStyles.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
        Text(value, style: style),
      ],
    );
  }
}