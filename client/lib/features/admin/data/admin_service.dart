import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../models/admin_models.dart';

class AdminService {
  final Dio _dio = DioClient.instance;

  // ─── TEACHERS ────────────────────────────────────────────────────

  Future<List<AdminUserModel>> getTeachers() async {
    try {
      final response = await _dio.get(ApiConstants.teachers);
      final teachers = response.data['data']['teachers'] as List;
      return teachers.map((e) => AdminUserModel.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  Future<void> createTeacher({
    required String name,
    required String email,
    required String department,
  }) async {
    try {
      await _dio.post(
        ApiConstants.teachers,
        data: {'name': name, 'email': email, 'department': department},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  // ─── STUDENTS ────────────────────────────────────────────────────

  Future<List<AdminUserModel>> getStudents() async {
    try {
      final response = await _dio.get(ApiConstants.students);

      final students = response.data['data']['students'] as List;
      return students.map((e) => AdminUserModel.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  Future<void> createStudent({
    required String name,
    required String email,
    required String rollNumber,
    required String programId,
    required String batchId,
  }) async {
    try {
      await _dio.post(
        ApiConstants.students,
        data: {
          'name': name,
          'email': email,
          'rollNumber': rollNumber,
          'programId': programId,
          'batchId': batchId,
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _dio.patch(
        '${ApiConstants.userStatus}/$userId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    try {
      await _dio.patch(
        ApiConstants.resetPassword,
        data: {'email': email, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  // ─── PROGRAMS ────────────────────────────────────────────────────

  Future<List<ProgramModel>> getPrograms() async {
    try {
      final response = await _dio.get(ApiConstants.programs);
      final programs = response.data['data']['programs'] as List;
      return programs.map((e) => ProgramModel.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  Future<void> createProgram({
    required String name,
    required String type,
  }) async {
    try {
      await _dio.post(
        ApiConstants.programs,
        data: {'name': name, 'type': type},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  // ─── BATCHES ─────────────────────────────────────────────────────

  Future<List<BatchModel>> getAllBatches() async {
    try {
      final response = await _dio.get(ApiConstants.batches);
      final batches = response.data['data']['batches'] as List;
      return batches.map((e) => BatchModel.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  Future<void> createBatch({
    required String programId,
    required String name,
    required int intakeYear,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.programs}/$programId/batches',
        data: {'name': name, 'intakeYear': intakeYear},
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  Future<void> promoteBatch(String batchId) async {
    try {
      await _dio.post('${ApiConstants.batches}/$batchId/promote');
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }

  // ─── REPORTS ─────────────────────────────────────────────────────

  Future<SystemReportModel> getReports() async {
    try {
      final response = await _dio.get(ApiConstants.reports);

      return SystemReportModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }
}
