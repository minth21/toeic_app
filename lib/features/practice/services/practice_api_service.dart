import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/app_constants.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../../../core/services/storage_service.dart';

class PracticeApiService {
  final StorageService _storageService = StorageService();

  Future<List<ExamModel>> getTests({String? difficulty}) async {
    try {
      final token = await _storageService.getToken();

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

  Future<ExamModel> getTestById(String testId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception('Unauthorized');

      final uri = Uri.parse(
        '${AppConstants.baseUrl}/tests/$testId?status=UNLOCKED',
      );

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
          return ExamModel.fromJson(data['test']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load test: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuestionModel>> getQuestionsByPartId(String partId) async {
    try {
      final token = await _storageService.getToken();

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
    int? timeTaken,
  ) async {
    try {
      final token = await _storageService.getToken();
      final userId = await _storageService.getUserId();

      if (token == null) throw Exception('Unauthorized');

      final uri = Uri.parse('${AppConstants.baseUrl}/practice/submit');

      final body = {'userId': userId, 'partId': partId, 'answers': answers};

      if (timeTaken != null) {
        body['timeTaken'] = timeTaken;
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
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
      final token = await _storageService.getToken();
      final userId = await _storageService.getUserId();

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

  Future<Map<String, dynamic>?> getAttemptDetail(String attemptId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final uri = Uri.parse(
        '${AppConstants.baseUrl}/practice/attempt/$attemptId',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> translateWord(
    String word,
    String sentence,
  ) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final uri = Uri.parse('${AppConstants.baseUrl}/ai/translate-word');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'word': word, 'sentence': sentence}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
