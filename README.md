# AIChatFlutter — Production-Ready AI Chat Client (Flutter)

Production-ready Flutter приложение для общения с AI через OpenRouter и VseGPT с аналитикой расходов, статистикой использования и современной layered architecture.

Проект разработан как portfolio-level production application.

---

# Features

## AI Chat

- Поддержка OpenRouter.ai и VseGPT.ru
- Выбор моделей
- Отправка и получение сообщений
- Подсчёт токенов
- Подсчёт стоимости сообщений
- Отображение баланса

---

## Settings Screen

Настройка прямо в приложении:

- API key
- Provider selection
- Base URL
- Max tokens
- Temperature

.env file не используется.

---

## Analytics / Statistics

Отслеживание:

- total tokens
- total cost
- model usage
- response times

---

## Expenses Screen

График расходов:

- расходы по дням
- total expenses
- persistent storage
- immutable data model

---

## Production Error Handling

State-driven error system:

- missing API key
- invalid API key
- network errors
- API errors

Без использования exceptions для управления логикой.

---

# Architecture

Используется layered clean architecture:

```
lib/

 api/
   openrouter_client.dart
   → REST API client

 models/
   message.dart
   chat_error.dart
   expenses_data.dart
   → immutable data models

 providers/
   chat_provider.dart
   expenses_provider.dart
   → state management

 repositories/
   expenses_repository.dart
   → business logic layer
   → abstraction between provider and services

 services/
   analytics_service.dart
   database_service.dart
   settings_service.dart
   → persistence layer

 screens/
   chat_screen.dart
   settings_screen.dart
   statistics_screen.dart
   expenses_screen.dart
   → UI layer

 utils/
   safe_parsing.dart
   → safe JSON parsing utilities

 main.dart
   → app entry point
```

---

# Architecture Overview

Layer responsibilities:

UI (screens)
↓
Providers (state)
↓
Repositories (business logic)
↓
Services (data access)
↓
API / Database

Это production architecture pattern.

---

# Tech Stack

- Flutter
- Dart
- Provider
- SQLite
- REST API
- OpenRouter API
- VseGPT API
- Charts
- Clean architecture

---

# Persistence

Локально сохраняется:

- chat history
- settings
- analytics
- expenses
- selected model

---

# Installation

```
git clone https://github.com/GoldenGlimmer/AIChatFlutter.git
cd AIChatFlutter
flutter pub get
flutter run
```

---

# Configuration

Настройка выполняется через Settings Screen.

.env file не требуется.

---

# Supported Platforms

- Windows
- Android
- Linux
- (Flutter multi-platform ready)

---

# Production-level features

- layered architecture
- repository pattern
- provider state management
- immutable models
- persistent storage
- analytics system
- safe parsing layer
- production error handling

---

# Portfolio project

Проект демонстрирует навыки:

- Flutter development
- clean architecture
- REST API integration
- state management
- persistent storage
- analytics systems
- production error handling

---

## Screenshots

### Chat Interface

Общение в режиме реального времени

![chat](assets/screenshots/chat.PNG)

### Model Selection

Возможность выбора моделей

![model_selection](assets/screenshots/model_selection.PNG)

### Usage Statistics

Анализ использования токенов, баланса и моделей.

![statistics](assets/screenshots/statistics.PNG)

### Expense Tracking

Визуализация ежедневных расходов с помощью диаграммы.

![expenses](assets/screenshots/expenses.PNG)

### Settings Screen

Настройка провайдера и управление ключами API.

![settings](assets/screenshots/settings.PNG)

### Error snackbar

Демонстрация ошибки

![error_snackbar](assets/screenshots/error_snackbar.PNG)

# Author

GitHub:
https://github.com/GoldenGlimmer

---

# License

MIT License
