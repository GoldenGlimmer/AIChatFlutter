// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт сервиса для работы с базой данных
import '../services/database_service.dart';
// Импорт сервиса для аналитики
import '../services/analytics_service.dart';
// Импорт утилит безопасного парсинга
import '../utils/safe_parsing.dart';

// Экран статистики использования чата
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем AnalyticsService для реактивного обновления
    final analytics = context.watch<AnalyticsService>();
    final stats = analytics.getStatistics();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text(
          'Статистика',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadDatabaseStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            );
          }

          final dbStats = snapshot.data ?? {
            'total_messages': 0,
            'total_tokens': 0,
            'model_usage': {},
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Основные показатели
                _buildSectionTitle('Общая статистика'),
                const SizedBox(height: 12),
                
                // Карточки с основной статистикой
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.message,
                        label: 'Сообщений',
                        value: dbStats['total_messages'].toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.token,
                        label: 'Токенов',
                        value: dbStats['total_tokens'].toString(),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Карточка с балансом
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return _buildStatCard(
                      icon: Icons.account_balance_wallet,
                      label: 'Баланс',
                      value: chatProvider.balance,
                      color: Colors.orange,
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Статистика сессии (реактивная)
                _buildSectionTitle('Статистика сессии'),
                const SizedBox(height: 12),
                
                _buildSessionStats(stats),
                
                const SizedBox(height: 24),
                
                // Использование по моделям
                _buildSectionTitle('Использование по моделям'),
                const SizedBox(height: 12),
                
                _buildModelUsage(dbStats['model_usage'] as Map<String, Map<String, int>>? ?? {}),
              ],
            ),
          );
        },
      ),
    );
  }

  // Загрузка статистики базы данных
  Future<Map<String, dynamic>> _loadDatabaseStatistics() async {
    final dbService = DatabaseService();
    return await dbService.getStatistics();
  }

  // Построение заголовка секции
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Построение карточки статистики
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Построение статистики сессии
  Widget _buildSessionStats(Map<String, dynamic> analyticsStats) {
    final sessionDuration = parseInt(analyticsStats['session_duration']) ?? 0;
    final messagesPerMinute = parseDouble(analyticsStats['messages_per_minute']) ?? 0.0;
    final tokensPerMessage = parseDouble(analyticsStats['tokens_per_message']) ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow('Длительность сессии', '${(sessionDuration / 60).floor()} мин'),
          const Divider(color: Color(0xFF424242), height: 16),
          _buildStatRow('Сообщений в минуту', messagesPerMinute.toStringAsFixed(2)),
          const Divider(color: Color(0xFF424242), height: 16),
          _buildStatRow('Токенов на сообщение', tokensPerMessage.toStringAsFixed(1)),
        ],
      ),
    );
  }

  // Построение строки статистики
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Построение списка использования моделей
  Widget _buildModelUsage(Map<String, Map<String, int>> modelUsage) {
    if (modelUsage.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Нет данных об использовании моделей',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: modelUsage.entries.map((entry) {
        final modelId = entry.key;
        final count = entry.value['count'] ?? 0;
        final tokens = entry.value['tokens'] ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF262626),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                modelId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Сообщений: $count',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  Text(
                    'Токенов: $tokens',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
