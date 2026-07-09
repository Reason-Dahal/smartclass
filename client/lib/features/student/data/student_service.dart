import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../models/student_models.dart';

class StudentService {
  final Dio _dio = DioClient.instance;

  // ─── ATTENDANCE ──────────────────────────────────────────────────

  Future<List<AttendanceSummary>> getMyAttendance({String? courseId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentAttendance,
        queryParameters: courseId != null ? {'courseId': courseId} : null,
      );
      final summary = response.data['data']['summary'] as List;
      return summary.map((e) => AttendanceSummary.fromJson(e)).toList();
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

  // ─── ASSIGNMENTS ─────────────────────────────────────────────────

  Future<List<AssignmentModel>> getMyAssignments({String? courseId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentAssignments,
        queryParameters: courseId != null ? {'courseId': courseId} : null,
      );
      final assignments = response.data['data']['assignments'] as List;
      return assignments.map((e) => AssignmentModel.fromJson(e)).toList();
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

  Future<void> submitAssignment(
    String assignmentId, {
    String? fileUrl,
    String? fileType,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.studentAssignments}/$assignmentId/submit',
        data: {'fileUrl': fileUrl, 'fileType': fileType},
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

  // V2 — returns grouped assignments by subject for current term
  Future<List<AssignmentGroupModel>> getMyAssignmentsGrouped() async {
    try {
      final response = await _dio.get(ApiConstants.studentAssignments);
      final groups = response.data['data']['groups'] as List? ?? [];
      return groups.map((g) => AssignmentGroupModel.fromJson(g)).toList();
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

  // V2 — soft delete a submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _dio.delete('${ApiConstants.studentSubmissions}/$submissionId');
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

  // ─── NOTES ───────────────────────────────────────────────────────

  Future<NotesResponse> getMyNotes({int? term}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentNotes,
        queryParameters: term != null ? {'term': term} : null,
      );
      return NotesResponse.fromJson(
        response.data['data'] as Map<String, dynamic>,
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

  // ─── MARKSHEETS ──────────────────────────────────────────────────

  Future<List<MarksheetModel>> getMyMarksheets({int? term}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentMarksheets,
        queryParameters: term != null ? {'term': term} : null,
      );
      final marksheets = response.data['data']['marksheets'] as List;
      return marksheets.map((e) => MarksheetModel.fromJson(e)).toList();
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

  // ─── EVALUATION ──────────────────────────────────────────────────

  Future<EvaluationModel> getEvaluation(String courseId) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentEvaluation,
        queryParameters: {'courseId': courseId},
      );
      return EvaluationModel.fromJson(response.data['data']);
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

  // ─── COURSES ─────────────────────────────────────────────────────

  Future<List<CourseModel>> getMyCourses() async {
    try {
      final response = await _dio.get(ApiConstants.studentCourses);
      final courses = response.data['data']['courses'] as List;
      return courses.map((e) => CourseModel.fromJson(e)).toList();
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

  // ─── Final Result ─────────────────────────────────────────────────────
  Future<List<FinalResultModel>> getMyFinalResults() async {
    try {
      final response = await _dio.get(ApiConstants.studentFinalResults);
      final results = response.data['data']['results'] as List;
      return results.map((e) => FinalResultModel.fromJson(e)).toList();
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

  // ─── NOTIFICATIONS ───────────────────────────────────────────────

  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.studentNotifications);
      final notifications = response.data['data']['notifications'] as List;
      return notifications.map((e) => NotificationModel.fromJson(e)).toList();
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

  Future<void> markNotificationRead(String id) async {
    try {
      await _dio.patch('${ApiConstants.studentNotifications}/$id/read');
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
