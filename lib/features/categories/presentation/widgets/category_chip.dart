import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/categories_model.dart';
import 'package:material_symbols_icons/symbols.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.category, required this.onTap});

  /// Choisit une icône représentative selon le nom de la catégorie —
  /// purement visuel, n'a aucun impact sur les données/la navigation.
  String get _normalizedName {
    var n = category.name.toLowerCase();
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    accents.forEach((accented, plain) => n = n.replaceAll(accented, plain));
    return n;
  }

  IconData get _fallbackIcon {
    final name = _normalizedName;
    if (name.contains('electron') || name.contains('high-tech') || name.contains('hightech')) {
      return Symbols.devices;
    }
    if (name.contains('vehicul') || name.contains('auto') || name.contains('voiture') || name.contains('moto')) {
      return Symbols.directions_car;
    }
    if (name.contains('tel') || name.contains('tablet') || name.contains('phone') || name.contains('smartphone')) {
      return Symbols.phone_iphone;
    }
    if (name.contains('mode') || name.contains('vet') || name.contains('vestimentaire')) {
      return Symbols.checkroom;
    }
    if (name.contains('chaussure') || name.contains('sneaker')) {
      return Symbols.footprint;
    }
    if (name.contains('info') || name.contains('ordinateur') || name.contains('pc') || name.contains('laptop')) {
      return Symbols.laptop_mac;
    }
    if (name.contains('maison') || name.contains('jardin') || name.contains('deco') || name.contains('meuble')) {
      return Symbols.chair;
    }
    if (name.contains('jeu') || name.contains('gaming') || name.contains('console')) {
      return Symbols.sports_esports;
    }
    if (name.contains('sport') || name.contains('fitness') || name.contains('muscu')) {
      return Symbols.fitness_center;
    }
    if (name.contains('beaute') || name.contains('cosmet') || name.contains('parfum') || name.contains('soin')) {
      return Symbols.spa;
    }
    if (name.contains('aliment') || name.contains('epicerie') || name.contains('nourriture') || name.contains('boisson')) {
      return Symbols.restaurant;
    }
    if (name.contains('bijou') || name.contains('montre') || name.contains('accessoire')) {
      return Symbols.diamond;
    }
    if (name.contains('livre') || name.contains('papeterie') || name.contains('bureau')) {
      return Symbols.menu_book;
    }
    if (name.contains('bebe') || name.contains('enfant') || name.contains('jouet')) {
      return Symbols.child_care;
    }
    if (name.contains('animal') || name.contains('animalerie')) {
      return Symbols.pets;
    }
    return Symbols.category;
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