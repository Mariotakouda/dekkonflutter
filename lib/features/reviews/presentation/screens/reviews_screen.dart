import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/reviews_provider.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes avis')),
      body: reviewsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(message: 'Impossible de charger vos avis.'),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.star_border,
              title: 'Aucun avis publié',
              subtitle: 'Donnez votre avis après réception d\'une commande.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (review.product != null)
                      Text(review.product!['name'] as String? ?? '', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 18,
                            color: AppColors.secondary,
                          )),
                    ),
                    if (review.comment != null) ...[
                      const SizedBox(height: 8),
                      Text(review.comment!, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}