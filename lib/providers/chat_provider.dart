// Импорт библиотеки для работы с JSON
import 'dart:convert';
// Импорт библиотеки для работы с файловой системой
import 'dart:io';
// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';
// Импорт пакета для получения путей к директориям
import 'package:path_provider/path_provider.dart';
// Импорт модели сообщения
import '../models/message.dart';
// Импорт модели ошибок чата
import '../models/chat_error.dart';
// Импорт клиента для работы с API
import '../api/openrouter_client.dart';
// Импорт сервиса для работы с базой данных
import '../services/database_service.dart';
// Импорт сервиса для аналитики
import '../services/analytics_service.dart';
// Импорт сервиса настроек
import '../services/settings_service.dart';
// Импорт провайдера расходов
import 'expenses_provider.dart';

// Основной класс провайдера для управления состоянием чата
class ChatProvider with ChangeNotifier {
  // Сервис настроек
  final SettingsService _settings;
  // Список сообщений чата
  final List<ChatMessage> _messages = [];
  // Логи для отладки
  final List<String> _debugLogs = [];
  // Список доступных моделей
  List<Map<String, dynamic>> _availableModels = [];
  // Текущая выбранная модель
  String? _currentModel;
  // Баланс пользователя
  String _balance = '\$0.00';
  // Флаг загрузки
  bool _isLoading = false;
  // Состояние ошибки чата
  ChatError _error = ChatError.none;
  // Ссылка на ExpensesProvider для обновления расходов
  ExpensesProvider? _expensesProvider;

  /// Создает клиент API или возвращает null если API ключ отсутствует
  /// 
  /// При отсутствии ключа устанавливает состояние ошибки [ChatError.apiKeyMissing]
  OpenRouterClient? _createClientOrNull() {
    final apiKey = _settings.apiKey;

    if (apiKey == null || apiKey.trim().isEmpty) {
      _setError(ChatError.apiKeyMissing);
      return null;
    }

    return OpenRouterClient(
      apiKey: apiKey.trim(),
      baseUrl: _settings.baseUrl,
    );
  }

  // Метод для установки ExpensesProvider
  void setExpensesProvider(ExpensesProvider provider) {
    _expensesProvider = provider;
  }

  // Метод для логирования сообщений
  void _log(String message) {
    // Добавление сообщения в логи с временной меткой
    _debugLogs.add('${DateTime.now()}: $message');
    // Вывод сообщения в консоль
    debugPrint(message);
  }

  // Геттер для получения неизменяемого списка сообщений
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  // Геттер для получения списка доступных моделей
  List<Map<String, dynamic>> get availableModels => _availableModels;
  // Геттер для получения текущей модели
  String? get currentModel => _currentModel;
  // Геттер для получения баланса
  String get balance => _balance;
  // Геттер для получения состояния загрузки
  bool get isLoading => _isLoading;
  // Геттер для получения состояния ошибки
  ChatError get error => _error;

  // Геттер для получения базового URL
  String? get baseUrl => _settings.baseUrl;

  // Конструктор провайдера с внедрением зависимостей
  ChatProvider(this._settings) {
    // Инициализация провайдера
    _initializeProvider();
  }

  /// Устанавливает состояние ошибки и уведомляет слушателей
  void _setError(ChatError error) {
    if (_error == error) return;
    _error = error;
    notifyListeners();
  }

  /// Очищает состояние ошибки
  void clearError() {
    _error = ChatError.none;
    notifyListeners();
  }

  // Метод инициализации провайдера
  Future<void> _initializeProvider() async {
    try {
      if (_settings.apiKey == null ||
          _settings.apiKey!.trim().isEmpty) {
        _log('API key not set, skipping initialization');
        return;
      }

      _log('Initializing provider...');
      await _loadModels();
      await _loadBalance();
      await _loadHistory();
    } catch (e, stackTrace) {
      _log('Error initializing provider: $e');
      _log('Stack trace: $stackTrace');
    }
  }

  // Метод загрузки доступных моделей
  Future<void> _loadModels() async {
    try {
      // Создаем клиент или выходим если API ключ отсутствует
      final client = _createClientOrNull();
      if (client == null) return;

      // Получение списка моделей из API
      _availableModels = await client.getModels();
      // Сортировка моделей по имени по возрастанию
      _availableModels
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      // Установка модели из настроек или первая доступная
      if (_availableModels.isNotEmpty) {
        final savedModel = _settings.model;
        // Проверяем, есть ли сохраненная модель в списке доступных
        final modelExists = _availableModels.any((m) => m['id'] == savedModel);
        _currentModel = modelExists ? savedModel : _availableModels[0]['id'];
      }
      // Уведомление слушателей об изменениях
      notifyListeners();
    } catch (e) {
      // Логирование ошибок загрузки моделей
      _log('Error loading models: $e');
    }
  }

  // Метод загрузки баланса пользователя
  Future<void> _loadBalance() async {
    try {
      // Создаем клиент или выходим если API ключ отсутствует
      final client = _createClientOrNull();
      if (client == null) return;

      // Получение баланса из API
      _balance = await client.getBalance();
      // Уведомление слушателей об изменениях
      notifyListeners();
    } catch (e) {
      // Логирование ошибок загрузки баланса
      _log('Error loading balance: $e');
    }
  }

