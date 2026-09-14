import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Clé SharedPreferences marquant l'écran de bienvenue comme déjà vu.
const String onboardingSeenKey = 'onboarding_seen';

/// Les illustrations du carrousel.
const List<String> _heroImages = [
  'assets/images/illustra1.jpg',
  'assets/images/illustra2.jfif',
  'assets/images/illustra8.png',
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _heroController = PageController(
    initialPage: 1000,
  );

  Timer? _autoSlideTimer;

  // Index réel de la page affichée dans le PageView infini.
  int _currentPage = 1000;

  @override
  void initState() {
    super.initState();

    // Défilement automatique toutes les 3 secondes.
    // Le carrousel continue toujours vers la droite.
    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (!mounted) return;

        _heroController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingSeenKey, true);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight =
                (constraints.maxHeight * 0.42).clamp(180.0, 340.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    // ---------------------------------------------------------
                    // ZONE HERO
                    // ---------------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Stack(
                        children: [
                          // Images sans arrondi.
                          SizedBox(
                            height: heroHeight,
                            width: double.infinity,
                            child: PageView.builder(
                              controller: _heroController,

                              // Nombre suffisamment grand pour donner
                              // l'impression d'un carrousel infini.
                              itemCount: 2000000,

                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },

                              itemBuilder: (context, index) {
                                // On répète les 3 images en boucle.
                                final imageIndex =
                                    index % _heroImages.length;

                                return Image.asset(
                                  _heroImages[imageIndex],
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return Container(
                                      color:
                                          AppColors.surfaceContainerLow,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Symbols.storefront,
                                        size: 64,
                                        color: AppColors.textDisabled,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          // ---------------------------------------------------
                          // INDICATEURS
                          // ---------------------------------------------------
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _heroImages.length,
                                (index) {
                                  // Index réel de l'image actuellement affichée.
                                  final realIndex =
                                      _currentPage % _heroImages.length;

                                  final isActive =
                                      index == realIndex;

                                  return AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 250,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: isActive ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // ---------------------------------------------------
                          // BOUTON PASSER
                          // ---------------------------------------------------
                          Positioned(
                            top: 12,
                            right: 12,
                            child: SafeArea(
                              bottom: false,
                              child: TextButton(
                                onPressed: () async {
                                  await _markSeen();

                                  if (context.mounted) {
                                    context.go(AppRoutes.home);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(
                                    alpha: 0.85,
                                  ),
                                  foregroundColor:
                                      AppColors.primaryDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'Passer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ---------------------------------------------------------
                    // ZONE CONTENU
                    // ---------------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        24,
                        20,
                        24,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Symbols.verified_user,
                              color: AppColors.success,
                              size: 24,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Achetez simplement, où que vous soyez.',
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
                            'Découvrez nos produits, commandez facilement et suivez votre commande en temps réel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ---------------------------------------------------
                          // BOUTON CRÉER UN COMPTE
                          // ---------------------------------------------------
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _markSeen();

                                if (context.mounted) {
                                  context.push(
                                    AppRoutes.auth,
                                    extra: const AuthScreenArgs(
                                      startInLoginMode: false,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Créer un compte',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ---------------------------------------------------
                          // BOUTON SE CONNECTER
                          // ---------------------------------------------------
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await _markSeen();

                                if (context.mounted) {
                                  context.push(
                                    AppRoutes.auth,
                                    extra: const AuthScreenArgs(
                                      startInLoginMode: true,
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    AppColors.primaryDark,
                                side: const BorderSide(
                                  color: AppColors.primaryDark,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
