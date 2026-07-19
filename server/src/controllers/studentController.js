const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Assignment = require('../models/Assignment');
const Submission = require('../models/Submission');
const Note = require('../models/Note');
const Marksheet = require('../models/Marksheet');
const FinalResult = require('../models/FinalResult');
const EvaluationConfig = require('../models/EvaluationConfig');
const Notification = require('../models/Notification');
const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const Batch = require('../models/Batch');

// ─── HELPER: get student profile from logged-in user ─────────────
const getStudentProfile = async (userId) => {
  return await Student.findOne({ userId }).populate('batchId', 'currentTerm');
};

// ─── ATTENDANCE ───────────────────────────────────────────────────

const getMyAttendance = async (req, res) => {
  try {
    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    const { courseId } = req.query;
    const filter = { studentId: student._id };
    if (courseId) filter.courseId = courseId;

    const attendance = await Attendance.find(filter)
      .populate('courseId', 'subjectName term')
      .sort({ date: -1 });

    // Calculate attendance percentage per course
    const courseMap = {};
    attendance.forEach((record) => {
      const key = record.courseId._id.toString();
      if (!courseMap[key]) {
        courseMap[key] = {
          course: record.courseId,
          total: 0,
          present: 0,
          absent: 0,
          late: 0,
        };
      }
      courseMap[key].total += 1;
      courseMap[key][record.status] += 1;
    });

    const summary = Object.values(courseMap).map((c) => ({
      course: c.course,
      totalClasses: c.total,
      present: c.present,
      absent: c.absent,
      late: c.late,
      attendancePercentage: ((c.present / c.total) * 100).toFixed(2),
    }));

    res.status(200).json({
      success: true,
      data: { summary, records: attendance },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── ASSIGNMENTS ──────────────────────────────────────────────────

const getMyAssignments = async (req, res) => {
  try {
    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    // V2 — get current term from student's batch
    const batch = await Batch.findById(student.batchId);
    const currentTerm = batch ? batch.currentTerm : 1;

    // Get enrolled courses for current term only
    const enrollments = await Enrollment.find({
      studentId: student._id,
      isActive: true,
    }).select('courseId');

    const courseIds = enrollments.map((e) => e.courseId);

    // Filter courses to current term only
    const currentTermCourses = await Course.find({
      _id: { $in: courseIds },
      term: currentTerm,
      isActive: true,
    }).select('_id subjectName term');

    const currentTermCourseIds = currentTermCourses.map((c) => c._id);

    const assignments = await Assignment.find({
      courseId: { $in: currentTermCourseIds },
      isActive: true,
    })
      .populate('courseId', 'subjectName term')
      .sort({ dueDate: 1 });

    // Check submission status — V2: exclude soft-deleted submissions
    const assignmentsWithStatus = await Promise.all(
      assignments.map(async (assignment) => {
        const submission = await Submission.findOne({
          assignmentId: assignment._id,
          studentId:    student._id,
          isDeleted:    false,   // V2 — exclude deleted submissions
        });

        return {
          ...assignment.toObject(),
          submission: submission ? {
            _id:         submission._id,
            fileUrl:     submission.fileUrl,     // V2 — for preview
            fileType:    submission.fileType,    // V2 — pdf or docx
            status:      submission.status,
            grade:       submission.grade,
            feedback:    submission.feedback,
            submittedAt: submission.submittedAt,
            isGraded:    submission.grade !== null && submission.grade !== undefined,
          } : null,
          isSubmitted: !!submission,
          isPastDue:   new Date() > new Date(assignment.dueDate),
        };
      })
    );

    // V2 — group by subject
    const grouped = [];
    const subjectMap = {};

    currentTermCourses.forEach((course) => {
      if (!subjectMap[course._id.toString()]) {
        subjectMap[course._id.toString()] = {
          subjectName: course.subjectName,
          courseId:    course._id,
          assignments: [],
        };
        grouped.push(subjectMap[course._id.toString()]);
      }
    });

    assignmentsWithStatus.forEach((assignment) => {
      const courseId = assignment.courseId._id
        ? assignment.courseId._id.toString()
        : assignment.courseId.toString();
      if (subjectMap[courseId]) {
        subjectMap[courseId].assignments.push(assignment);
      }
    });

    res.status(200).json({
      success: true,
      data: {
        term:   currentTerm,
        groups: grouped,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const submitAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    const { fileUrl, fileType } = req.body;  // ← add fileType

    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    const assignment = await Assignment.findById(id);
    if (!assignment || !assignment.isActive) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Assignment not found' },
      });
    }

    // Verify student is enrolled
    const enrollment = await Enrollment.findOne({
      studentId: student._id,
      courseId:  assignment.courseId,
      isActive:  true,
    });
    if (!enrollment) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'You are not enrolled in this course' },
      });
    }

    // Check due date for resubmission after delete
    const isPastDue = new Date() > new Date(assignment.dueDate);
    if (isPastDue) {
      // Check if there is a non-deleted submission already
      const existing = await Submission.findOne({
        assignmentId: id,
        studentId:    student._id,
        isDeleted:    false,
      });
      if (existing) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'ALREADY_SUBMITTED',
            message: 'Assignment already submitted',
          },
        });
      }
    }

    const status = isPastDue ? 'late' : 'on-time';

    // Determine file type from URL if not provided
    const resolvedFileType = fileType ||
      (fileUrl?.toLowerCase().endsWith('.pdf') ? 'pdf' : 'docx');

    const submission = await Submission.findOneAndUpdate(
      { assignmentId: id, studentId: student._id },
      {
        assignmentId: id,
        studentId:    student._id,
        fileUrl:      fileUrl || null,
        fileType:     resolvedFileType,   //add
        submittedAt:  new Date(),
        status,
        isDeleted:    false,              //reset soft delete on resubmit
        deletedAt:    null,               //clear deleted date
        grade:        null,               //clear old grade on resubmit
        feedback:     null,               //clear old feedback on resubmit
      },
      { upsert: true, new: true, runValidators: false }
    );

    res.status(200).json({
      success: true,
      data: {
        message: `Assignment submitted — marked as ${status}`,
        submission,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── NOTES ───────────────────────────────────────────────────────

const getMyNotes = async (req, res) => {
  try {
    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    // V2 — get current term from student's batch
    const batch = await Batch.findById(student.batchId);
    const currentTerm = batch ? batch.currentTerm : 1;

    // Term from query or default to current term
    const requestedTerm = req.query.term
      ? parseInt(req.query.term)
      : currentTerm;

    // Get all enrolled courses
    const enrollments = await Enrollment.find({
      studentId: student._id,
      isActive:  true,
    }).select('courseId');

    const courseIds = enrollments.map((e) => e.courseId);

    // Filter courses by requested term
    const termCourses = await Course.find({
      _id:      { $in: courseIds },
      term:     requestedTerm,
      isActive: true,
    }).select('_id subjectName term');

    const termCourseIds = termCourses.map((c) => c._id);

    const notes = await Note.find({
      courseId: { $in: termCourseIds },
      isActive: true,
    })
      .populate('courseId', 'subjectName term')
      .sort({ createdAt: -1 });

    // V2 — group by subject
    const grouped = [];
    const subjectMap = {};

    termCourses.forEach((course) => {
      const key = course._id.toString();
      if (!subjectMap[key]) {
        subjectMap[key] = {
          subjectName: course.subjectName,
          courseId:    course._id,
          notes:       [],
        };
        grouped.push(subjectMap[key]);
      }
    });

    notes.forEach((note) => {
      const courseId = note.courseId._id
        ? note.courseId._id.toString()
        : note.courseId.toString();

      if (subjectMap[courseId]) {
        // Detect file type from URL
        const url      = note.fileUrl || '';
        const fileType = url.toLowerCase().includes('.pdf') ? 'pdf' : 'docx';

        subjectMap[courseId].notes.push({
          _id:        note._id,
          title:      note.title,
          fileUrl:    note.fileUrl,
          fileType,
          createdAt:  note.createdAt,
        });
      }
    });

    // Get all available terms for the switcher
    const allCourses = await Course.find({
      _id:      { $in: courseIds },
      isActive: true,
    }).select('term').distinct('term');

    res.status(200).json({
      success: true,
      data: {
        currentTerm,
        requestedTerm,
        availableTerms: allCourses.sort((a, b) => a - b),
        groups: grouped,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};


// MARKSHEETS

const getMyMarksheets = async (req, res) => {
  try {
    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    const { term, courseId } = req.query;
    const filter = { studentId: student._id };
    if (term) filter.term = Number(term);
    if (courseId) filter.courseId = courseId;

    const marksheets = await Marksheet.find(filter)
      .populate('courseId', 'subjectName term')
      .sort({ term: -1 });

    // Group by examType so students see their marks organized under
    // First Terminal / Mid Term / Pre-Board headings, rather than
    // one flat undifferentiated list.
    const examTypeLabels = {
      first_terminal: 'First Terminal',
      mid_term: 'Mid Term',
      pre_board: 'Pre-Board',
    };

    const groups = {};
    Marksheet.EXAM_TYPES.forEach((type) => {
      groups[type] = {
        examType: type,
        label: examTypeLabels[type],
        marksheets: [],
      };
    });

    marksheets.forEach((m) => {
      if (groups[m.examType]) {
        groups[m.examType].marksheets.push(m);
      }
    });

    // Only return exam types that actually have at least one record —
    // avoids showing three empty sections when a term has just started.
    const nonEmptyGroups = Object.values(groups).filter(
      (g) => g.marksheets.length > 0
    );

    res.status(200).json({
      success: true,
      data: { groups: nonEmptyGroups },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

//FINAL RESULTS 

const getMyFinalResults = async (req, res) => {
  try {
    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    // V2 — return result files for the student's program
    // All students in the same program see the same merit list file
    const results = await FinalResult.find({ programId: student.programId })
      .populate('programId', 'name type')
      .sort({ term: -1 });  // newest term first

    res.status(200).json({
      success: true,
      data: { results },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};
// EVALUATION INDICATOR 

const getEvaluationIndicator = async (req, res) => {
  try {
    const { courseId } = req.query;

    if (!courseId) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'courseId is required' },
      });
    }

    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    // Check if evaluation is enabled for this course
    const course = await Course.findById(courseId);
    if (!course || !course.evaluationEnabled) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'EVALUATION_DISABLED',
          message: 'Your teacher has not enabled evaluation for this course yet. Please check back later.',
        },
      });
    }

    // Get evaluation weights — use defaults if not configured
    let config = await EvaluationConfig.findOne();
    if (!config) {
      config = {
        attendanceWeight: 25,
        internalExamWeight: 25,
        assignmentWeight: 25,
        teacherEvaluationWeight: 25,
      };
    }

    // 1. Attendance percentage
    const attendanceRecords = await Attendance.find({
      courseId,
      studentId: student._id,
    });
    const totalClasses = attendanceRecords.length;
    const presentClasses = attendanceRecords.filter(
      (r) => r.status === 'present'
    ).length;
    const attendancePercent = totalClasses > 0
      ? (presentClasses / totalClasses) * 100
      : 0;

    /* 2. Internal exam percentage — averaged across whichever exam
     types (First Terminal, Mid Term, Pre-Board) currently exist
     for this course and term. Simple average, unweighted between
     exam types. If none exist yet, treated as 0. */
    const currentTerm = student.batchId?.currentTerm || 1;

    const examMarksheets = await Marksheet.find({
      courseId,
      studentId: student._id,
      term: currentTerm, 
    });

    let internalExamPercent = 0;
    let teacherEvalScore = 0;

    if (examMarksheets.length > 0) {
      const examPercents = examMarksheets.map(
        (m) => (m.internalExamMarks / m.internalExamTotalMarks) * 100
      );
      const evalScores = examMarksheets.map((m) => m.teacherEvaluationScore);

      internalExamPercent =
        examPercents.reduce((sum, p) => sum + p, 0) / examPercents.length;
      teacherEvalScore =
        evalScores.reduce((sum, s) => sum + s, 0) / evalScores.length;
    }

    // 3. Assignment submission percentage
    const assignments = await Assignment.find({ courseId, isActive: true });
    const totalAssignments = assignments.length;
    const submittedCount = await Submission.countDocuments({
      assignmentId: { $in: assignments.map((a) => a._id) },
      studentId: student._id,
    });
    const assignmentPercent = totalAssignments > 0
      ? (submittedCount / totalAssignments) * 100
      : 0;

    // 4. Weighted score calculation
    const score =
      (attendancePercent * config.attendanceWeight +
        internalExamPercent * config.internalExamWeight +
        assignmentPercent * config.assignmentWeight +
        teacherEvalScore * config.teacherEvaluationWeight) /
      100;

    // 5. Status label
    let status;
    if (score >= 80) status = 'Excellent';
    else if (score >= 65) status = 'Good';
    else if (score >= 50) status = 'Average';
    else status = 'At Risk';

    res.status(200).json({
      success: true,
      data: {
        score: parseFloat(score.toFixed(2)),
        status,
        breakdown: {
          attendance: {
            percent: parseFloat(attendancePercent.toFixed(2)),
            weight: config.attendanceWeight,
            contribution: parseFloat(
              ((attendancePercent * config.attendanceWeight) / 100).toFixed(2)
            ),
          },
          internalExam: {
            percent: parseFloat(internalExamPercent.toFixed(2)),
            weight: config.internalExamWeight,
            contribution: parseFloat(
              ((internalExamPercent * config.internalExamWeight) / 100).toFixed(2)
            ),
          },
          assignments: {
            percent: parseFloat(assignmentPercent.toFixed(2)),
            weight: config.assignmentWeight,
            contribution: parseFloat(
              ((assignmentPercent * config.assignmentWeight) / 100).toFixed(2)
            ),
          },
          teacherEvaluation: {
            score: teacherEvalScore,
            weight: config.teacherEvaluationWeight,
            contribution: parseFloat(
              ((teacherEvalScore * config.teacherEvaluationWeight) / 100).toFixed(2)
            ),
          },
        },
        weights: config,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// DELET SUBMISSION
const deleteSubmission = async (req, res) => {
  try {
    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    const submission = await Submission.findById(req.params.id);
    if (!submission) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Submission not found' },
      });
    }

    // Ownership check
    if (!submission.studentId.equals(student._id)) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'Not your submission' },
      });
    }

    // Cannot delete if already graded
    if (submission.grade !== null && submission.grade !== undefined) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'ALREADY_GRADED',
          message: 'Cannot delete a graded submission',
        },
      });
    }

    // Soft delete
    submission.isDeleted = true;
    submission.deletedAt = new Date();
    await submission.save();

    res.status(200).json({
      success: true,
      data: { message: 'Submission deleted successfully' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};


// ─── NOTIFICATIONS ────────────────────────────────────────────────

const getMyNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);

    const unreadCount = await Notification.countDocuments({
      userId: req.user._id,
      isRead: false,
    });

    res.status(200).json({
      success: true,
      data: { notifications, unreadCount },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const markNotificationRead = async (req, res) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { isRead: true }
    );

    res.status(200).json({
      success: true,
      data: { message: 'Notification marked as read' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const markAllNotificationsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { isRead: true }
    );

    res.status(200).json({
      success: true,
      data: { message: 'All notifications marked as read' },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

module.exports = {
  getMyAttendance,
  getMyAssignments,
  submitAssignment,
  deleteSubmission,
  getMyNotes,
  getMyMarksheets,
  getMyFinalResults,
  getEvaluationIndicator,
  getMyNotifications,
  markNotificationRead,
  markAllNotificationsRead,
};