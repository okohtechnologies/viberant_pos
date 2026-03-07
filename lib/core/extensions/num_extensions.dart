// lib/core/extensions/num_extensions.dart
import 'package:intl/intl.dart';

extension NumExtensions on num {
  // Format as currency with symbol and decimals
  String toCurrency({String symbol = '₵', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(this);
  }

  // Format as number with thousands separator
  String toFormattedNumber() {
    final formatter = NumberFormat('#,###');
    return formatter.format(this);
  }

  // Format as decimal with thousands separator
  String toFormattedDecimal({int decimalDigits = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}');
    return formatter.format(this);
  }

  // Format with specific pattern
  String toFormatted(String pattern) {
    final formatter = NumberFormat(pattern);
    return formatter.format(this);
  }

  // Format percentage
  String toPercentage({int decimalDigits = 1}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}%');
    return formatter.format(this / 100);
  }

  // Format as compact number (1.2K, 3.5M)
  String toCompact() {
    final formatter = NumberFormat.compact();
    return formatter.format(this);
  }

  // Check if number is zero
  bool get isZero => this == 0;

  // Check if number is positive
  bool get isPositive => this > 0;

  // Check if number is negative
  bool get isNegative => this < 0;
}
