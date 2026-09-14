import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Bannière promotionnelle de l'accueil — utilise l'image "accueil"
/// (assets/images/accueil.jpg) en arrière-plan. Le dégradé beige ne couvre
/// que la zone du texte (environ les 45 premiers % de la largeur) et
/// redescend à 0% d'opacité avant d'atteindre l'image, pour qu'elle reste
/// nette et visible sur la partie droite au lieu d'être voilée de gris.
class PromoBanner extends StatelessWidget {
  final VoidCallback? onDiscoverTap;

  const PromoBanner({super.key, this.onDiscoverTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.backgroundBeige,
        boxShadow: AppTheme.ambientShadow,
        image: const DecorationImage(
          image: AssetImage('assets/images/accueil.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Dégradé resserré sur la zone du texte, qui retombe à 0%
          // d'opacité avant l'image : celle-ci reste donc nette, sans voile.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.backgroundBeige.withValues(alpha: 0.95),
                    AppColors.backgroundBeige.withValues(alpha: 0.75),
                    AppColors.backgroundBeige.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.42, 0.62],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Text(
                  'Offre Spéciale',
                  style: AppTextStyles.h1Mobile.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  "Jusqu'à -50% sur l'Électronique",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onDiscoverTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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