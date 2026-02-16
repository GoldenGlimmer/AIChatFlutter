// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт пакета для локализации приложения
import 'package:flutter_localizations/flutter_localizations.dart';
// Импорт пакета для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт кастомного провайдера для управления состоянием чата
import 'providers/chat_provider.dart';
// Импорт провайдера расходов
import 'providers/expenses_provider.dart';
// Импорт сервиса настроек
import 'services/settings_service.dart';
// Импорт сервиса аналитики
import 'services/analytics_service.dart';
// Импорт репозитория расходов
import 'repositories/expenses_repository.dart';
// Импорт экранов приложения
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/expenses_screen.dart';

// Виджет для обработки и отлова ошибок в приложении
class ErrorBoundaryWidget extends StatelessWidget {
  // Дочерний виджет, который будет обернут в обработчик ошибок
  final Widget child;

  // Конструктор с обязательным параметром child
  const ErrorBoundaryWidget({super.key, required this.child});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем Builder для создания нового контекста
    return Builder(
      // Функция построения виджета с обработкой ошибок
      builder: (context) {
        // Пытаемся построить дочерний виджет
        try {
          // Возвращаем дочерний виджет, если ошибок нет
          return child;
          // Ловим и обрабатываем ошибки
        } catch (error, stackTrace) {
          // Логируем ошибку в консоль
          debugPrint('Error in ErrorBoundaryWidget: $error');
          // Логируем стек вызовов для отладки
          debugPrint('Stack trace: $stackTrace');
          // Возвращаем MaterialApp с экраном ошибки
          return MaterialApp(
            // Основной экран приложения
            home: Scaffold(
              // Красный фон для экрана ошибки
              backgroundColor: Colors.red,
              // Центрируем содержимое
              body: Center(
                // Добавляем отступы
                child: Padding(
                  // Отступы 16 пикселей со всех сторон
                  padding: const EdgeInsets.all(16.0),
                  // Текст с описанием ошибки
                  child: Text(
                    // Отображаем текст ошибки
                    'Error: $error',
                    // Белый цвет текста
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// Основная точка входа в приложение
void main() async {
  try {
    // Инициализация Flutter биндингов
    WidgetsFlutterBinding.ensureInitialized();

    // Настройка обработки ошибок Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      // Отображение ошибки
      FlutterError.presentError(details);
      // Логирование ошибки
      debugPrint('Flutter error: ${details.exception}');
      // Логирование стека вызовов
      debugPrint('Stack trace: ${details.stack}');
    };



    // Инициализация SharedPreferences и SettingsService
    final settingsService = await SettingsService.create();
    debugPrint('SettingsService initialized');

    // Запуск приложения с обработчиком ошибок
    runApp(ErrorBoundaryWidget(
      child: MyApp(settingsService: settingsService),
    ));
  } catch (e, stackTrace) {
    // Логирование ошибки запуска приложения
    debugPrint('Error starting app: $e');
    // Логирование стека вызовов
    debugPrint('Stack trace: $stackTrace');
    // Запуск приложения с экраном ошибки
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error starting app: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Основной виджет с навигацией (MainScaffold)
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

// Состояние MainScaffold с BottomNavigationBar
class _MainScaffoldState extends State<MainScaffold> {
  // Индекс выбранной вкладки
  int _selectedIndex = 0;

  // Список экранов для навигации
  final List<Widget> _pages = const [
    ChatScreen(),
    StatisticsScreen(),
    ExpensesScreen(),
    SettingsScreen(),
  ];

  // Названия вкладок
  final List<String> _titles = const [
    'Чат',
    'Статистика',
    'Расходы',
    'Настройки',
  ];

  // Иконки вкладок
  final List<IconData> _icons = const [
    Icons.chat_bubble,
    Icons.analytics,
    Icons.show_chart,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF262626),
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: List.generate(_titles.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index],
          );
        }),
      ),
    );
  }
}

// Основной виджет приложения
class MyApp extends StatelessWidget {
  // Сервис настроек
  final SettingsService settingsService;

  // Конструктор с ключом и сервисом настроек
  const MyApp({super.key, required this.settingsService});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем MultiProvider для управления зависимостями
    return MultiProvider(
      providers: [
        // SettingsService как обычный Provider (не ChangeNotifier)
        Provider<SettingsService>.value(value: settingsService),
        // AnalyticsService как ChangeNotifierProvider для реактивности
        ChangeNotifierProvider<AnalyticsService>(
          create: (_) => AnalyticsService(),
        ),
        // ExpensesRepository как обычный Provider
        Provider<ExpensesRepository>(
          create: (_) => DatabaseExpensesRepository(),
        ),
        // ExpensesProvider с внедрением ExpensesRepository
        ChangeNotifierProvider<ExpensesProvider>(
          create: (context) => ExpensesProvider(
            repository: context.read<ExpensesRepository>(),
          ),
        ),
        // ChatProvider с внедрением SettingsService и ExpensesProvider
        ChangeNotifierProvider<ChatProvider>(
          create: (context) {
            try {
              // Создаем экземпляр ChatProvider с SettingsService
              final chatProvider = ChatProvider(context.read<SettingsService>());
              // Устанавливаем связь с ExpensesProvider для обновления расходов
              chatProvider.setExpensesProvider(context.read<ExpensesProvider>());
              return chatProvider;
            } catch (e, stackTrace) {
              // Логирование ошибки создания провайдера
              debugPrint('Error creating ChatProvider: $e');
              // Логирование стека вызовов
              debugPrint('Stack trace: $stackTrace');
              // Повторный выброс исключения
              rethrow;
            }
          },
        ),
      ],
      // Основной виджет MaterialApp
      child: MaterialApp(
        // Настройка поведения прокрутки
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: ScrollBehavior(),
            child: child!,
          );
        },
        // Заголовок приложения
        title: 'AI Chat',
        // Скрытие баннера debug
        debugShowCheckedModeBanner: false,
        // Установка локали по умолчанию (русский)
        locale: const Locale('ru', 'RU'),
        // Поддерживаемые локали
        supportedLocales: const [
          Locale('ru', 'RU'), // Русский
          Locale('en', 'US'), // Английский (США)
        ],
        // Делегаты для локализации
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate, // Локализация Material виджетов
          GlobalWidgetsLocalizations.delegate, // Локализация базовых виджетов
          GlobalCupertinoLocalizations
              .delegate, // Локализация Cupertino виджетов
        ],
        // Настройка темы приложения
        theme: ThemeData(
          // Цветовая схема на основе синего цвета
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, // Основной цвет
            brightness: Brightness.dark, // Темная тема
          ),
          // Использование Material 3
          useMaterial3: true,
          // Цвет фона Scaffold
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          // Настройка темы AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF262626), // Цвет фона
            foregroundColor: Colors.white, // Цвет текста
          ),
          // Настройка темы диалогов
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF333333), // Цвет фона
            titleTextStyle: TextStyle(
              color: Colors.white, // Цвет заголовка
              fontSize: 20, // Размер шрифта
              fontWeight: FontWeight.bold, // Жирный шрифт
              fontFamily: 'Roboto', // Шрифт
            ),
            contentTextStyle: TextStyle(
              color: Colors.white70, // Цвет текста
              fontSize: 16, // Размер шрифта
              fontFamily: 'Roboto', // Шрифт
            ),
          ),
          // Настройка текстовой темы
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              fontFamily: 'Roboto', // Шрифт
              fontSize: 16, // Размер шрифта
              color: Colors.white, // Цвет текста
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Roboto', // Шрифт
              fontSize: 14, // Размер шрифта
              color: Colors.white, // Цвет текста
            ),
          ),
          // Настройка темы кнопок
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // Цвет текста
              textStyle: const TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 14, // Размер шрифта
              ),
            ),
          ),
          // Настройка темы текстовых кнопок
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // Цвет текста
              textStyle: const TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 14, // Размер шрифта
              ),
            ),
          ),
        ),
        // Основной экран приложения с навигацией
        home: const MainScaffold(),
      ),
    );
  }
}
