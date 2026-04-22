import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/class_model.dart';
import '../models/student_model.dart';

abstract class ClassService {
  Future<List<ClassModel>> fetchStudentClasses(String studentId);
  Future<List<StudentModel>> fetchClassRoster(String classId);
  Future<void> verifyStudent(String studentId);
  Future<void> removeStudent(String classId, String studentId);
}

class HttpClassService implements ClassService {
  HttpClassService({
    String baseUrl = 'https://api.qles.app',
    String? authToken,
    http.Client? client,
  })  : _baseUrl = baseUrl,
        _authToken = authToken,
        _client = client ?? http.Client();

  final String _baseUrl;
  String? _authToken;
  final http.Client _client;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  void _assertSuccess(http.Response response, String context) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message'] as String? ?? response.reasonPhrase ?? 'Unknown error';
      } catch (_) {
        message = response.reasonPhrase ?? 'Unknown error';
      }
      throw ClassServiceException(
        '$context failed with status ${response.statusCode}: $message',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<List<ClassModel>> fetchStudentClasses(String studentId) async {
    final uri = Uri.parse('$_baseUrl/classes').replace(
      queryParameters: {'studentId': studentId},
    );
    final response = await _client.get(uri, headers: _headers);
    _assertSuccess(response, 'fetchStudentClasses');
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StudentModel>> fetchClassRoster(String classId) async {
    final uri = Uri.parse('$_baseUrl/classes/$classId/students');
    final response = await _client.get(uri, headers: _headers);
    _assertSuccess(response, 'fetchClassRoster');
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> verifyStudent(String studentId) async {
    final uri = Uri.parse('$_baseUrl/students/$studentId/verify');
    final response = await _client.patch(uri, headers: _headers);
    _assertSuccess(response, 'verifyStudent');
  }

  @override
  Future<void> removeStudent(String classId, String studentId) async {
    final uri = Uri.parse('$_baseUrl/classes/$classId/students/$studentId');
    final response = await _client.delete(uri, headers: _headers);
    _assertSuccess(response, 'removeStudent');
  }
}

class ClassServiceException implements Exception {
  const ClassServiceException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'ClassServiceException($statusCode): $message';
}
