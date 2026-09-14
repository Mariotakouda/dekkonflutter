/// Empêche qu'une même action de navigation soit déclenchée deux fois de
/// suite trop rapidement (ex: double-tap sur une carte produit).
///
/// Sans ça, deux `context.push()` vers la même route peuvent partir avant
/// que le premier ne soit enregistré par le Navigator, ce qui crée deux
/// pages avec la même clé et fait planter l'app :
/// "Assertion failed ... !keyReservation.contains(key) is not true".
class NavDebounce {
  NavDebounce._();

  static DateTime? _lastCall;

  /// Exécute [action] seulement si aucun appel n'a eu lieu dans les
  /// [window] précédentes (500 ms par défaut, largement suffisant pour
  /// absorber un double-tap sans jamais gêner un utilisateur normal).
  static void run(void Function() action, {Duration window = const Duration(milliseconds: 500)}) {
    final now = DateTime.now();
    if (_lastCall != null && now.difference(_lastCall!) < window) {
      return;
    }
    _lastCall = now;
    action();
  }
}