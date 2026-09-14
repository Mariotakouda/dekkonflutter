import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Puce de filtre "faite maison" (Container + InkWell), en remplacement de
/// [ChoiceChip] du SDK Flutter.
///
/// Pourquoi : `ChoiceChip` (et la famille `RawChip` sous-jacente) déclenche
/// un bug connu de Flutter Web où changer l'état sélectionné d'un chip
/// pendant que le curseur de la souris est dessus fait planter le
/// MouseTracker interne du framework
/// (`Assertion failed ... mouse_tracker.dart:199`). Une fois cette
/// assertion levée en boucle, le rendu de la page peut se figer
/// complètement (page blanche, plus aucun bouton cliquable) — exactement
/// le symptôme observé sur "Mes commandes" et "Catalogue", qui utilisaient
/// tous les deux des `ChoiceChip` pour leurs filtres.
///
/// Ce widget reproduit le même rendu visuel avec des composants standards
/// (`InkWell` + `AnimatedContainer`) qui ne sont pas concernés par ce bug.
class SimpleFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SimpleFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(999));
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.surfaceContainerHigh,
          borderRadius: radius,
          border: selected ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}