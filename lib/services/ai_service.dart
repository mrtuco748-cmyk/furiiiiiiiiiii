import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_config.dart';

/// Servicio central de IA para F.U.R.I.
/// Usa Gemini 1.5 Flash (gratuito, 60 RPM).
/// Todas las llamadas incluyen timeout de 15s.
class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  GenerativeModel? _model;
  bool _ready = false;
  bool _rateLimited = false;
  DateTime _lastError = DateTime.now();

  bool get isReady => _ready;

  void init() {
    final key = geminiApiKey;
    if (key.isEmpty) {
      _ready = false;
      return;
    }
    try {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
      _ready = true;
    } catch (e) { _ready = false; }
  }

  Future<String?> suggest(String prompt) async {
    if (!_ready || _rateLimited) return null;
    if (DateTime.now().difference(_lastError).inSeconds < 5) return null;
    try {
      final response = await _model!.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));
      _rateLimited = false;
      return response.text?.trim();
    } catch (e) {
      if (e.toString().contains('429') || e.toString().contains('rate')) {
        _rateLimited = true;
        Future.delayed(const Duration(seconds: 10), () => _rateLimited = false);
        return null;
      }
      _lastError = DateTime.now();
      return null;
    }
  }

  Future<String?> ask(String question, String context) async {
    return suggest('$context\n\nPregunta: $question\nResponde breve, max 2 líneas.');
  }

  Future<String?> studyTip(int streak, int todaySeconds) async {
    if (streak == 0) return 'Empezá a estudiar 💻';
    if (todaySeconds < 1800) return 'Llevás ${todaySeconds ~/ 60}min hoy, seguí así 🔥';
    return 'Buena racha de $streak días! 📈';
  }

  Future<String?> financeTip(double income, double expenses) async {
    final ratio = income > 0 ? expenses / income : 0;
    if (ratio > 0.8) return 'Gastaron ${(ratio * 100).toStringAsFixed(0)}% de sus ingresos';
    if (expenses > income) return 'Gastos superan ingresos 💸';
    return 'Buen ritmo de ahorro 📈';
  }

  Future<String?> taskTip(int overdue) async {
    if (overdue > 0) return '$overdue tarea(s) vencida(s) ⏰';
    return 'Todo al día ✅';
  }

  Future<String?> galleryTip(int count, int albums) async {
    if (count == 0) return 'Subí tu primera foto 📸';
    return '$count fotos · $albums álbumes';
  }

  Future<String?> calendarTip(int todayCount) async {
    if (todayCount == 0) return 'Día libre 🎉';
    return '$todayCount evento(s) hoy 📅';
  }

  Future<String?> nosotrosTip() async {
    return 'Hoy hace 3 meses que visitaron... 💭';
  }

  Future<String?> boardTip(int elements) async {
    if (elements == 0) return 'Pizarra vacía, creá algo ✏️';
    return '$elements elementos en pizarra 📋';
  }
}
