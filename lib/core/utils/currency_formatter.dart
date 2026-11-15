import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _standardFormat = NumberFormat('#,##0', 'en_US');

  static String formatUsd(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000.0;
      return '\$${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 2)}M';
    } else if (amount >= 1000) {
      final thousands = amount / 1000.0;
      return '\$${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}k';
    }
    return '\$${_standardFormat.format(amount)}';
  }

  static String formatPkr(double amount) {
    // 1 Crore = 10,000,000 PKR
    // 1 Lac = 100,000 PKR
    if (amount >= 10000000) {
      final crore = amount / 10000000.0;
      return 'PKR ${crore.toStringAsFixed(crore.truncateToDouble() == crore ? 0 : 2)}Cr';
    } else if (amount >= 100000) {
      final lac = amount / 100000.0;
      return 'PKR ${lac.toStringAsFixed(lac.truncateToDouble() == lac ? 0 : 1)}Lac';
    }
    return 'PKR ${_standardFormat.format(amount)}';
  }

  static String format({
    required double usdAmount,
    required double pkrAmount,
    required bool isPkr,
  }) {
    return isPkr ? formatPkr(pkrAmount) : formatUsd(usdAmount);
  }

  static String formatExactUsd(double amount) {
    return '\$${_standardFormat.format(amount.round())}';
  }

  static String formatExactPkr(double amount) {
    return 'PKR ${_standardFormat.format(amount.round())}';
  }
}
