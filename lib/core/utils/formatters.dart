import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _money = NumberFormat('#,##0.00');

  static String money(num value, {String symbol = 'Ks'}) {
    return '$symbol ${_money.format(value)}';
  }

  static String date(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  static String dateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
  }

  static String invoiceNo(int seq, DateTime now) {
    return 'INV-${DateFormat('yyyyMMdd').format(now)}-${seq.toString().padLeft(4, '0')}';
  }
}
