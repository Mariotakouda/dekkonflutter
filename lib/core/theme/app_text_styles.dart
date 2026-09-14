import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typographie DEKKON — Inter, conformément au design system Google Stitch
/// v2 "Dekkon Design System" (voir DESIGN.md).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base =>
      GoogleFonts.inter(color: AppColors.textPrimary);

  // Titres (headline-lg / headline-lg-mobile / headline-md du design system)
  static TextStyle get h1 => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
      );
  static TextStyle get h1Mobile => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
      );
  static TextStyle get h2 => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );
  static TextStyle get h3 => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
  static TextStyle get h4 => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // Corps (body-lg / body-md du design system)
  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );
  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );
  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // Libellés / boutons
  // labelLarge = boutons (SemiBold) ; labelMedium/labelSmall = labels,
  // informations (Medium), conformément à l'échelle typographique du client.
  static TextStyle get labelLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelMedium => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelSmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      );

  // Prix — rôle "price-display" du design system (mis en avant, bleu action)
  static TextStyle get priceLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.01 * 18,
        color: AppColors.primary,
      );
  static TextStyle get priceMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        letterSpacing: 0.01 * 18,
        color: AppColors.primary,
      );
  static TextStyle get priceStrikethrough => _base.copyWith(
        fontSize: 14,
        color: AppColors.textDisabled,
        decoration: TextDecoration.lineThrough,
      );

  // Caption / hints
  static TextStyle get caption =>
      _base.copyWith(fontSize: 11, color: AppColors.textSecondary);
}