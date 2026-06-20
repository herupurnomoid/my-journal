import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_analysis_model.dart';

class AIApiService {
  static const String baseUrl = 'https://asia-southeast2-my-journal-8c171.cloudfunctions.net/api/v1';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<MoodAnalysisModel> analyzeMood(String title, String content) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token');
    }

    final url = Uri.parse('$baseUrl/ai/analyze-mood');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Assuming backend returns data inside a "data" object as per typical API,
      // or directly if specified. The request mentioned: "Response Data (data objek):"
      final data = jsonResponse['data'] ?? jsonResponse;
      return MoodAnalysisModel.fromJson(data);
    } else {
      throw Exception('Failed to analyze mood: ${response.statusCode}');
    }
  }

  Future<String> getWeeklyInsights(List<Map<String, String>> journals) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get authentication token');
    }

    final url = Uri.parse('$baseUrl/ai/weekly-insights');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'journals': journals,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;
      return data['weeklySummary'] ?? 'Tidak ada ringkasan.';
    } else {
      throw Exception('Failed to get insights: ${response.statusCode}');
    }
  }
}
