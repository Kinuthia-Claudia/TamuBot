import 'dart:convert';
import 'package:http/http.dart' as http;

class AssistantService {
  static const String _baseUrl = "https://colourfully-unrelaxed-jestine.ngrok-free.dev";

  // Identify dish and get ingredients
  Future<Map<String, dynamic>> identifyDish({
    required String query,
    required String sessionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/identify-dish'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to identify dish: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get cooking instructions
  Future<Map<String, dynamic>> getInstructions({
    required String sessionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/get-instructions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get instructions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Substitute ingredient
  Future<Map<String, dynamic>> substituteIngredient({
    required String sessionId,
    required String ingredient,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/substitute-ingredient'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'ingredient': ingredient,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to substitute ingredient: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}