import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_US', symbol: r'$');
final _day = DateFormat('d MMM y', 'es');
final _month = DateFormat('MMMM y', 'es');

String formatMoney(double value) => _money.format(value);

String formatBillingDay(DateTime value) => _day.format(value);

/// "Octubre 2026".
String formatBillingMonth(DateTime value) {
  final text = _month.format(value);
  return text[0].toUpperCase() + text.substring(1);
}
