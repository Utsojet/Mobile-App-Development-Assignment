class IngredientScaler {
  static final RegExp _amountRegex = RegExp(
    r'^(\d+(?:\.\d+)?|\d+\/\d+)(\s*.*)$',
    caseSensitive: false,
  );

  static String scale(String rawAmount, int servings, {int baseServings = 1}) {
    if (servings <= 0 || servings == baseServings) return rawAmount;
    final trimmed = rawAmount.trim();
    if (trimmed.isEmpty) return rawAmount;

    final match = _amountRegex.firstMatch(trimmed);
    if (match == null) return rawAmount; // Handles non-numeric values like "to taste"

    final numberPart = match.group(1)!;
    final unitPart = match.group(2) ?? '';

    double? baseValue;
    if (numberPart.contains('/')) {
      final fractionParts = numberPart.split('/');
      if (fractionParts.length == 2) {
        final num = double.tryParse(fractionParts[0]);
        final den = double.tryParse(fractionParts[1]);
        if (num != null && den != null && den != 0) {
          baseValue = num / den;
        }
      }
    } else {
      baseValue = double.tryParse(numberPart);
    }

    if (baseValue == null) return rawAmount;

    final scaledValue = (baseValue * servings) / baseServings;

    String formattedNumber;
    if (scaledValue % 1 == 0) {
      formattedNumber = scaledValue.toInt().toString();
    } else {
      formattedNumber = scaledValue.toStringAsFixed(2);
      if (formattedNumber.contains('.')) {
        formattedNumber = formattedNumber.replaceAll(RegExp(r'0+$'), '');
        formattedNumber = formattedNumber.replaceAll(RegExp(r'\.$'), '');
      }
    }

    return '$formattedNumber$unitPart';
  }
}