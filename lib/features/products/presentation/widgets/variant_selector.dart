import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/products_model.dart';

class VariantSelector extends StatelessWidget {
  final List<ProductVariantModel> variants;
  final ProductVariantModel? selected;
  final void Function(ProductVariantModel) onSelect;

  const VariantSelector({
    super.key,
    required this.variants,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Variante', style: AppTextStyles.labelMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = selected?.id == variant.id;
            final isAvailable = variant.inStock;

            return GestureDetector(
              onTap: isAvailable ? () => onSelect(variant) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  variant.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: !isAvailable
                        ? AppColors.textDisabled
                        : isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                    decoration: !isAvailable ? TextDecoration.lineThrough : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}