  // Сервис для работы с базой данных
  final DatabaseService _db = DatabaseService();
  // Сервис для сбора аналитики
  final AnalyticsService _analytics = AnalyticsService();

  // Метод загрузки истории сообщений
  Future<void> _loadHistory() async {
    try {
      // Получение сообщений из базы данных
      final messages = await _db.getMessages();
      // Очистка текущего списка и добавление новых сообщений
      _messages.clear();
      _messages.addAll(messages);
      // Уведомление слушателей об изменениях
      notifyListeners();
    } catch (e) {
      // Логирование ошибок загрузки истории
      _log('Error loading history: $e');
    }
  }

  // Метод сохранения сообщения в базу данных
  Future<void> _saveMessage(ChatMessage message) async {
    try {
      // Сохранение сообщения в базу данных
      await _db.saveMessage(message);
    } catch (e) {
      // Логирование ошибок сохранения сообщения
      _log('Error saving message: $e');
    }
  }

  // Метод отправки сообщения
  Future<void> sendMessage(String content, {bool trackAnalytics = true}) async {
    if (content.trim().isEmpty || _currentModel == null) return;

    // Установка флага загрузки
    _isLoading = true;
    // Уведомление пользователя об изменениях
    notifyListeners();

    try {
      // Обеспечение правильного кодирования сообщения
      content = utf8.decode(utf8.encode(content));

      // Добавление сообщения пользователя
      final userMessage = ChatMessage(
        content: content,
        isUser: true,
        modelId: _currentModel,
      );
      _messages.add(userMessage);
      // Уведомление слушателей об изменениях
      notifyListeners();

      // Сохранение сообщения пользователя
      await _saveMessage(userMessage);

      // Запись времени начала отправки
      final startTime = DateTime.now();

      // Создаем клиент или выходим если API ключ отсутствует
      final client = _createClientOrNull();
      if (client == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Отправка сообщения в API с параметрами из настроек
      final response = await client.sendMessage(
        message: content,
        model: _currentModel!,
        maxTokens: _settings.maxTokens,
        temperature: _settings.temperature,
      );
      // Логирование ответа API
      _log('API Response: $response');

      // Расчет времени ответа
      final responseTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000;

      if (response.containsKey('error')) {
        // Добавление сообщения об ошибке от API (не исключение)
        final errorMessage = ChatMessage(
          content: utf8.decode(utf8.encode('Error: ${response['error']}')),
          isUser: false,
          modelId: _currentModel,
        );
        _messages.add(errorMessage);
        await _saveMessage(errorMessage);
      } else if (response.containsKey('choices') &&
          response['choices'] is List &&
          response['choices'].isNotEmpty &&
          response['choices'][0] is Map &&
          response['choices'][0].containsKey('message') &&
          response['choices'][0]['message'] is Map &&
          response['choices'][0]['message'].containsKey('content')) {
        // Добавление ответа AI
        final aiContent = utf8.decode(utf8.encode(
          response['choices'][0]['message']['content'] as String,
        ));
        // Получение количества использованных токенов (безопасный парсинг int/double)
        final tokensRaw = response['usage']?['total_tokens'];
        final tokens = tokensRaw is int
            ? tokensRaw
            : tokensRaw is double
                ? tokensRaw.toInt()
                : 0;

        // Трекинг аналитики, если включен
        if (trackAnalytics) {
          _analytics.trackMessage(
            model: _currentModel!,
            messageLength: content.length,
            responseTime: responseTime,
            tokensUsed: tokens,
          );
        }

        // Создание и добавление сообщения AI
        // Получение количества токенов из ответа (безопасный парсинг int/double)
        final promptTokensRaw = response['usage']['prompt_tokens'];
        final promptTokens = promptTokensRaw is int
            ? promptTokensRaw
            : promptTokensRaw is double
                ? promptTokensRaw.toInt()
                : 0;

        final completionTokensRaw = response['usage']['completion_tokens'];
        final completionTokens = completionTokensRaw is int
            ? completionTokensRaw
            : completionTokensRaw is double
                ? completionTokensRaw.toInt()
                : 0;

        final totalCost = response['usage']?['total_cost'];

        // Получение тарифов для текущей модели
        final model = _availableModels
            .firstWhere((model) => model['id'] == _currentModel);

        // Расчет стоимости запроса
        final cost = (totalCost == null)
            ? ((promptTokens *
                    (double.tryParse(model['pricing']?['prompt']) ?? 0)) +
                (completionTokens *
                    (double.tryParse(model['pricing']?['completion']) ?? 0)))
            : totalCost;

        // Логирование ответа API
        _log('Cost Response: $cost');

        final aiMessage = ChatMessage(
          content: aiContent,
          isUser: false,
          modelId: _currentModel,
          tokens: tokens,
          cost: cost,
        );
        _messages.add(aiMessage);
        // Сохранение сообщения AI
        await _saveMessage(aiMessage);

        // Обновляем расходы если есть стоимость (безопасный вызов через ?.)
        if (cost > 0) {
          _expensesProvider?.refresh();
        }

        // Обновление баланса после успешного сообщения
        await _loadBalance();
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      // Логирование ошибок отправки сообщения
      _log('Error sending message: $e');

      // Определяем тип ошибки и устанавливаем соответствующее состояние
      final errorString = e.toString();
      if (errorString.contains('INVALID_API_KEY')) {
        _setError(ChatError.invalidApiKey);
      } else if (errorString.contains('SocketException') ||
          errorString.contains('Connection refused') ||
          errorString.contains('Network is unreachable')) {
        _setError(ChatError.networkError);
      } else {
        _setError(ChatError.serverError);
      }

      // Ошибки отображаются только через ChatError state и Snackbar
      // НЕ добавляем errorMessage в чат
    } finally {
      // Сброс флага загрузки
      _isLoading = false;
      // Уведомление слушателей об изменениях
      notifyListeners();
    }
  }

  // Метод установки текущей модели
  Future<void> setCurrentModel(String modelId) async {
    // Установка новой модели
    _currentModel = modelId;
    // Сохранение модели в настройках
    await _settings.setModel(modelId);
    // Уведомление слушателей об изменениях
    notifyListeners();
  }

  // Метод повторной инициализации провайдера (вызывается после сохранения API ключа)
  Future<void> reinitialize() async {
    _log('Reinitializing provider after settings update...');
    await _initializeProvider();
  }

  // Метод очистки истории
  Future<void> clearHistory() async {
    // Очистка списка сообщений
    _messages.clear();
    // Очистка истории в базе данных
    await _db.clearHistory();
    // Очистка данных аналитики
    _analytics.clearData();
    // Уведомление слушателей об изменениях
    notifyListeners();
  }

  // Метод экспорта логов
  Future<String> exportLogs() async {
    // Получение директории для сохранения файла
    final directory = await getApplicationDocumentsDirectory();
    // Генерация имени файла с текущей датой и временем
    final now = DateTime.now();
    final fileName =
        'chat_logs_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.txt';
    // Создание файла
    final file = File('${directory.path}/$fileName');

    // Создание буфера для записи логов
    final buffer = StringBuffer();
    buffer.writeln('=== Debug Logs ===\n');
    // Запись всех логов
    for (final log in _debugLogs) {
      buffer.writeln(log);
    }

    buffer.writeln('\n=== Chat Logs ===\n');
    // Запись времени генерации
    buffer.writeln('Generated: ${now.toString()}\n');

    // Запись всех сообщений
    for (final message in _messages) {
      buffer.writeln('${message.isUser ? "User" : "AI"} (${message.modelId}):');
      buffer.writeln(message.content);
      // Запись количества токенов, если есть
      if (message.tokens != null) {
        buffer.writeln('Tokens: ${message.tokens}');
      }
      // Запись времени сообщения
      buffer.writeln('Time: ${message.timestamp}');
      buffer.writeln('---\n');
    }

    // Запись содержимого в файл
    await file.writeAsString(buffer.toString());
    // Возвращение пути к файлу
    return file.path;
  }

  // Метод экспорта сообщений в формате JSON
  Future<String> exportMessagesAsJson() async {
    // Получение директории для сохранения файла
    final directory = await getApplicationDocumentsDirectory();
    // Генерация имени файла с текущей датой и временем
    final now = DateTime.now();
    final fileName =
        'chat_history_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.json';
    // Создание файла
    final file = File('${directory.path}/$fileName');

    // Преобразование сообщений в JSON
    final List<Map<String, dynamic>> messagesJson =
        _messages.map((message) => message.toJson()).toList();

    // Запись JSON в файл
    await file.writeAsString(jsonEncode(messagesJson));
    // Возвращение пути к файлу
    return file.path;
  }

  String formatPricing(double pricing) {
    if (_settings.apiKey == null || _settings.apiKey!.isEmpty) {
      return pricing.toStringAsFixed(6);
    }
    return OpenRouterClient(
      apiKey: _settings.apiKey!.trim(),
      baseUrl: _settings.baseUrl,
    ).formatPricing(pricing);
  }

  // Метод экспорта истории
  Future<Map<String, dynamic>> exportHistory() async {
    // Получение статистики из базы данных
    final dbStats = await _db.getStatistics();
    // Получение статистики аналитики
    final analyticsStats = _analytics.getStatistics();
    // Получение данных сессий
    final sessionData = _analytics.exportSessionData();
    // Получение эффективности моделей
    final modelEfficiency = _analytics.getModelEfficiency();
    // Получение статистики времени ответа
    final responseTimeStats = _analytics.getResponseTimeStats();
    // Получение статистики длины сообщений
    final messageLengthStats = _analytics.getMessageLengthStats();

    // Возвращение всех данных в виде Map
    return {
      'database_stats': dbStats,
      'analytics_stats': analyticsStats,
      'session_data': sessionData,
      'model_efficiency': modelEfficiency,
      'response_time_stats': responseTimeStats,
      'message_length_stats': messageLengthStats,
    };
  }
}
