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
  final String? fileUrl; // V2 — for in-app preview
  final String? fileType; // V2 — 'pdf' or 'docx'
  final bool isGraded; // V2 — true when grade is not null

  SubmissionModel({
    required this.id,
    required this.status,
    this.grade,
    this.feedback,
    required this.submittedAt,
    this.fileUrl,
    this.fileType,
    required this.isGraded,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    final grade = json['grade'] != null
        ? double.tryParse(json['grade'].toString())
        : null;
    return SubmissionModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      grade: grade,
      feedback: json['feedback'],
      submittedAt:
          DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      isGraded: grade != null,
    );
  }
}

class NoteModel {
  final String id;
  final String title;
  final String fileUrl;
  final String fileType; // V2 — 'pdf' or 'docx'
  final String subjectName;
  final DateTime uploadedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.subjectName,
    required this.uploadedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final course = json['courseId'] as Map<String, dynamic>? ?? {};
    final fileUrl = json['fileUrl'] ?? '';
    final fileType =
        json['fileType'] ??
        (fileUrl.toLowerCase().contains('.pdf') ? 'pdf' : 'docx');
    return NoteModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      fileUrl: fileUrl,
      fileType: fileType,
      subjectName: course['subjectName'] ?? '',
      uploadedAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class NoteGroupModel {
  final String subjectName;
  final String courseId;
  final List<NoteModel> notes;

  NoteGroupModel({
    required this.subjectName,
    required this.courseId,
    required this.notes,
  });

  factory NoteGroupModel.fromJson(Map<String, dynamic> json) {
    final notes = (json['notes'] as List? ?? [])
        .map((n) => NoteModel.fromJson(n))
        .toList();
    return NoteGroupModel(
      subjectName: json['subjectName'] ?? '',
      courseId: json['courseId'] is Map
          ? (json['courseId'] as Map)['_id'] ?? ''
          : json['courseId']?.toString() ?? '',
      notes: notes,
    );
  }
}

class NotesResponse {
  final int currentTerm;
  final int requestedTerm;
  final List<int> availableTerms;
  final List<NoteGroupModel> groups;

  NotesResponse({
    required this.currentTerm,
    required this.requestedTerm,
    required this.availableTerms,
    required this.groups,
  });

  factory NotesResponse.fromJson(Map<String, dynamic> json) {
    return NotesResponse(
      currentTerm: json['currentTerm'] ?? 1,
      requestedTerm: json['requestedTerm'] ?? 1,
      availableTerms: (json['availableTerms'] as List? ?? [])
          .map((t) => t as int)
          .toList(),
      groups: (json['groups'] as List? ?? [])
          .map((g) => NoteGroupModel.fromJson(g))
          .toList(),
    );
  }
}

class MarksheetModel {
  final String id;
  final String subjectName;
  final int term;
  final String examType;
  final double internalExamMarks;
  final double internalExamTotalMarks;
  final double teacherEvaluationScore;

  MarksheetModel({
    required this.id,
    required this.subjectName,
    required this.term,
    required this.examType,
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
      examType: json['examType'] ?? '',
      internalExamMarks:
          double.tryParse(json['internalExamMarks'].toString()) ?? 0.0,
      internalExamTotalMarks:
          double.tryParse(json['internalExamTotalMarks'].toString()) ?? 0.0,
      teacherEvaluationScore:
          double.tryParse(json['teacherEvaluationScore'].toString()) ?? 0.0,
    );
  }
}

// Human-readable labels, matching the backend's Marksheet.EXAM_TYPES
// and the teacher-side kExamTypeLabels constant.
const Map<String, String> examTypeLabels = {
  'first_terminal': 'First Terminal',
  'mid_term': 'Mid Term',
  'pre_board': 'Pre-Board',
};

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

class AssignmentGroupModel {
  final String subjectName;
  final String courseId;
  final List<AssignmentModel> assignments;

  AssignmentGroupModel({
    required this.subjectName,
    required this.courseId,
    required this.assignments,
  });

  factory AssignmentGroupModel.fromJson(Map<String, dynamic> json) {
    final assignments = (json['assignments'] as List? ?? [])
        .map((a) => AssignmentModel.fromJson(a))
        .toList();
    return AssignmentGroupModel(
      subjectName: json['subjectName'] ?? '',
      courseId: json['courseId'] is Map
          ? json['courseId']['_id'] ?? ''
          : json['courseId'] ?? '',
      assignments: assignments,
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
