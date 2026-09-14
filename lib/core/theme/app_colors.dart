import 'package:flutter/material.dart';

/// Palette DEKKON — nouvelle charte "Orange / Noir profond / Blanc cassé"
/// (remplace l'ancien design system bleu corporate Google Stitch v2).
class AppColors {
  AppColors._();

  // Couleurs principales — Orange (boutons, éléments actifs, illustrations,
  // accents, onglet actif de la nav)
  static const Color primary = Color(0xFFF4530C); // Orange principal
  static const Color primaryLight = Color(0xFFF2AB84); // Orange pâle
  static const Color primaryDark = Color(0xFFD45C28); // Orange clair (variante)
  static const Color onPrimary = Color(0xFFFDFBF9);
  static const Color primaryContainer = Color(0xFFFBDDCE);
  static const Color onPrimaryContainer = Color(0xFF181614);

  // Secondaire — Noir profond (fonds de présentation, certains boutons,
  // actions secondaires)
  static const Color secondary = Color(0xFF0A0402); // Noir profond
  static const Color secondaryLight = Color(0xFF181614); // Noir UI
  static const Color secondaryDark = Color(0xFF000000);
  static const Color onSecondary = Color(0xFFFDFBF9);
  static const Color secondaryContainer = Color(0xFFEAE7E5);
  static const Color onSecondaryContainer = Color(0xFF181614);

  // Texte
  static const Color textPrimary = Color(0xFF181614); // Noir UI
  static const Color textSecondary = Color(0xFF777471); // Gris moyen
  static const Color textDisabled = Color(0xFFACA9A5);

  // Neutres / surfaces
  static const Color background = Color(0xFFFDFBF9); // Blanc cassé
  static const Color backgroundLightGray = Color(0xFFF2F0ED);
  static const Color backgroundBeige = Color(0xFFE4E3DF);
  static const Color surface = Color(0xFFFDFBF9);
  static const Color surfaceContainerLow = Color(0xFFF2F0ED);
  static const Color surfaceContainer = Color(0xFFE4E3DF);
  static const Color surfaceContainerHigh = Color(0xFFE8E7E3);
  static const Color border = Color(0xFFE4E3DF); // Gris très clair
  static const Color outline = Color(0xFF777471); // Gris moyen
  static const Color divider = Color(0xFFE4E3DF);

  // Sémantiques
  static const Color success = Color(0xFF35B878); // Vert succès
  static const Color successContainer = Color(0xFFD5EEDF);
  static const Color warning = Color(0xFFD45C28);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFF3D9D8);
  static const Color onError = Color(0xFFFDFBF9);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color info = primaryLight;

  // Urgence / promotions
  static const Color promotionYellow = Color(0xFFF2AB84); // Orange pâle
  static const Color promotionRed = Color(0xFFE63946);

  // États des commandes (mapping direct avec OrderStatus backend)
  static const Color statusPending = Color(0xFF9E9E9E);
  static const Color statusConfirmed = primaryDark;
  static const Color statusProcessing = primary;
  static const Color statusDelivered = success;
  static const Color statusCancelled = error;

  // Overlay / ombres
  static const Color overlay = Color(0x660A0402);
  static const Color shimmerBase = Color(0xFFE4E3DF); // Gris très clair
  static const Color shimmerHighlight = Color(0xFFF3F1EF);

  /// Ombre "whisper-soft" utilisée pour les cartes et éléments interactifs.
  static const Color ambientShadow = Color(0x0D181614);
}