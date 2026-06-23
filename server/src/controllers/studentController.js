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

    const { courseId } = req.query;

    // Get all courses the student is enrolled in
    const enrollmentFilter = { studentId: student._id, isActive: true };
    if (courseId) enrollmentFilter.courseId = courseId;

    const enrollments = await Enrollment.find(enrollmentFilter).select('courseId');
    const courseIds = enrollments.map((e) => e.courseId);

    const assignments = await Assignment.find({
      courseId: { $in: courseIds },
      isActive: true,
    })
      .populate('courseId', 'subjectName term')
      .sort({ dueDate: 1 });

    // Check submission status for each assignment
    const assignmentsWithStatus = await Promise.all(
      assignments.map(async (assignment) => {
        const submission = await Submission.findOne({
          assignmentId: assignment._id,
          studentId: student._id,
        });
        return {
          ...assignment.toObject(),
          submission: submission || null,
          isSubmitted: !!submission,
          isPastDue: new Date() > new Date(assignment.dueDate),
        };
      })
    );

    res.status(200).json({
      success: true,
      data: { assignments: assignmentsWithStatus },
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
    const { fileUrl } = req.body;

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

    // Verify student is enrolled in this course
    const enrollment = await Enrollment.findOne({
      studentId: student._id,
      courseId: assignment.courseId,
      isActive: true,
    });

    if (!enrollment) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'You are not enrolled in this course' },
      });
    }

    // Determine on-time or late
    const status = new Date() > new Date(assignment.dueDate) ? 'late' : 'on-time';

    const submission = await Submission.findOneAndUpdate(
      { assignmentId: id, studentId: student._id },
      {
        assignmentId: id,
        studentId: student._id,
        fileUrl: fileUrl || null,
        submittedAt: new Date(),
        status,
      },
      { upsert: true, new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      data: {
        message: `Assignment submitted successfully — marked as ${status}`,
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

    const { courseId } = req.query;
    const enrollmentFilter = { studentId: student._id, isActive: true };
    if (courseId) enrollmentFilter.courseId = courseId;

    const enrollments = await Enrollment.find(enrollmentFilter).select('courseId');
    const courseIds = enrollments.map((e) => e.courseId);

    const notes = await Note.find({
      courseId: { $in: courseIds },
      isActive: true,
    })
      .populate('courseId', 'subjectName term')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: { notes },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── MARKSHEETS ───────────────────────────────────────────────────

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

    res.status(200).json({
      success: true,
      data: { marksheets },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── FINAL RESULTS ────────────────────────────────────────────────

const getMyFinalResults = async (req, res) => {
  try {
    const student = await getStudentProfile(req.user._id);
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Student profile not found' },
      });
    }

    const results = await FinalResult.find({ studentId: student._id })
      .populate('courseResults.courseId', 'subjectName term')
      .sort({ term: -1 });

    // Extract backlog courses — failed with no later pass
    const backlog = [];
    const passedCourseIds = new Set();

    // First pass — collect all passed courses
    results.forEach((result) => {
      result.courseResults.forEach((cr) => {
        if (cr.status === 'pass') {
          passedCourseIds.add(cr.courseId._id.toString());
        }
      });
    });

    // Second pass — find failed courses not later passed
    results.forEach((result) => {
      result.courseResults.forEach((cr) => {
        if (
          cr.status === 'fail' &&
          !passedCourseIds.has(cr.courseId._id.toString())
        ) {
          backlog.push({
            course: cr.courseId,
            term: result.term,
          });
        }
      });
    });

    res.status(200).json({
      success: true,
      data: { results, backlog },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── EVALUATION INDICATOR ─────────────────────────────────────────

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
          message: 'Evaluation indicator is not enabled for this course',
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

    // 2. Internal exam percentage
    const marksheet = await Marksheet.findOne({
      courseId,
      studentId: student._id,
    });
    const internalExamPercent = marksheet
      ? (marksheet.internalExamMarks / marksheet.internalExamTotalMarks) * 100
      : 0;
    const teacherEvalScore = marksheet
      ? marksheet.teacherEvaluationScore
      : 0;

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
  getMyNotes,
  getMyMarksheets,
  getMyFinalResults,
  getEvaluationIndicator,
  getMyNotifications,
  markNotificationRead,
  markAllNotificationsRead,
};