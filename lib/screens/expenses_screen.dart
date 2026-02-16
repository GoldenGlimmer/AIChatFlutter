// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт пакета для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт пакета для построения графиков
import 'package:fl_chart/fl_chart.dart';
// Импорт модели расходов
import '../models/expenses_data.dart';
// Импорт провайдера расходов
import '../providers/expenses_provider.dart';

/// Экран расходов с графиком
///
/// Использует [ExpensesProvider] для получения данных о расходах.
/// UI автоматически обновляется при изменении данных благодаря [Consumer].
class ExpensesScreen extends StatefulWidget {
  /// Конструктор экрана расходов
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

/// Состояние экрана расходов
class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные при первом построении экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpensesProvider>();
      if (provider.state.loadingState == ExpensesLoadingState.initial) {
        provider.loadExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text(
          'Расходы',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          // Кнопка обновления
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<ExpensesProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<ExpensesProvider>(
        builder: (context, provider, child) {
          final state = provider.state;

          // Обработка состояния загрузки
          if (state.loadingState == ExpensesLoadingState.loading &&
              !state.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Обработка состояния ошибки
          if (state.loadingState == ExpensesLoadingState.error &&
              !state.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? 'Ошибка загрузки данных',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadExpenses(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final daily = state.dailyExpenses;
          final total = state.totalExpenses;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Карточка общей суммы расходов
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Расходы за ${provider.analysisDays} дней',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${total.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Заголовок графика
                const Text(
                  'Ежедневные расходы',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // График расходов
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: daily.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет данных',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        )
                      : _buildBarChart(daily),
                ),

                const SizedBox(height: 16),

                // Легенда
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A73E8),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Стоимость запросов',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Построение столбчатого графика
  ///
  /// Использует типизированную модель [DailyExpense] вместо Map для безопасности.
  Widget _buildBarChart(List<DailyExpense> daily) {
    // Находим максимальное значение для масштабирования
    double maxCost = 0;
    for (final item in daily) {
      if (item.cost > maxCost) maxCost = item.cost;
    }
    if (maxCost == 0) maxCost = 1; // Минимальное значение для оси Y

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCost * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF333333),
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = daily[groupIndex];
              return BarTooltipItem(
                '${item.formattedDateFull}\n\$${item.cost.toStringAsFixed(4)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= daily.length) {
                  return const SizedBox.shrink();
                }

                // Показываем дату каждые 5 дней
                if (index % 5 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      daily[index].formattedDate,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '\$${value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxCost / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFF424242),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(daily.length, (index) {
          final cost = daily[index].cost;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: cost,
                color: const Color(0xFF1A73E8),
                width: 6,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
