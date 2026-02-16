/// Перечисление ошибок чата для state-driven архитектуры
/// 
/// Используется в [ChatProvider] для управления состоянием ошибок
/// и в UI для отображения соответствующих сообщений пользователю.
enum ChatError {
  /// Нет ошибки (начальное состояние)
  none,

  /// API ключ отсутствует или пустой
  apiKeyMissing,

  /// API ключ невалидный (401/403 от сервера)
  invalidApiKey,

  /// Сетевая ошибка (нет подключения к интернету)
  networkError,

  /// Ошибка сервера (5xx статусы и прочие ошибки)
  serverError,
}

/// Расширение для получения пользовательских сообщений об ошибках
extension ChatErrorMessage on ChatError {
  /// Возвращает локализованное сообщение об ошибке для отображения в UI
  String get message {
    switch (this) {
      case ChatError.none:
        return '';
      case ChatError.apiKeyMissing:
        return 'Пожалуйста, введите ваш ключ API в настройках';
      case ChatError.invalidApiKey:
        return 'Введён неправильный API key';
      case ChatError.networkError:
        return 'Ошибка сети. Проверьте подключение к интернету';
      case ChatError.serverError:
        return 'Ошибка сервера. Попробуйте позже';
    }
  }

  /// Возвращает цвет для Snackbar в зависимости от типа ошибки
  /// 
  /// Для информационных ошибок - оранжевый, для критических - красный
  // ignore: unused_element
  int get colorValue {
    switch (this) {
      case ChatError.none:
        return 0xFF4CAF50; // Зеленый
      case ChatError.apiKeyMissing:
        return 0xFFFF9800; // Оранжевый
      case ChatError.invalidApiKey:
        return 0xFFF44336; // Красный
      case ChatError.networkError:
        return 0xFFFF9800; // Оранжевый
      case ChatError.serverError:
        return 0xFFF44336; // Красный
    }
  }
}
