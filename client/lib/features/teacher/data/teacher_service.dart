import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../models/teacher_models.dart';

class TeacherService {
  final Dio _dio = DioClient.instance;

  // ─── COURSES ─────────────────────────────────────────────────────

  Future<List<TeacherCourseModel>> getMyCourses() async {
    try {
      final response = await _dio.get(ApiConstants.teacherCourses);
      final courses = response.data['data']['courses'] as List;
      return courses.map((e) => TeacherCourseModel.fromJson(e)).toList();
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

  Future<void> toggleEvaluation(String courseId, bool enabled) async {
    try {
      await _dio.patch(
        '/courses/teacher/$courseId/evaluation',
        data: {'evaluationEnabled': enabled},
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

  // ─── ATTENDANCE ──────────────────────────────────────────────────

  Future<List<AttendanceRecordModel>> getAttendance(
    String courseId,
    String date,
  ) async {
    try {
      final response = await _dio.get(
        '/teacher/courses/$courseId/attendance',
        queryParameters: {'date': date},
      );
      final records = response.data['data']['attendance'] as List;
      return records.map((e) => AttendanceRecordModel.fromJson(e)).toList();
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

  Future<void> takeAttendance(
    String courseId,
    String date,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      await _dio.post(
        '/teacher/courses/$courseId/attendance',
        data: {'date': date, 'records': records},
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

  // ─── ASSIGNMENTS ─────────────────────────────────────────────────

  Future<void> createAssignment(
    String courseId, {
    required String title,
    required String description,
    required String dueDate,
  }) async {
    try {
      await _dio.post(
        '/teacher/courses/$courseId/assignments',
        data: {'title': title, 'description': description, 'dueDate': dueDate},
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

  Future<List<SubmissionDetailModel>> getSubmissions(
    String assignmentId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.teacherAssignments}/$assignmentId/submissions',
      );
      final submissions = response.data['data']['submissions'] as List;
      return submissions.map((e) => SubmissionDetailModel.fromJson(e)).toList();
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

  Future<void> gradeSubmission(
    String submissionId, {
    required double grade,
    String? feedback,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.teacherSubmissions}/$submissionId/grade',
        data: {'grade': grade, 'feedback': feedback},
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

  // ─── NOTES ───────────────────────────────────────────────────────

  Future<List<TeacherNoteModel>> getNotes(String courseId) async {
    try {
      final response = await _dio.get('/teacher/courses/$courseId/notes');
      final data = response.data['data'];
      final notes = (data['notes'] ?? []) as List;
      return notes.map((e) => TeacherNoteModel.fromJson(e)).toList();
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

  Future<void> uploadNote(
    String courseId, {
    required String title,
    required String fileUrl,
  }) async {
    try {
      await _dio.post(
        '/teacher/courses/$courseId/notes',
        data: {'title': title, 'fileUrl': fileUrl},
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

  Future<void> uploadMarksheet(
    String courseId, {
    required String studentId,
    required int term,
    required double internalExamMarks,
    required double internalExamTotalMarks,
    required double teacherEvaluationScore,
  }) async {
    try {
      await _dio.post(
        '/teacher/courses/$courseId/marksheets',
        data: {
          'studentId': studentId,
          'term': term,
          'internalExamMarks': internalExamMarks,
          'internalExamTotalMarks': internalExamTotalMarks,
          'teacherEvaluationScore': teacherEvaluationScore,
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

  //Attendance
  Future<List<Map<String, dynamic>>> getCourseStudents(String courseId) async {
    try {
      final response = await _dio.get('/teacher/courses/$courseId/students');
      final students = response.data['data']['students'] as List;
      return students.cast<Map<String, dynamic>>();
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
