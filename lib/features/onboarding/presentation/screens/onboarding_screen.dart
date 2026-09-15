
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Clé SharedPreferences marquant l'écran de bienvenue comme déjà vu.
const String onboardingSeenKey = 'onboarding_seen';

/// ---------------------------------------------------------------------------
/// MODÈLE D'UNE PAGE D'ONBOARDING
/// ---------------------------------------------------------------------------
class _OnboardingPage {
  final String image;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });
}

/// ---------------------------------------------------------------------------
/// CONTENU DES 3 PAGES
/// ---------------------------------------------------------------------------
const List<_OnboardingPage> _onboardingPages = [
  _OnboardingPage(
    image: 'assets/images/illustra10.jfif',
    title: 'Achetez simplement, où que vous soyez.',
    description:
        'Découvrez nos produits, choisissez ce dont vous avez besoin et commandez facilement depuis votre téléphone.',
  ),
  _OnboardingPage(
    image: 'assets/images/illustra2.jfif',
    title: 'Trouvez tout ce dont vous avez besoin.',
    description:
        'Parcourez notre catalogue et découvrez une large sélection de produits adaptés à vos besoins.',
  ),
  _OnboardingPage(
    image: 'assets/images/illustra8.png',
    title: 'Suivez votre commande en temps réel.',
    description:
        'Suivez facilement l’évolution de votre commande et recevez vos produits en toute tranquillité.',
  ),
];

