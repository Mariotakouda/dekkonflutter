import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/categories_model.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.category, required this.onTap});

  /// Choisit une icône représentative selon le nom de la catégorie —
  /// purement visuel, n'a aucun impact sur les données/la navigation.
  IconData get _fallbackIcon {
    final name = category.name.toLowerCase();
    if (name.contains('tél') || name.contains('tel') || name.contains('tablet') || name.contains('phone')) {
      return Icons.phone_iphone_outlined;
    }
    if (name.contains('mode') || name.contains('vêt') || name.contains('vet')) {
      return Icons.checkroom_outlined;
    }
    if (name.contains('info') || name.contains('ordinateur') || name.contains('pc')) {
      return Icons.laptop_mac_outlined;
    }
    if (name.contains('maison') || name.contains('jardin')) {
      return Icons.thermostat_outlined;
    }
    if (name.contains('jeu') || name.contains('gaming')) {
      return Icons.sports_esports_outlined;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: category.imageUrl != null
                  ? CachedNetworkImage(imageUrl: category.imageUrl!, fit: BoxFit.cover)
                  : Icon(_fallbackIcon, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}