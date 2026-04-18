import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../config/api_config.dart';

/// Base API Service - Xử lý tất cả HTTP requests
/// Dùng chung cho tất cả các modules
class ApiService {
  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.get(
        url,
        headers: headers ?? ApiConfig.headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// GET request for bytes (PDF, Excel, etc.)
  Future<Uint8List> getBytes(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.get(
        url,
        headers: headers ?? ApiConfig.headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(
        url,
        headers: headers ?? ApiConfig.headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.put(
        url,
        headers: headers ?? ApiConfig.headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.patch(
        url,
        headers: headers ?? ApiConfig.headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.delete(
        url,
        headers: headers ?? ApiConfig.headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Parse JSON
    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid JSON response');
    }

    // Check status code
    if (statusCode >= 200 && statusCode < 300) {
      return data;
    } else if (statusCode == 401) {
      throw Exception('Unauthorized: ${data['error'] ?? data['message']}');
    } else if (statusCode == 404) {
      throw Exception('Not found: ${data['error'] ?? data['message']}');
    } else if (statusCode >= 500) {
      throw Exception('Server error: ${data['error'] ?? data['message']}');
    } else {
      throw Exception(data['error'] ?? data['message'] ?? 'Request failed');
    }
  }

  /// Upload File (Multipart Request)
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath, {
    required String field,
    Map<String, String>? headers,
    Map<String, String>? fields,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', url);

      // Add Headers
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // Auto detect mime type
      final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
      final mimeTypeData = mimeType.split('/');

      // Add File
      request.files.add(
        await http.MultipartFile.fromPath(
          field,
          filePath,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
        ),
      );

      // Add extra fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
