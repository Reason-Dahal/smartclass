const Teacher = require('../models/Teacher');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const Attendance = require('../models/Attendance');
const Assignment = require('../models/Assignment');
const Submission = require('../models/Submission');
const Note = require('../models/Note');
const Marksheet = require('../models/Marksheet');
const Notification = require('../models/Notification');
const Student = require('../models/Student');

// ─── HELPER: verify teacher owns the course ──────────────────────
const verifyTeacherCourse = async (teacherUserId, courseId) => {
  const teacher = await Teacher.findOne({ userId: teacherUserId });
  if (!teacher) return null;

  const course = await Course.findOne({
    _id: courseId,
    teacherId: teacher._id,
    isActive: true,
  });

  return course ? { teacher, course } : null;
};

// ─── ATTENDANCE ───────────────────────────────────────────────────

const takeAttendance = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { date, records } = req.body;

    // records = [{ studentId, status }, ...]

    if (!date || !records || !Array.isArray(records) || records.length === 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'date and records array are required',
        },
      });
    }

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Course not found or you are not the teacher of this course',
        },
      });
    }

    const attendanceDate = new Date(date);

    // Build attendance records — upsert each one
    // (if teacher re-submits for same date, it updates rather than duplicates)
    const results = await Promise.all(
      records.map(({ studentId, status }) =>
        Attendance.findOneAndUpdate(
          { courseId, studentId, date: attendanceDate },
          { courseId, studentId, date: attendanceDate, status, markedBy: req.user._id },
          { upsert: true, new: true, runValidators: true }
        )
      )
    );

    res.status(200).json({
      success: true,
      data: {
        message: `Attendance recorded for ${results.length} students`,
        date: attendanceDate,
        records: results,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const getAttendance = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { date } = req.query;

    const verified = await verifyTeacherCourse(req.user._id, courseId);
    if (!verified) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Course not found or you are not the teacher of this course',
        },
      });
    }

    const filter = { courseId };
    if (date) filter.date = new Date(date);

    const attendance = await Attendance.find(filter)
      .populate('studentId', 'rollNumber')
      .sort({ date: -1 });

    res.status(200).json({
      success: true,
      data: { attendance },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

const correctAttendance = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['present', 'absent', 'late'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Status must be present, absent or late',
        },
      });
    }

    const record = await Attendance.findById(id);
    if (!record) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Attendance record not found' },
      });
    }

    // Verify teacher owns the course this attendance belongs to
    const verified = await verifyTeacherCourse(req.user._id, record.courseId);
    if (!verified) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
      });
    }

    record.status = status;
    record.markedBy = req.user._id;
    await record.save();

    res.status(200).json({
      success: true,
      data: { message: 'Attendance corrected successfully', record },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { code: 'SERVER_ERROR', message: error.message },
    });
  }
};

// ─── ASSIGNMENTS ──────────────────────────────────────────────────

