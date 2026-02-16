import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;

  static const String _keyMaxTokens = 'max_tokens';
  static const String _keyTemperature = 'temperature';
  static const String _keyBaseUrl = 'base_url';
  static const String _keyModel = 'model';
  static const String _keyApiKey = 'api_key';

  static const int defaultMaxTokens = 1024;
  static const double defaultTemperature = 0.7;
  static const String defaultBaseUrl = 'https://openrouter.ai/api/v1';
  static const String defaultModel = 'openai/gpt-4o-mini';

  SettingsService(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final currentBaseUrl = prefs.getString(_keyBaseUrl);
    if (currentBaseUrl == null || currentBaseUrl.trim().isEmpty) {
      await prefs.setString(_keyBaseUrl, defaultBaseUrl);
    }
    return SettingsService(prefs);
  }

  // ==================== SAFE GETTERS ====================

  int get maxTokens {
    final value = _prefs.get(_keyMaxTokens);

    if (value is int) return value;
    if (value is double) return value.toInt();

    return defaultMaxTokens;
  }

  double get temperature {
    final value = _prefs.get(_keyTemperature);

    if (value is double) return value;
    if (value is int) return value.toDouble();

    return defaultTemperature;
  }

  String get baseUrl {
      final value = _prefs.getString(_keyBaseUrl);
      if (value == null || value.trim().isEmpty) {
        return defaultBaseUrl;
      }
        return value;
  }

  String get model =>
      _prefs.getString(_keyModel) ?? defaultModel;

  String? get apiKey =>
      _prefs.getString(_keyApiKey);

  // ==================== SETTERS ====================

  Future<bool> setMaxTokens(int value) async {
    return await _prefs.setInt(_keyMaxTokens, value);
  }

  Future<bool> setTemperature(double value) async {
    return await _prefs.setDouble(_keyTemperature, value);
  }

  Future<bool> setBaseUrl(String value) async {
    return await _prefs.setString(_keyBaseUrl, value);
  }

  Future<bool> setModel(String value) async {
    return await _prefs.setString(_keyModel, value);
  }

  Future<bool> setApiKey(String value) async {
    return await _prefs.setString(_keyApiKey, value);
  }

  Map<String, dynamic> toMap() {
    return {
      'maxTokens': maxTokens,
      'temperature': temperature,
      'baseUrl': baseUrl,
      'model': model,
      'apiKey': apiKey,
    };
  }
}
