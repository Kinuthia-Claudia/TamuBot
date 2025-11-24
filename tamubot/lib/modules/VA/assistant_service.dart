import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantService {
  static const String _baseUrl = "https://colourfully-unrelaxed-jestine.ngrok-free.dev";
  final SupabaseClient _supabase = Supabase.instance.client;

  // Voice transcription
  Future<Map<String, dynamic>> transcribeAudio({
    required String audioUrl,
    required String userId,
  }) async {
    try {
      print('Sending transcription request to: $_baseUrl/transcribe');
      print('Audio URL: $audioUrl');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/transcribe'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'audio_url': audioUrl,
          'user_id': userId,
        }),
      );

      print('Transcription response status: ${response.statusCode}');
      print('Transcription response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Transcription error: $e');
      rethrow;
    }
  }

  // Upload audio to Supabase - FIXED VERSION
  Future<String> uploadAudioToSupabase({
    required File audioFile,
    required String userId,
  }) async {
    try {
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = 'user_$userId/$fileName';

      // Upload file to Supabase storage - this returns a String (file path) on success
      // or throws an exception on failure
      await _supabase.storage
          .from('audio_uploads')
          .upload(filePath, audioFile);

      // Get public URL - this returns a String directly
      final publicUrl = _supabase.storage
          .from('audio_uploads')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }

  // Existing methods
  Future<Map<String, dynamic>> identifyDish({
    required String query,
    required String sessionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/identify-dish'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to identify dish: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInstructions({
    required String sessionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/get-instructions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get instructions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> substituteIngredient({
    required String sessionId,
    required String ingredient,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/substitute-ingredient'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'ingredient': ingredient,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to substitute ingredient: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // New method for full recipe
  Future<Map<String, dynamic>> getFullRecipe({
    required String query,
    required String sessionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/full-recipe'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get full recipe: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Health check method
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}