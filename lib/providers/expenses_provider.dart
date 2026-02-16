// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';
// Импорт модели расходов
import '../models/expenses_data.dart';
// Импорт репозитория расходов
import '../repositories/expenses_repository.dart';

/// Состояние загрузки данных о расходах
enum ExpensesLoadingState {
  /// Начальное состояние, данные ещё не загружались
  initial,

  /// Данные загружаются
  loading,

  /// Данные успешно загружены
  loaded,

  /// Произошла ошибка при загрузке
  error,
}

/// Класс состояния расходов
/// 
/// Использует строго типизированную модель [ExpensesData] для хранения данных.
class ExpensesState {
  /// Текущее состояние загрузки
  final ExpensesLoadingState loadingState;

  /// Данные о расходах (типизированная модель)
  final ExpensesData data;

  /// Сообщение об ошибке (если есть)
  final String? errorMessage;

  /// Конструктор состояния
  ExpensesState({
    this.loadingState = ExpensesLoadingState.initial,
    ExpensesData? data,
    this.errorMessage,
  }) : data = data ?? ExpensesData.empty;

  /// Создаёт копию состояния с изменёнными полями
  ExpensesState copyWith({
    ExpensesLoadingState? loadingState,
    ExpensesData? data,
    String? errorMessage,
  }) {
    return ExpensesState(
      loadingState: loadingState ?? this.loadingState,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Геттер для получения списка ежедневных расходов
  List<DailyExpense> get dailyExpenses => data.daily;

  /// Геттер для получения общей суммы расходов
  double get totalExpenses => data.total;

  /// Проверяет, есть ли данные о расходах
  bool get hasData => data.hasData;
}

/// Провайдер для управления состоянием расходов
/// 
/// Использует [ExpensesRepository] для получения данных и
/// строго типизированную модель [ExpensesData] для хранения.
class ExpensesProvider extends ChangeNotifier {
  final ExpensesRepository _repository;

  /// Текущее состояние
  ExpensesState _state = ExpensesState();

  /// Количество дней для анализа (по умолчанию 30)
  int _analysisDays = 30;

  /// Конструктор с внедрением зависимости репозитория
  ExpensesProvider({required ExpensesRepository repository})
      : _repository = repository;

  /// Геттер для получения текущего состояния
  ExpensesState get state => _state;

  /// Геттер для получения текущего количества дней анализа
  int get analysisDays => _analysisDays;

  /// Геттер для получения данных о расходах
  ExpensesData get expensesData => _state.data;

  /// Устанавливает количество дней для анализа и перезагружает данные
  Future<void> setAnalysisDays(int days) async {
    if (days != _analysisDays && days > 0) {
      _analysisDays = days;
      await loadExpenses();
    }
  }

  /// Загружает данные о расходах из репозитория
  Future<void> loadExpenses() async {
    // Устанавливаем состояние загрузки, сохраняя текущие данные
    _state = _state.copyWith(loadingState: ExpensesLoadingState.loading);
    notifyListeners();

    try {
      final data = await _repository.getDailyExpenses(days: _analysisDays);

      _state = _state.copyWith(
        loadingState: ExpensesLoadingState.loaded,
        data: data,
        errorMessage: null,
      );
    } on ArgumentError catch (e) {
      // Обработка ошибок валидации параметров
      _state = _state.copyWith(
        loadingState: ExpensesLoadingState.error,
        errorMessage: 'Некорректные параметры: ${e.message}',
      );
    } on FormatException catch (e) {
      // Обработка ошибок формата данных
      _state = _state.copyWith(
        loadingState: ExpensesLoadingState.error,
        errorMessage: 'Ошибка формата данных: ${e.message}',
      );
    } catch (e, stackTrace) {
      // Обработка всех остальных ошибок с логированием stackTrace
      debugPrint('Error loading expenses: $e');
      debugPrint('Stack trace: $stackTrace');

      _state = _state.copyWith(
        loadingState: ExpensesLoadingState.error,
        errorMessage: 'Ошибка загрузки данных: $e',
      );
    } finally {
      notifyListeners();
    }
  }

  /// Принудительно обновляет данные (вызывается после отправки сообщения)
  /// 
  /// Если данные уже были загружены, обновляет их без показа loading.
  /// При ошибке логирует проблему, но не меняет состояние UI.
  Future<void> refresh() async {
    // Если данные ещё не были загружены, выполняем полную загрузку
    if (_state.loadingState != ExpensesLoadingState.loaded) {
      await loadExpenses();
      return;
    }

    // Сохраняем текущие данные, чтобы UI не показывал loading при обновлении
    try {
      final data = await _repository.getDailyExpenses(days: _analysisDays);

      _state = _state.copyWith(
        data: data,
        errorMessage: null,
      );
      notifyListeners();
    } catch (e, stackTrace) {
      // При ошибке обновления логируем проблему со stackTrace
      debugPrint('Error refreshing expenses: $e');
      debugPrint('Stack trace: $stackTrace');
      // Не меняем состояние UI при ошибке обновления
    }
  }

  /// Сбрасывает состояние к начальному
  void reset() {
    _state = ExpensesState();
    notifyListeners();
  }
}
