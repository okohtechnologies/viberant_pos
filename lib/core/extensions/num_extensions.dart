// lib/core/extensions/num_extensions.dart
import 'package:intl/intl.dart';

extension NumFormatting on num {
  /// Format as Ghana Cedis — GHS 1,234.56
  String toGHS({int decimalDigits = 2}) {
    return NumberFormat.currency(
      symbol: 'GHS ',
      decimalDigits: decimalDigits,
    ).format(this);
  }

  /// Format as a plain decimal string — 1234.56
  String toDecimal({int decimalDigits = 2}) {
    return toStringAsFixed(decimalDigits);
  }

  /// Format with thousands separator, no symbol — 1,234.56
  String toReadable({int decimalDigits = 2}) {
    return NumberFormat('#,##0.${'0' * decimalDigits}').format(this);
  }

  /// Compact format — 1.2K, 3.4M
  String toCompact() {
    return NumberFormat.compact().format(this);
  }
}

extension IntFormatting on int {
  /// Pluralise a word based on this count.
  /// e.g. 1.pluralise('item') → 'item'
  ///      3.pluralise('item') → 'items'
  String pluralise(String word, {String? plural}) {
    return this == 1 ? word : (plural ?? '${word}s');
  }
}
