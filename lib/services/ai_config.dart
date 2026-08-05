import 'package:flutter_dotenv/flutter_dotenv.dart';

String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
