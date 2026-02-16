// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';

// Экран настроек приложения
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Состояние экрана настроек
class _SettingsScreenState extends State<SettingsScreen> {
  // Контроллеры для текстовых полей
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();

  // Значения настроек
  double _maxTokens = 1000;
  double _temperature = 0.7;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  // Загрузка настроек из SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Загружаем из SharedPreferences, по умолчанию пустые(кроме base_url) значения
      _apiKeyController.text = prefs.getString('api_key') ?? '';
      _baseUrlController.text = prefs.getString('base_url') ?? 'https://openrouter.ai/api/v1';
      _maxTokens = prefs.getDouble('max_tokens') ?? 1000;
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _isLoading = false;
    });
  }

  // Сохранение настроек в SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('api_key', _apiKeyController.text.trim());
    await prefs.setString('base_url', _baseUrlController.text.trim());
    await prefs.setDouble('max_tokens', _maxTokens);
    await prefs.setDouble('temperature', _temperature);

    // Переинициализируем ChatProvider с новыми настройками
    if (mounted) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.reinitialize();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сохранены', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text(
          'Настройки',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Секция API настроек
                  _buildSectionTitle('API Настройки'),
                  const SizedBox(height: 12),

                  // Поле API ключа
                  _buildTextField(
                    label: 'API Key',
                    controller: _apiKeyController,
                    obscureText: true,
                    hintText: 'Введите API ключ',
                  ),
                  const SizedBox(height: 16),

                  // Поле Base URL
                  _buildTextField(
                    label: 'Base URL',
                    controller: _baseUrlController,
                    hintText: 'https://openrouter.ai/api/v1 / https://api.vsetgpt.ru/v1',
                  ),

                  const SizedBox(height: 24),

                  // Секция параметров модели
                  _buildSectionTitle('Параметры модели'),
                  const SizedBox(height: 12),

                  // Слайдер Max Tokens
                  _buildSlider(
                    label: 'Max Tokens',
                    value: _maxTokens,
                    min: 256,
                    max: 4096,
                    divisions: 15,
                    onChanged: (value) => setState(() => _maxTokens = value),
                    valueLabel: _maxTokens.round().toString(),
                  ),

                  const SizedBox(height: 16),

                  // Слайдер Temperature
                  _buildSlider(
                    label: 'Temperature',
                    value: _temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) => setState(() => _temperature = value),
                    valueLabel: _temperature.toStringAsFixed(1),
                  ),

                  const SizedBox(height: 32),

                  // Кнопка сохранения
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
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

  // Построение текстового поля
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF333333),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Построение слайдера
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              valueLabel,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: const Color(0xFF1A73E8),
          inactiveColor: const Color(0xFF424242),
        ),
      ],
    );
  }
}