/// ---------------------------------------------------------------------------
/// ONBOARDING SCREEN
/// ---------------------------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Un seul contrôleur :
  /// l'image + le texte défilent donc ensemble.
  final PageController _pageController = PageController(
    initialPage: 1000,
  );

  Timer? _autoSlideTimer;

  /// Index de la page actuellement affichée.
  int _currentPage = 1000;

  @override
  void initState() {
    super.initState();

    /// -----------------------------------------------------------------------
    /// DÉFILEMENT AUTOMATIQUE
    /// -----------------------------------------------------------------------
    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }

        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// ENREGISTRER QUE L'ONBOARDING A ÉTÉ VU
  /// -------------------------------------------------------------------------
  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      onboardingSeenKey,
      true,
    );
  }

  /// -------------------------------------------------------------------------
  /// PASSER À L'ACCUEIL
  /// -------------------------------------------------------------------------
  Future<void> _skipOnboarding() async {
    await _markSeen();

    if (!mounted) return;

    context.go(AppRoutes.home);
  }

  /// -------------------------------------------------------------------------
  /// ALLER À L'AUTHENTIFICATION
  /// -------------------------------------------------------------------------
  Future<void> _openAuth({
    required bool loginMode,
  }) async {
    await _markSeen();

    if (!mounted) return;

    context.push(
      AppRoutes.auth,
      extra: AuthScreenArgs(
        startInLoginMode: loginMode,
      ),
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();

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
            /// ----------------------------------------------------------------
            /// HAUTEUR DE L'IMAGE
            /// ----------------------------------------------------------------
            final double heroHeight =
                (constraints.maxHeight * 0.42).clamp(
              180.0,
              340.0,
            );

            /// ----------------------------------------------------------------
            /// HAUTEUR DU CONTENU TEXTE
            ///
            /// Le PageView a maintenant une hauteur FIXE.
            /// C'est important pour éviter les erreurs de layout.
            /// ----------------------------------------------------------------
            const double contentHeight = 245.0;

            /// ----------------------------------------------------------------
            /// HAUTEUR TOTALE DU CARROUSEL
            ///
            /// Image + texte.
            /// ----------------------------------------------------------------
            final double carouselHeight =
                heroHeight + contentHeight;

            /// Index réel entre 0, 1 et 2.
            final int realIndex =
                _currentPage % _onboardingPages.length;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    // ==========================================================
                    // CARROUSEL
                    //
                    // IMAGE + TEXTE SONT DANS LE MÊME PAGEVIEW.
                    // ==========================================================
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 24,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: carouselHeight,
                        child: PageView.builder(
                          controller: _pageController,

                          /// Carrousel quasi-infini.
                          itemCount: 2000000,

                          /// Mise à jour de l'indicateur.
                          onPageChanged: (index) {
                            if (!mounted) return;

                            setState(() {
                              _currentPage = index;
                            });
                          },

                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            /// On répète les 3 pages.
                            final int pageIndex =
                                index % _onboardingPages.length;

                            final _OnboardingPage page =
                                _onboardingPages[pageIndex];

                            return Column(
                              children: [
                                // =================================================
                                // IMAGE
                                // =================================================
                                SizedBox(
                                  width: double.infinity,
                                  height: heroHeight,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // -------------------------------------------
                                      // IMAGE
                                      // -------------------------------------------
                                      Image.asset(
                                        page.image,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,

                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color: AppColors
                                                .surfaceContainerLow,
                                            alignment:
                                                Alignment.center,
                                            child: const Icon(
                                              Symbols.storefront,
                                              size: 64,
                                              color: AppColors
                                                  .textDisabled,
                                            ),
                                          );
                                        },
                                      ),

                                      // -------------------------------------------
                                      // INDICATEURS
                                      // -------------------------------------------
                                      Positioned(
                                        bottom: 14,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              List.generate(
                                            _onboardingPages.length,
                                            (indicatorIndex) {
                                              final bool isActive =
                                                  indicatorIndex ==
                                                      realIndex;

                                              return AnimatedContainer(
                                                duration:
                                                    const Duration(
                                                  milliseconds: 250,
                                                ),
                                                curve:
                                                    Curves.easeInOut,
                                                margin:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal: 3,
                                                ),
                                                width: isActive
                                                    ? 20
                                                    : 6,
                                                height: 6,
                                                decoration:
                                                    BoxDecoration(
                                                  color: isActive
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withValues(
                                                          alpha: 0.5,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    999,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      // -------------------------------------------
                                      // BOUTON PASSER
                                      // -------------------------------------------
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: TextButton(
                                          onPressed:
                                              _skipOnboarding,
                                          style:
                                              TextButton.styleFrom(
                                            backgroundColor:
                                                Colors.white
                                                    .withValues(
                                              alpha: 0.85,
                                            ),
                                            foregroundColor:
                                                AppColors
                                                    .primaryDark,
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                999,
                                              ),
                                            ),
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Passer',
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // =================================================
                                // TEXTE
                                //
                                // IMPORTANT :
                                // Le texte est dans le même PageView que
                                // l'image.
                                // Il glisse donc exactement en même temps.
                                // =================================================
                                SizedBox(
                                  height: contentHeight,
                                  width: double.infinity,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      20,
                                      22,
                                      20,
                                      10,
                                    ),
                                    child: Column(
                                      children: [
                                        // ---------------------------------------
                                        // ICÔNE
                                        // ---------------------------------------
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Symbols.verified_user,
                                            color:
                                                AppColors.success,
                                            size: 24,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 10,
                                        ),

                                        // ---------------------------------------
                                        // TITRE
                                        // ---------------------------------------
                                        Text(
                                          page.title,
                                          textAlign:
                                              TextAlign.center,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight:
                                                FontWeight.w700,
                                            height: 1.2,
                                            letterSpacing: -0.2,
                                            color: AppColors
                                                .primaryDark,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        // ---------------------------------------
                                        // DESCRIPTION
                                        // ---------------------------------------
                                        Text(
                                          page.description,
                                          textAlign:
                                              TextAlign.center,
                                          maxLines: 3,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.4,
                                            color: AppColors
                                                .textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // ==========================================================
                    // BOUTONS FIXES
                    //
                    // Ils ne défilent PAS avec les pages.
                    // ==========================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        24,
                      ),
                      child: Column(
                        children: [
                          // ======================================================
                          // CRÉER UN COMPTE
                          // ======================================================
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _openAuth(
                                  loginMode: false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape:
                                    RoundedRectangleBorder(
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

                          const SizedBox(
                            height: 12,
                          ),

                          // ======================================================
                          // SE CONNECTER
                          // ======================================================
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                _openAuth(
                                  loginMode: true,
                                );
                              },
                              style:
                                  OutlinedButton.styleFrom(
                                foregroundColor:
                                    AppColors.primaryDark,
                                side: const BorderSide(
                                  color:
                                      AppColors.primaryDark,
                                  width: 2,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape:
                                    RoundedRectangleBorder(
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
