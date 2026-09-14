import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Logo Dekkon (assets/images/logodekkon.png), à utiliser partout où le
/// nom "Dekkon" était affiché en texte (en-têtes, écran de connexion...).
/// Repli propre sur le texte "DEKKON" si l'image n'est pas trouvée, pour ne
/// jamais casser l'affichage.
class DekkonLogo extends StatelessWidget {
  final double height;

  const DekkonLogo({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logodekkon.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        'DEKKON',
        style: AppTextStyles.h1Mobile.copyWith(
          color: AppColors.primary,
          fontSize: height * 0.7,
        ),
      ),
    );
  }
}