// Импорт пакета для форматирования дат
import 'package:intl/intl.dart';

/// Модель ежедневного расхода
/// 
/// Используется для хранения данных о расходах за конкретный день.
/// Неизменяемая (immutable) для безопасности и предсказуемости.
class DailyExpense {
  /// Дата как DateTime (строгая типизация)
  final DateTime date;
  
  /// Сумма расходов за день
  final double cost;

  /// Конструктор с обязательными именованными параметрами
  const DailyExpense({
    required this.date,
    required this.cost,
  });

  /// Создает DailyExpense из Map
  /// 
  /// [data] - Map с ключами 'date' (String в формате 'YYYY-MM-DD') и 'cost' (num)
  /// Возвращает DailyExpense или выбрасывает FormatException при невалидных данных
  factory DailyExpense.fromMap(Map<String, dynamic> data) {
    final dateValue = data['date'];
    final costValue = data['cost'];
    
    // Проверяем типы данных для безопасности
    if (dateValue is! String) {
      throw FormatException(
        'Invalid date type in DailyExpense: expected String, got ${dateValue.runtimeType}',
      );
    }
    
    // Парсим строку даты в DateTime
    final DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateValue);
    } catch (e) {
      throw FormatException(
        'Invalid date format in DailyExpense: "$dateValue". Expected format: YYYY-MM-DD',
      );
    }
    
    // Конвертируем cost в double (может быть int или double)
    final costDouble = costValue is num 
        ? costValue.toDouble() 
        : throw FormatException(
            'Invalid cost type in DailyExpense: expected num, got ${costValue.runtimeType}',
          );
    
    return DailyExpense(
      date: parsedDate,
      cost: costDouble,
    );
  }

  /// Конвертирует DailyExpense в Map
  /// 
  /// Дата форматируется в строку 'YYYY-MM-DD'
  Map<String, dynamic> toMap() {
    return {
      'date': _dateToString(date),
      'cost': cost,
    };
  }

  /// Форматирует DateTime в строку 'YYYY-MM-DD'
  static String _dateToString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Геттер для получения отформатированной даты для UI
  /// 
  /// Формат: 'dd.MM' (например, '15.02')
  String get formattedDate {
    return DateFormat('dd.MM').format(date);
  }

  /// Геттер для получения полной отформатированной даты
  /// 
  /// Формат: 'dd.MM.yyyy' (например, '15.02.2026')
  String get formattedDateFull {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Создает копию с измененными полями
  DailyExpense copyWith({
    DateTime? date,
    double? cost,
  }) {
    return DailyExpense(
      date: date ?? this.date,
      cost: cost ?? this.cost,
    );
  }

  @override
  String toString() => 'DailyExpense(date: $formattedDateFull, cost: $cost)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyExpense && 
           other.date.year == date.year &&
           other.date.month == date.month &&
           other.date.day == date.day &&
           other.cost == cost;
  }

  @override
  int get hashCode => Object.hash(
        date.year,
        date.month,
        date.day,
        cost,
      );
}

/// Модель данных о расходах
/// 
/// Содержит список ежедневных расходов и общую сумму.
/// Неизменяемая (immutable) для безопасности и предсказуемости.
/// Список daily полностью неизменяем благодаря List.unmodifiable.
class ExpensesData {
  /// Список ежедневных расходов (неизменяемый)
  final List<DailyExpense> daily;
  
  /// Общая сумма расходов
  final double total;

  /// Конструктор с обязательными именованными параметрами
  /// 
  /// [daily] - список ежедневных расходов (копируется как неизменяемый)
  /// [total] - общая сумма расходов
  ExpensesData({
    required List<DailyExpense> daily,
    required this.total,
  }) : daily = List.unmodifiable(daily);

  /// Создает ExpensesData из Map
  /// 
  /// [data] - Map с ключами 'daily' (List) и 'total' (num)
  /// Возвращает ExpensesData или выбрасывает FormatException при невалидных данных
  factory ExpensesData.fromMap(Map<String, dynamic> data) {
    final dailyValue = data['daily'];
    final totalValue = data['total'];
    
    // Проверяем типы данных
    if (dailyValue is! List) {
      throw FormatException(
        'Invalid daily type in ExpensesData: expected List, got ${dailyValue.runtimeType}',
      );
    }
    
    // Конвертируем total в double
    final totalDouble = totalValue is num 
        ? totalValue.toDouble() 
        : throw FormatException(
            'Invalid total type in ExpensesData: expected num, got ${totalValue.runtimeType}',
          );
    
    // Конвертируем список Map в список DailyExpense
    final dailyList = dailyValue.map((item) {
      if (item is! Map<String, dynamic>) {
        throw FormatException(
          'Invalid item type in daily list: expected Map<String, dynamic>, got ${item.runtimeType}',
        );
      }
      return DailyExpense.fromMap(item);
    }).toList();
    
    return ExpensesData(
      daily: dailyList,
      total: totalDouble,
    );
  }

  /// Конвертирует ExpensesData в Map
  Map<String, dynamic> toMap() {
    return {
      'daily': daily.map((e) => e.toMap()).toList(),
      'total': total,
    };
  }

  /// Создает копию с измененными полями
  ExpensesData copyWith({
    List<DailyExpense>? daily,
    double? total,
  }) {
    return ExpensesData(
      daily: daily ?? this.daily,
      total: total ?? this.total,
    );
  }

  /// Возвращает пустой объект ExpensesData
  /// 
  /// Список daily пустой и неизменяемый
  static final ExpensesData empty = ExpensesData(
    daily: const [],
    total: 0.0,
  );

  /// Проверяет, есть ли данные о расходах
  bool get hasData => daily.isNotEmpty || total > 0;

  @override
  String toString() => 'ExpensesData(daily: ${daily.length} items, total: $total)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpensesData && 
           other.total == total && 
           _listEquals(other.daily, daily);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(daily),
        total,
      );

  /// Вспомогательный метод для сравнения списков
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
