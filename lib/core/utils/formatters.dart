import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _priceFormat = NumberFormat.decimalPattern(AppConstants.currencyLocale);

  /// Formatte un prix en FCFA sans décimales (ex: 89000 -> "89 000 FCFA").
  static String price(double amount) {
    return '${_priceFormat.format(amount.round())} ${AppConstants.currency}';
  }

  static String priceCompact(double amount) {
    return _priceFormat.format(amount.round());
  }

  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return Formatters.date(date);
  }
}