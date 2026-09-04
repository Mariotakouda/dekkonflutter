import 'package:flutter/material.dart';
import '../../data/models/products_model.dart';
import 'product_card.dart';

/// Grille 2 colonnes réutilisable — utilisée dans Home (sections horizontales)
/// et dans l'écran catalogue (grille verticale complète).
class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ProductGrid({
    super.key,
    required this.products,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }
}