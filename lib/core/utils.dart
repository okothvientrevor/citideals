import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _comma = NumberFormat('#,##0', 'en_US');

/// Returns "UGX 2,500,000"
String formatUGX(num amount) => 'UGX ${_comma.format(amount)}';

/// Strips commas and returns a raw digits string for parsing.
String stripCommas(String value) => value.replaceAll(',', '');

/// TextInputFormatter that reformats digits with comma thousands separators.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = _comma.format(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
