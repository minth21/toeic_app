import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeApiService {
  Future<List<ExamModel>> getTests({String? difficulty}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Unauthorized');
      }

      final Map<String, dynamic> queryParameters = {'status': 'UNLOCKED'};

      if (difficulty != null) {
        queryParameters['difficulty'] = difficulty;
      }

      final uri = Uri.parse(
        '${AppConstants.baseUrl}/tests',
      ).replace(queryParameters: queryParameters);

      // print('Fetching tests from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> testsJson = data['tests'];
          return testsJson.map((json) => ExamModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load tests');
        }
      } else {
        if (response.statusCode == 401) {
          throw Exception('Unauthorized');
        }
        throw Exception('Failed to load tests: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuestionModel>> getQuestionsByPartId(String partId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('Unauthorized');

      final uri = Uri.parse('${AppConstants.baseUrl}/parts/$partId/questions');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> questionsJson = data['questions'];
          return questionsJson
              .map((json) => QuestionModel.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitPart(
    String partId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      // Retrieve user_id from prefs (assuming it was saved during login)
      // If not saved, we might need to update Auth logic or decode token
      // For now, let's assume it's stored or we use a placeholder if the backend extracts it from token
      // Backend expects 'userId' in body.
      // Let's assume AuthViewModel or LoginScreen saved it.
      // Checking AuthViewModel might be good, but let's try to get it.
      final userId = prefs.getString('user_id');

      if (token == null) throw Exception('Unauthorized');

      // If userId is missing, we might need to handle it.
      // But let's proceed. Backend actually gets userId from token usually, but here we pass it.
      // My backend controller logic: const { userId, partId, answers }: SubmitPartRequest = req.body;
      // So it expects it in body.

      final uri = Uri.parse('${AppConstants.baseUrl}/practice/submit');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'partId': partId,
          'answers': answers,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to submit test');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPartHistory(String partId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        return []; // Return empty if no user info
      }

      final uri = Uri.parse(
        '${AppConstants.baseUrl}/practice/history/$userId/$partId',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
