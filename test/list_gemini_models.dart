// ignore_for_file: avoid_print

import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Load .env
  final file = File('.env');
  if (!file.existsSync()) {
    print('No .env file found');
    return;
  }

  final lines = file.readAsLinesSync();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('No GEMINI_API_KEY found in .env');
    return;
  }

  print('Listing models for key starting with: ${apiKey.substring(0, 5)}...');

  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      print('Available Models:');
      print(response.body);
    } else {
      print('Error Listing Models (${response.statusCode}):');
      print(response.body);
    }
  } catch (e) {
    print('Failed to list models: $e');
  }
}
