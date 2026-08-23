abstract final class GameFormatters {
  static String compactCurrency(double value) {
    final absoluteValue = value.abs();
    final sign = value < 0 ? '-' : '';
    if (absoluteValue >= 1000000000) {
      return '$sign£${(absoluteValue / 1000000000).toStringAsFixed(1)}bn';
    }
    if (absoluteValue >= 1000000) {
      return '$sign£${(absoluteValue / 1000000).toStringAsFixed(1)}m';
    }
    if (absoluteValue >= 1000) {
      return '$sign£${(absoluteValue / 1000).toStringAsFixed(0)}k';
    }
    return '$sign£${absoluteValue.toStringAsFixed(0)}';
  }

  static String currency(double value) {
    final rounded = value.round().abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < rounded.length; index++) {
      if (index > 0 && (rounded.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(rounded[index]);
    }
    return '${value < 0 ? '-' : ''}£$buffer';
  }
}
