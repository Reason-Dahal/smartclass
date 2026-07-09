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

  Future<void> editTeacher({
    required String profileId,
    String? name,
    String? email,
    String? department,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.teachers}/$profileId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (department != null) 'department': department,
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

  Future<void> deactivateTeacher(String profileId) async {
    try {
      await _dio.delete('${ApiConstants.teachers}/$profileId');
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

  Future<void> editStudent({
    required String profileId,
    String? name,
    String? email,
    String? rollNumber,
    String? programId,
    String? batchId,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.students}/$profileId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (rollNumber != null) 'rollNumber': rollNumber,
          if (programId != null) 'programId': programId,
          if (batchId != null) 'batchId': batchId,
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

  Future<void> deactivateStudent(String profileId) async {
    try {
      await _dio.delete('${ApiConstants.students}/$profileId');
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

  Future<void> editProgram({
    required String programId,
    required String name,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.programs}/$programId',
        data: {'name': name},
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

  Future<void> deactivateProgram(String programId) async {
    try {
      await _dio.delete('${ApiConstants.programs}/$programId');
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

  Future<void> reactivateProgram(String programId) async {
    try {
      await _dio.patch(
        '${ApiConstants.programs}/$programId',
        data: {'isActive': true},
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

  Future<List<BatchModel>> getBatchesByProgram(String programId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.programs}/$programId/batches',
      );
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

  Future<void> editBatch({
    required String batchId,
    String? name,
    int? intakeYear,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.programs}/batches/$batchId',
        data: {
          if (name != null) 'name': name,
          if (intakeYear != null) 'intakeYear': intakeYear,
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

  Future<void> deactivateBatch(String batchId) async {
    try {
      await _dio.delete('${ApiConstants.programs}/batches/$batchId');
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

  Future<void> reactivateBatch(String batchId) async {
    try {
      await _dio.patch(
        '${ApiConstants.programs}/batches/$batchId',
        data: {'isActive': true},
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

  //Final Year Report
  Future<void> uploadFinalResults({
    required String programId,
    required int term,
    required List<int> fileBytes,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'programId': programId,
        'term': term.toString(),
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: DioMediaType(
            fileType == 'pdf' ? 'application' : 'application',
            fileType == 'pdf'
                ? 'pdf'
                : 'vnd.openxmlformats-officedocument.wordprocessingml.document',
          ),
        ),
      });

      await _dio.post(
        ApiConstants.finalResults,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
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

  // Add Courses
  Future<void> createCourse({
    required String programId,
    required String teacherId,
    required String subjectName,
    required int term,
    required bool isElective,
  }) async {
    try {
      await _dio.post(
        ApiConstants.courses,
        data: {
          'programId': programId,
          'teacherId': teacherId,
          'subjectName': subjectName,
          'term': term,
          'isElective': isElective,
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

  Future<void> editCourse({
    required String courseId,
    String? subjectName,
    String? teacherId,
    bool? isElective,
    bool? isActive,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.courses}/$courseId',
        data: {
          if (subjectName != null) 'subjectName': subjectName,
          if (teacherId != null) 'teacherId': teacherId,
          if (isElective != null) 'isElective': isElective,
          if (isActive != null) 'isActive': isActive,
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

  Future<void> deactivateCourse(String courseId) async {
    try {
      await _dio.delete('${ApiConstants.courses}/$courseId');
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

  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await _dio.get(ApiConstants.courses);
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

  //Evaluation
  Future<Map<String, dynamic>> getEvaluationConfig() async {
    try {
      final response = await _dio.get(ApiConstants.evaluationConfig);
      return response.data['data']['config'] as Map<String, dynamic>;
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

  Future<void> updateEvaluationConfig({
    required int attendanceWeight,
    required int internalExamWeight,
    required int assignmentWeight,
    required int teacherEvaluationWeight,
  }) async {
    try {
      await _dio.patch(
        ApiConstants.evaluationConfig,
        data: {
          'attendanceWeight': attendanceWeight,
          'internalExamWeight': internalExamWeight,
          'assignmentWeight': assignmentWeight,
          'teacherEvaluationWeight': teacherEvaluationWeight,
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

  Future<void> overrideAttendance({
    required String attendanceId,
    required String status,
  }) async {
    try {
      await _dio.patch(
        '/admin/attendance/$attendanceId',
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

  Future<void> overrideMarksheet({
    required String marksheetId,
    required double internalExamMarks,
    required double internalExamTotalMarks,
    required double teacherEvaluationScore,
  }) async {
    try {
      await _dio.patch(
        '/admin/marksheets/$marksheetId',
        data: {
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
}
