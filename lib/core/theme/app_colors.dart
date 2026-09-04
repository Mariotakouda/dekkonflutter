import 'package:flutter/material.dart';

/// Palette DEKKON — basée sur le design system Google Stitch v2
/// "Dekkon Design System" (bleu corporate, voir DESIGN.md fourni par le client).
class AppColors {
  AppColors._();

  // Couleurs principales — Bleu Action (CTA d'achat : "Acheter", "Ajouter au
  // panier", badges, onglet actif de la nav)
  static const Color primary = Color(0xFF0058BE);
  static const Color primaryLight = Color(0xFF2170E4);
  static const Color primaryDark = Color(0xFF00236F); // brand navy — logo, titres
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD8E2FF);
  static const Color onPrimaryContainer = Color(0xFF00236F);

  // Secondaire — Bleu marine confiance (boutons outline, focus, actions
  // secondaires, sécurité/paiement)
  static const Color secondary = Color(0xFF00236F);
  static const Color secondaryLight = Color(0xFF1E3A8A);
  static const Color secondaryDark = Color(0xFF001233);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDCE1FF);
  static const Color onSecondaryContainer = Color(0xFF264191);

  // Texte
  static const Color textPrimary = Color(0xFF121C2A); // on-surface
  static const Color textSecondary = Color(0xFF444651); // on-surface-variant
  static const Color textDisabled = Color(0xFF9AA3B6);

  // Neutres / surfaces
  static const Color background = Color(0xFFF8F9FF);
  static const Color backgroundLightGray = Color(0xFFF9FAFB);
  static const Color backgroundBeige = Color(0xFFF5F5DC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE6EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE9FC);
  static const Color border = Color(0xFFC5C5D3); // outline-variant
  static const Color outline = Color(0xFF757682);
  static const Color divider = Color(0xFFE6EEFF);

  // Sémantiques
  static const Color success = Color(0xFF006E1C);
  static const Color successContainer = Color(0xFF76DA75);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color info = primaryLight;

  // Urgence / promotions
  static const Color promotionYellow = Color(0xFFFFD600);
  static const Color promotionRed = Color(0xFFE63946);

  // États des commandes (mapping direct avec OrderStatus backend)
  static const Color statusPending = Color(0xFF9E9E9E);
  static const Color statusConfirmed = secondaryLight;
  static const Color statusProcessing = primary;
  static const Color statusDelivered = success;
  static const Color statusCancelled = error;

  // Overlay / ombres
  static const Color overlay = Color(0x66000000);
  static const Color shimmerBase = Color(0xFFE8EAED);
  static const Color shimmerHighlight = Color(0xFFF5F6F8);

  /// Ombre "whisper-soft" utilisée par le design system Stitch pour les
  /// cartes et éléments interactifs (rgba(17,24,39,0.05)).
  static const Color ambientShadow = Color(0x0D111827);
}