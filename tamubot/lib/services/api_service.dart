import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For Android emulator
  static const String baseUrl = 'http://192.168.100.4:3000';
  
  // For physical device testing (your computer's IP)
  // static const String baseUrl = 'http://192.168.1.X:3000';

  static Future<Map<String, dynamic>> sendVoiceCommand(String transcript) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/voice-command'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transcript': transcript}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }
}