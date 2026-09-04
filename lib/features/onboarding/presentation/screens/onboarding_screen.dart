import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Clé SharedPreferences marquant l'écran de bienvenue comme déjà vu, pour
/// ne l'afficher qu'à la toute première ouverture de l'app.
const String onboardingSeenKey = 'onboarding_seen';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingSeenKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        // LayoutBuilder + SingleChildScrollView : le hero garde une hauteur
        // proportionnelle à l'écran (au lieu d'un 340px fixe qui débordait
        // sur les petits écrans), et tout reste scrollable en dernier
        // recours si le contenu ne tient toujours pas (petit téléphone,
        // police système agrandie, etc.).
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight = (constraints.maxHeight * 0.42).clamp(180.0, 340.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // --- Zone hero : photo produits + logo + bouton Passer ---
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          child: SizedBox(
                            height: heroHeight,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/bienvenue.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceContainerLow,
                                alignment: Alignment.center,
                                child: const Icon(Icons.storefront_outlined, size: 64, color: AppColors.textDisabled),
                              ),
                            ),
                          ),
                        ),
                      
                        // Bouton "Passer" — absent de la maquette d'origine, ajouté
                        // pour ne pas obliger l'utilisateur à se connecter/inscrire.
                        Positioned(
                          top: 12,
                          right: 12,
                          child: SafeArea(
                            bottom: false,
                            child: TextButton(
                              onPressed: () async {
                                await _markSeen();
                                if (context.mounted) context.go(AppRoutes.home);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.85),
                                foregroundColor: AppColors.primaryDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                              child: const Text('Passer', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // --- Zone contenu : icône confiance, titre, texte, CTAs ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user, color: AppColors.success, size: 24),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Achetez simplement, partout au Togo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              letterSpacing: -0.2,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Découvrez nos produits, commandez facilement et suivez votre livraison.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 32),

                          // --- CTAs ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _markSeen();
                                if (context.mounted) context.push(AppRoutes.auth, extra: false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: const Text('Créer un compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await _markSeen();
                                if (context.mounted) context.push(AppRoutes.auth, extra: true);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(color: AppColors.primaryDark, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}