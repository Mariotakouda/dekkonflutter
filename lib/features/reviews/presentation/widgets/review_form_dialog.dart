// lib/features/reviews/presentation/widgets/review_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/reviews_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<void> showReviewFormDialog(BuildContext context, {required String orderItemId, required String productName}) {
  return showDialog(
    context: context,
    builder: (_) => ReviewFormDialog(orderItemId: orderItemId, productName: productName),
  );
}

class ReviewFormDialog extends ConsumerStatefulWidget {
  final String orderItemId;
  final String productName;

  const ReviewFormDialog({super.key, required this.orderItemId, required this.productName});

  @override
  ConsumerState<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends ConsumerState<ReviewFormDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(reviewSubmitProvider);

    return AlertDialog(
      title: Text('Évaluer ${widget.productName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    Symbols.star,
                    fill: i < _rating ? 1 : 0,
                    color: AppColors.secondary,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                )),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Votre commentaire (optionnel)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        CustomButton(
          label: 'Publier',
          isLoading: isSubmitting,
          onPressed: () async {
            final error = await ref.read(reviewSubmitProvider.notifier).submit(
                  orderItemId: widget.orderItemId,
                  rating: _rating,
                  comment: _commentController.text.trim(),
                );

            if (!context.mounted) return;

            if (error == null) {
              // Succès : on ferme le dialogue et on informe l'utilisateur.
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Avis publié avec succès.')),
              );
            } else {
              // Échec : on garde le dialogue ouvert pour ne pas perdre la
              // saisie de l'utilisateur, et on affiche l'erreur au-dessus
              // du formulaire (le SnackBar seul passait souvent inaperçu
              // car le dialogue se fermait en même temps).
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            }
          },
        ),
      ],
    );
  }
}
