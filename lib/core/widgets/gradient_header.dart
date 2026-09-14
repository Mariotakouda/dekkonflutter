import 'package:flutter/material.dart';

/// Dégradé orange -> blanc utilisé en haut de toutes les pages principales
/// (Accueil, Catalogue, Panier, Commandes, Profil) pour une identité
/// visuelle cohérente sur toute l'app. Défini une seule fois ici pour que
/// toutes les pages utilisent exactement la même couleur (et que la nav bar
/// en bas puisse reprendre le même orange — voir scaffold_with_nav_bar.dart).
const kHeaderGradientTop = Color(0xFFFF7A2E);
const kHeaderGradientBottom = Colors.white;

/// Enveloppe [child] (la TopAppBar d'un écran) dans le dégradé orange ->
/// blanc commun à toutes les pages principales, avec des coins arrondis en
/// bas pour un rendu "carte" cohérent partout.
class GradientHeader extends StatelessWidget {
  final Widget child;

  /// Position (0.0 à 1.0) à laquelle le dégradé atteint le blanc. Par
  /// défaut 1.0 (le blanc n'est atteint qu'en tout bas du bandeau).
  final double stopAt;

  const GradientHeader({super.key, required this.child, this.stopAt = 1.0});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [kHeaderGradientTop, kHeaderGradientBottom],
          stops: [0.0, stopAt],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: child,
    );
  }
}