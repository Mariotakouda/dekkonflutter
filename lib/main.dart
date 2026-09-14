import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  // Par défaut, quand la construction d'un widget précis échoue (donnée
  // inattendue, valeur nulle...), Flutter affiche un rectangle gris/rouge
  // vide à sa place — ce qui, pour un widget qui occupe toute une liste ou
  // tout un écran, donne l'impression d'une "page blanche". On remplace ce
  // rendu par défaut par un petit message visible, pour qu'il y ait toujours
  // quelque chose à l'écran plutôt que du vide.
  //
  // Note : ceci ne couvre que les erreurs qui surviennent pendant la
  // construction (build) d'un widget. Une erreur qui survient pendant la
  // phase de mise en page (layout) d'un RenderObject n'est pas couverte par
  // ce mécanisme — voir la protection ajoutée directement dans
  // orders_screen.dart pour ce cas précis.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF4F2),
      child: const Text(
        "Une erreur d'affichage est survenue ici.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB3261E), fontSize: 13),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: DekkonApp(),
    ),
  );
}