// Импорт модели расходов
import '../models/expenses_data.dart';
// Импорт сервиса базы данных
import '../services/database_service.dart';

/// Абстрактный класс репозитория расходов
/// 
/// Определяет контракт для работы с данными о расходах.
/// Использует строго типизированную модель [ExpensesData] для безопасности.
abstract class ExpensesRepository {
  /// Получает ежедневные расходы за указанное количество дней
  /// 
  /// [days] - количество дней для анализа (должно быть > 0)
  /// 
  /// Возвращает [ExpensesData] со списком ежедневных расходов и общей суммой.
  /// При отсутствии данных возвращает [ExpensesData.empty].
  /// 
  /// Выбрасывает исключения:
  /// - [ArgumentError] если days <= 0
  /// - [Exception] при ошибках доступа к данным
  Future<ExpensesData> getDailyExpenses({required int days});
}

/// Реализация репозитория расходов, использующая [DatabaseService]
/// 
/// Конвертирует данные из формата базы данных в строго типизированную
/// модель [ExpensesData] для обеспечения type safety.
class DatabaseExpensesRepository implements ExpensesRepository {
  final DatabaseService _databaseService;

  /// Конструктор с внедрением зависимости [DatabaseService]
  /// 
  /// [databaseService] - опциональный сервис базы данных.
  /// Если не указан, создается новый экземпляр [DatabaseService].
  DatabaseExpensesRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  @override
  Future<ExpensesData> getDailyExpenses({required int days}) async {
    // Валидация входных параметров
    if (days <= 0) {
      throw ArgumentError.value(
        days,
        'days',
        'Количество дней должно быть больше 0',
      );
    }

    // Получаем данные из базы данных
    final rawData = await _databaseService.getDailyExpenses(days: days);

    // Конвертируем Map в типизированную модель ExpensesData
    // При null или пустых данных возвращаем пустой объект
    if (rawData.isEmpty) {
      return ExpensesData.empty;
    }

    try {
      return ExpensesData.fromMap(rawData);
    } on FormatException {
      // Перебрасываем FormatException как есть
      rethrow;
    } catch (e) {
      // Оборачиваем другие исключения с контекстом
      throw Exception('Ошибка конвертации данных расходов: $e');
    }
  }
}