const createAssignment = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { title, description, dueDate } = req.body;
  
      if (!title || !dueDate) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'title and dueDate are required',
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const assignment = await Assignment.create({
        courseId,
        createdBy: req.user._id,
        title,
        description,
        dueDate: new Date(dueDate),
      });
  
      // Notify all enrolled students
      const enrollments = await Enrollment.find({
        courseId,
        isActive: true,
      }).populate('studentId', 'userId');
  
      const notifications = enrollments.map((e) => ({
        userId: e.studentId.userId,
        type: 'assignment',
        message: `New assignment posted in ${verified.course.subjectName}: ${title}`,
        relatedId: assignment._id,
      }));
  
      if (notifications.length > 0) {
        await Notification.insertMany(notifications, { ordered: false });
      }
  
      res.status(201).json({
        success: true,
        data: { assignment },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const updateAssignment = async (req, res) => {
    try {
      const { id } = req.params;
      const { title, description, dueDate, isActive } = req.body;
  
      const assignment = await Assignment.findById(id);
      if (!assignment) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Assignment not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, assignment.courseId);
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      if (title) assignment.title = title;
      if (description) assignment.description = description;
      if (dueDate) assignment.dueDate = new Date(dueDate);
      if (isActive !== undefined) assignment.isActive = isActive;
  
      await assignment.save();
  
      res.status(200).json({
        success: true,
        data: { assignment },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const getSubmissions = async (req, res) => {
    try {
      const { id } = req.params;
  
      const assignment = await Assignment.findById(id);
      if (!assignment) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Assignment not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, assignment.courseId);
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      const submissions = await Submission.find({ assignmentId: id })
        .populate({
          path: 'studentId',
          select: 'rollNumber',
          populate: { path: 'userId', select: 'name email' },
        })
        .sort({ submittedAt: 1 });
  
      res.status(200).json({
        success: true,
        data: {
          assignment: { title: assignment.title, dueDate: assignment.dueDate },
          totalSubmissions: submissions.length,
          submissions,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const gradeSubmission = async (req, res) => {
    try {
      const { id } = req.params;
      const { grade, feedback } = req.body;
  
      if (grade === undefined) {
        return res.status(400).json({
          success: false,
          error: { code: 'VALIDATION_ERROR', message: 'grade is required' },
        });
      }
  
      const submission = await Submission.findById(id)
        .populate('assignmentId');
  
      if (!submission) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Submission not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(
        req.user._id,
        submission.assignmentId.courseId
      );
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      submission.grade = grade;
      submission.feedback = feedback || null;
      await submission.save();
  
      // Notify the student their work was graded
      const student = await Student.findById(submission.studentId);
      await Notification.create({
        userId: student.userId,
        type: 'grade',
        message: `Your submission for "${submission.assignmentId.title}" has been graded: ${grade}`,
        relatedId: submission._id,
      });
  
      res.status(200).json({
        success: true,
        data: { message: 'Submission graded successfully', submission },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  // ─── NOTES ───────────────────────────────────────────────────────
  
  const uploadNote = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { title, fileUrl } = req.body;
  
      if (!title || !fileUrl) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'title and fileUrl are required',
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const note = await Note.create({
        courseId,
        uploadedBy: req.user._id,
        title,
        fileUrl,
      });
  
      // Notify all enrolled students
      const enrollments = await Enrollment.find({
        courseId,
        isActive: true,
      }).populate('studentId', 'userId');
  
      const notifications = enrollments.map((e) => ({
        userId: e.studentId.userId,
        type: 'note',
        message: `New note uploaded in ${verified.course.subjectName}: ${title}`,
        relatedId: note._id,
      }));
  
      if (notifications.length > 0) {
        await Notification.insertMany(notifications, { ordered: false });
      }
  
      res.status(201).json({
        success: true,
        data: { note },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const deleteNote = async (req, res) => {
    try {
      const { id } = req.params;
  
      const note = await Note.findById(id);
      if (!note) {
        return res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: 'Note not found' },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, note.courseId);
      if (!verified) {
        return res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'You are not the teacher of this course' },
        });
      }
  
      note.isActive = false;
      await note.save();
  
      res.status(200).json({
        success: true,
        data: { message: 'Note deleted successfully' },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  // ─── MARKSHEETS ───────────────────────────────────────────────────
  
  const uploadMarksheet = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { studentId, term, internalExamMarks, internalExamTotalMarks, teacherEvaluationScore } = req.body;
  
      if (!studentId || !term || internalExamMarks === undefined ||
          !internalExamTotalMarks || teacherEvaluationScore === undefined) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'studentId, term, internalExamMarks, internalExamTotalMarks and teacherEvaluationScore are required',
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const marksheet = await Marksheet.findOneAndUpdate(
        { studentId, courseId, term },
        {
          studentId,
          courseId,
          term,
          internalExamMarks,
          internalExamTotalMarks,
          teacherEvaluationScore,
          uploadedBy: req.user._id,
        },
        { upsert: true, new: true, runValidators: true }
      );
  
      res.status(200).json({
        success: true,
        data: { marksheet },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };
  
  const bulkUploadMarksheets = async (req, res) => {
    try {
      const { courseId } = req.params;
      const { term, marksheets } = req.body;
  
      // marksheets = [{ studentId, internalExamMarks, internalExamTotalMarks, teacherEvaluationScore }]
  
      if (!term || !marksheets || !Array.isArray(marksheets) || marksheets.length === 0) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'term and marksheets array are required',
          },
        });
      }
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const results = await Promise.all(
        marksheets.map(({ studentId, internalExamMarks, internalExamTotalMarks, teacherEvaluationScore }) =>
          Marksheet.findOneAndUpdate(
            { studentId, courseId, term },
            {
              studentId, courseId, term,
              internalExamMarks, internalExamTotalMarks,
              teacherEvaluationScore,
              uploadedBy: req.user._id,
            },
            { upsert: true, new: true, runValidators: true }
          )
        )
      );
  
      res.status(200).json({
        success: true,
        data: {
          message: `Marksheets uploaded for ${results.length} students`,
          marksheets: results,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };

  const getCourseStudents = async (req, res) => {
    try {
      const { courseId } = req.params;
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const enrollments = await Enrollment.find({
        courseId,
        isActive: true,
      }).populate({
        path: 'studentId',
        select: 'rollNumber userId',
        populate: { path: 'userId', select: 'name email' },
      });
  
      const students = enrollments.map((e) => ({
        studentId: e.studentId._id,
        rollNumber: e.studentId.rollNumber,
        name: e.studentId.userId?.name || '',
        email: e.studentId.userId?.email || '',
      }));
  
      res.status(200).json({
        success: true,
        data: { students },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };

  const getCourseAssignments = async (req, res) => {
    try {
      const { courseId } = req.params;
  
      const verified = await verifyTeacherCourse(req.user._id, courseId);
      if (!verified) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Course not found or you are not the teacher of this course',
          },
        });
      }
  
      const assignments = await Assignment.find({
        courseId,
        isActive: true,
      }).sort({ createdAt: -1 });
  
      res.status(200).json({
        success: true,
        data: { assignments },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: { code: 'SERVER_ERROR', message: error.message },
      });
    }
  };

  module.exports = {
    takeAttendance,
    getAttendance,
    correctAttendance,
    createAssignment,
    updateAssignment,
    getSubmissions,
    gradeSubmission,
    uploadNote,
    deleteNote,
    uploadMarksheet,
    bulkUploadMarksheets,
    getCourseStudents,
    getCourseAssignments,
  };