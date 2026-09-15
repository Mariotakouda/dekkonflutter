
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Bannière promotionnelle de l'accueil.
///
/// L'image prend toute la largeur disponible de l'écran,
/// sans marge horizontale et sans coins arrondis.
///
/// Le dégradé beige reste concentré sur la partie gauche
/// afin de garantir une bonne lisibilité du texte tout en
/// conservant l'image nette sur la partie droite.
class PromoBanner extends StatelessWidget {
  final VoidCallback? onDiscoverTap;

  const PromoBanner({
    super.key,
    this.onDiscoverTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ==============================================================
      // DIMENSIONS
      // ==============================================================
      // L'image occupe toute la largeur disponible.
      width: double.infinity,
      height: 200,

      decoration: BoxDecoration(
        color: AppColors.backgroundBeige,

        // Ombre légère conservée.
        boxShadow: AppTheme.ambientShadow,

        image: const DecorationImage(
          image: AssetImage('assets/images/banier1.jfif'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),

      // Pas de borderRadius.
      // Pas de clipBehavior nécessaire.

      child: Stack(
        children: [
          // ============================================================
          // DÉGRADÉ
          // ============================================================
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.backgroundBeige.withValues(
                      alpha: 0.95,
                    ),
                    AppColors.backgroundBeige.withValues(
                      alpha: 0.75,
                    ),
                    AppColors.backgroundBeige.withValues(
                      alpha: 0.0,
                    ),
                  ],
                  stops: const [
                    0.0,
                    0.42,
                    0.62,
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // CONTENU
          // ============================================================
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ========================================================
                // BADGE PROMOTION
                // ========================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.promotionYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-20%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ========================================================
                // TITRE
                // ========================================================
                Text(
                  'Offre Spéciale',
                  style: AppTextStyles.h1Mobile.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                // ========================================================
                // DESCRIPTION
                // ========================================================
                Text(
                  "Jusqu'à -50% sur l'Électronique",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                // ========================================================
                // BOUTON
                // ========================================================
                ElevatedButton(
                  onPressed: onDiscoverTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    shape: const StadiumBorder(),
                    elevation: 2,
                  ),
                  child: Text(
                    'Découvrir',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
