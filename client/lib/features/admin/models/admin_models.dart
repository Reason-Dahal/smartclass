class AdminUserModel {
  final String id;
  final String profileId; // Teacher/Student profile _id
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;

  AdminUserModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as Map<String, dynamic>? ?? json;
    return AdminUserModel(
      id: userId['_id'] ?? json['_id'] ?? '',
      profileId: json['_id'] ?? '', // Teacher/Student profile _id
      name: userId['name'] ?? '',
      email: userId['email'] ?? '',
      role: userId['role'] ?? '',
      status: userId['status'] ?? 'active',
      createdAt:
          DateTime.tryParse(userId['createdAt'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
    );
  }
}

class ProgramModel {
  final String id;
  final String name;
  final String type;
  final int totalTerms;
  final bool isActive;

  ProgramModel({
    required this.id,
    required this.name,
    required this.type,
    required this.totalTerms,
    required this.isActive,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      totalTerms: json['totalTerms'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}

class BatchModel {
  final String id;
  final String name;
  final int intakeYear;
  final int currentTerm;
  final String programId;
  final String programName;

  BatchModel({
    required this.id,
    required this.name,
    required this.intakeYear,
    required this.currentTerm,
    required this.programId,
    required this.programName,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    final program = json['programId'] as Map<String, dynamic>? ?? {};
    return BatchModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      intakeYear: json['intakeYear'] ?? 0,
      currentTerm: json['currentTerm'] ?? 1,
      programId: program['_id'] ?? '',
      programName: program['name'] ?? '',
    );
  }
}

class SystemReportModel {
  final int totalStudents;
  final int totalTeachers;
  final int totalPrograms;
  final int totalCourses;
  final String overallAttendanceRate;
  final int totalAssignments;
  final int totalSubmissions;
  final String submissionRate;

  SystemReportModel({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalPrograms,
    required this.totalCourses,
    required this.overallAttendanceRate,
    required this.totalAssignments,
    required this.totalSubmissions,
    required this.submissionRate,
  });

  factory SystemReportModel.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] as Map<String, dynamic>? ?? {};
    final attendance = json['attendance'] as Map<String, dynamic>? ?? {};
    final assignments = json['assignments'] as Map<String, dynamic>? ?? {};
    return SystemReportModel(
      totalStudents: overview['totalStudents'] ?? 0,
      totalTeachers: overview['totalTeachers'] ?? 0,
      totalPrograms: overview['totalPrograms'] ?? 0,
      totalCourses: overview['totalCourses'] ?? 0,
      overallAttendanceRate: attendance['overallAttendanceRate'] ?? '0%',
      totalAssignments: assignments['totalAssignments'] ?? 0,
      totalSubmissions: assignments['totalSubmissions'] ?? 0,
      submissionRate: assignments['submissionRate'] ?? '0%',
    );
  }
}
