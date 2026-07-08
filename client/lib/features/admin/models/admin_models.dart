class AdminUserModel {
  final String id;
  final String profileId;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;
  // V2 additions
  final String? department; // teachers only
  final String? rollNumber; // students only
  final String? programId; // students only
  final String? batchId; // students only

  AdminUserModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.department,
    this.rollNumber,
    this.programId,
    this.batchId,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final userIdRaw = json['userId'];
    final userId = userIdRaw is Map<String, dynamic> ? userIdRaw : json;

    // programId and batchId may be populated objects or plain strings
    final programRaw = json['programId'];
    final batchRaw = json['batchId'];
    final programId = programRaw is Map
        ? programRaw['_id'] as String?
        : programRaw as String?;
    final batchId = batchRaw is Map
        ? batchRaw['_id'] as String?
        : batchRaw as String?;

    return AdminUserModel(
      id: userId['_id'] ?? json['_id'] ?? '',
      profileId: json['_id'] ?? '',
      name: userId['name'] ?? '',
      email: userId['email'] ?? '',
      role: userId['role'] ?? '',
      status: userId['status'] ?? 'active',
      createdAt:
          DateTime.tryParse(userId['createdAt'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      department: json['department'] as String?,
      rollNumber: json['rollNumber'] as String?,
      programId: programId,
      batchId: batchId,
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
