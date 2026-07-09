class AttendanceSummary {
  final String courseId;
  final String subjectName;
  final int totalClasses;
  final int present;
  final int absent;
  final int late;
  final double attendancePercentage;

  AttendanceSummary({
    required this.courseId,
    required this.subjectName,
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>? ?? {};
    return AttendanceSummary(
      courseId: course['_id'] ?? '',
      subjectName: course['subjectName'] ?? '',
      totalClasses: json['totalClasses'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      late: json['late'] ?? 0,
      attendancePercentage:
          double.tryParse(json['attendancePercentage'].toString()) ?? 0.0,
    );
  }
}

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String courseId;
  final String subjectName;
  final bool isSubmitted;
  final bool isPastDue;
  final SubmissionModel? submission;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.courseId,
    required this.subjectName,
    required this.isSubmitted,
    required this.isPastDue,
    this.submission,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final course = json['courseId'] as Map<String, dynamic>? ?? {};
    return AssignmentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      courseId: course['_id'] ?? '',
      subjectName: course['subjectName'] ?? '',
      isSubmitted: json['isSubmitted'] ?? false,
      isPastDue: json['isPastDue'] ?? false,
      submission: json['submission'] != null
          ? SubmissionModel.fromJson(json['submission'])
          : null,
    );
  }
}

class SubmissionModel {
  final String id;
  final String status;
  final double? grade;
  final String? feedback;
  final DateTime submittedAt;

  SubmissionModel({
    required this.id,
    required this.status,
    this.grade,
    this.feedback,
    required this.submittedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      grade: json['grade'] != null
          ? double.tryParse(json['grade'].toString())
          : null,
      feedback: json['feedback'],
      submittedAt:
          DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class NoteModel {
  final String id;
  final String title;
  final String fileUrl;
  final String subjectName;
  final DateTime uploadedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.subjectName,
    required this.uploadedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final course = json['courseId'] as Map<String, dynamic>? ?? {};
    return NoteModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      subjectName: course['subjectName'] ?? '',
      uploadedAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class MarksheetModel {
  final String id;
  final String subjectName;
  final int term;
  final double internalExamMarks;
  final double internalExamTotalMarks;
  final double teacherEvaluationScore;

  MarksheetModel({
    required this.id,
    required this.subjectName,
    required this.term,
    required this.internalExamMarks,
    required this.internalExamTotalMarks,
    required this.teacherEvaluationScore,
  });

  factory MarksheetModel.fromJson(Map<String, dynamic> json) {
    final course = json['courseId'] as Map<String, dynamic>? ?? {};
    return MarksheetModel(
      id: json['_id'] ?? '',
      subjectName: course['subjectName'] ?? '',
      term: json['term'] ?? 0,
      internalExamMarks:
          double.tryParse(json['internalExamMarks'].toString()) ?? 0.0,
      internalExamTotalMarks:
          double.tryParse(json['internalExamTotalMarks'].toString()) ?? 0.0,
      teacherEvaluationScore:
          double.tryParse(json['teacherEvaluationScore'].toString()) ?? 0.0,
    );
  }
}

class FinalResultModel {
  final String id;
  final String programName;
  final int term;
  final String fileUrl;
  final String fileType;
  final DateTime publishedDate;

  FinalResultModel({
    required this.id,
    required this.programName,
    required this.term,
    required this.fileUrl,
    required this.fileType,
    required this.publishedDate,
  });

  factory FinalResultModel.fromJson(Map<String, dynamic> json) {
    final program = json['programId'] as Map<String, dynamic>? ?? {};
    return FinalResultModel(
      id: json['_id'] ?? '',
      programName: program['name'] ?? '',
      term: json['term'] ?? 0,
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? 'pdf',
      publishedDate:
          DateTime.tryParse(json['publishedDate'] ?? '') ?? DateTime.now(),
    );
  }
}

class EvaluationModel {
  final double score;
  final String status;
  final Map<String, dynamic> breakdown;

  EvaluationModel({
    required this.score,
    required this.status,
    required this.breakdown,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      score: double.tryParse(json['score'].toString()) ?? 0.0,
      status: json['status'] ?? '',
      breakdown: json['breakdown'] ?? {},
    );
  }
}

class CourseModel {
  final String enrollmentId;
  final String enrollmentType;
  final Map<String, dynamic> course;

  CourseModel({
    required this.enrollmentId,
    required this.enrollmentType,
    required this.course,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      enrollmentId: json['enrollmentId'] ?? '',
      enrollmentType: json['enrollmentType'] ?? '',
      course: json['course'] as Map<String, dynamic>? ?? {},
    );
  }
}

class NotificationModel {
  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
