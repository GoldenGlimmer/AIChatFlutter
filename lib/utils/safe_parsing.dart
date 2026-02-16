/// Утилиты для безопасного парсинга числовых значений
/// Safe parsing utilities for numeric values

/// Безопасно парсит значение в int?
/// Safely parses a value to int?
int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Безопасно парсит значение в double?
/// Safely parses a value to double?
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
