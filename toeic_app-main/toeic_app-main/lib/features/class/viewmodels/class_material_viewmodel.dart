import 'package:flutter/material.dart';
import '../models/class_material.dart';
import '../services/class_api_service.dart';

class ClassMaterialViewModel extends ChangeNotifier {
  final ClassApiService _apiService = ClassApiService();

  List<ClassMaterial> _materials = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClassMaterial> get materials => _materials;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMaterials(String? classId, String? token) async {
    if (classId == null || token == null) {
      _errorMessage = 'Không tìm thấy thông tin lớp học';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getClassMaterials(classId, token);
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _materials = data.map((json) => ClassMaterial.fromJson(json)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Không thể tải tài liệu';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
