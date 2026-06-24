class TeacherCourseModel {
  final String id;
  final String subjectName;
  final int term;
  final String programName;
  final String programType;
  final bool evaluationEnabled;
  final int studentCount;

  TeacherCourseModel({
    required this.id,
    required this.subjectName,
    required this.term,
    required this.programName,
    required this.programType,
    required this.evaluationEnabled,
    required this.studentCount,
  });

  factory TeacherCourseModel.fromJson(Map<String, dynamic> json) {
    final program = json['programId'] as Map<String, dynamic>? ?? {};
    return TeacherCourseModel(
      id: json['_id'] ?? '',
      subjectName: json['subjectName'] ?? '',
      term: json['term'] ?? 0,
      programName: program['name'] ?? '',
      programType: program['type'] ?? '',
      evaluationEnabled: json['evaluationEnabled'] ?? false,
      studentCount: json['studentCount'] ?? 0,
    );
  }
}

class AttendanceRecordModel {
  final String id;
  final String studentId;
  final String rollNumber;
  final DateTime date;
  final String status;

  AttendanceRecordModel({
    required this.id,
    required this.studentId,
    required this.rollNumber,
    required this.date,
    required this.status,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final student = json['studentId'] as Map<String, dynamic>? ?? {};
    return AttendanceRecordModel(
      id: json['_id'] ?? '',
      studentId: student['_id'] ?? '',
      rollNumber: student['rollNumber'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'absent',
    );
  }
}

class TeacherAssignmentModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String courseId;
  final int submissionCount;

  TeacherAssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.courseId,
    required this.submissionCount,
  });

  factory TeacherAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      courseId: json['courseId'] is String
          ? json['courseId']
          : (json['courseId'] as Map<String, dynamic>?)?['_id'] ?? '',
      submissionCount: json['submissionCount'] ?? 0,
    );
  }
}

class SubmissionDetailModel {
  final String id;
  final String studentName;
  final String rollNumber;
  final String status;
  final DateTime submittedAt;
  final double? grade;
  final String? feedback;
  final String? fileUrl;

  SubmissionDetailModel({
    required this.id,
    required this.studentName,
    required this.rollNumber,
    required this.status,
    required this.submittedAt,
    this.grade,
    this.feedback,
    this.fileUrl,
  });

  factory SubmissionDetailModel.fromJson(Map<String, dynamic> json) {
    final student = json['studentId'] as Map<String, dynamic>? ?? {};
    final userId = student['userId'] as Map<String, dynamic>? ?? {};
    return SubmissionDetailModel(
      id: json['_id'] ?? '',
      studentName: userId['name'] ?? '',
      rollNumber: student['rollNumber'] ?? '',
      status: json['status'] ?? '',
      submittedAt:
          DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
      grade: json['grade'] != null
          ? double.tryParse(json['grade'].toString())
          : null,
      feedback: json['feedback'],
      fileUrl: json['fileUrl'],
    );
  }
}

class TeacherNoteModel {
  final String id;
  final String title;
  final String fileUrl;
  final DateTime uploadedAt;

  TeacherNoteModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory TeacherNoteModel.fromJson(Map<String, dynamic> json) {
    return TeacherNoteModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      uploadedAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
